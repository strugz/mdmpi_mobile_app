import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/client_registry_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The account picker reads the client registry cached on the phone, and asks
/// the server only while nothing is cached yet. It used to ask the server on
/// every keystroke and sat empty while it waited.

ClientModel _c(String code, String name) => ClientModel(
    id: code,
    code: code,
    name: name,
    address: '',
    contact: '',
    emailAddress: '');

class _Registry extends ClientRegistryRepository {
  _Registry({this.cached = const []});

  List<ClientModel> cached;
  int onlineCalls = 0;
  int refreshCalls = 0;
  Completer<Result<int>>? pendingRefresh;

  @override
  Future<int> cachedCount() async => cached.length;

  @override
  Future<List<ClientModel>> searchCached(String term) async => [
        for (final c in cached)
          if (c.name.toLowerCase().contains(term.toLowerCase())) c,
      ];

  @override
  Future<Result<List<ClientModel>>> searchOnline(String term,
      {int limit = 25}) async {
    onlineCalls++;
    return Result.success([_c('C-ONLINE', 'From the server')]);
  }

  @override
  Future<Result<int>> refresh() {
    refreshCalls++;
    pendingRefresh = Completer<Result<int>>();
    return pendingRefresh!.future;
  }
}

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  tearDown(Get.reset);

  test('searches the cached copy, without the network', () async {
    final registry = Get.put<ClientRegistryRepository>(
            _Registry(cached: [_c('C-100', 'Antipolo Doctors Hospital')]))
        as _Registry;
    final activity = Get.put<CollectionActivityController>(_Activity());

    final result = await activity.searchClientRegistry('anti');

    expect(result.value.single.id, 'C-100');
    expect(registry.onlineCalls, 0);
  });

  test('asks the server only while nothing is cached yet', () async {
    final registry =
        Get.put<ClientRegistryRepository>(_Registry()) as _Registry;
    final activity = Get.put<CollectionActivityController>(_Activity());

    final result = await activity.searchClientRegistry('anything');

    expect(result.value.single.id, 'C-ONLINE');
    expect(registry.onlineCalls, 1);
  });

  test('a download refreshes the copy, one refresh at a time', () async {
    final registry = Get.put<ClientRegistryRepository>(
        _Registry(cached: [_c('C-100', 'Antipolo')])) as _Registry;
    final activity = Get.put<CollectionActivityController>(_Activity());

    final first = activity.loadClientRegistry(force: true);
    await Future<void>.delayed(Duration.zero);
    // A second download while the first refresh runs does not start another.
    await activity.loadClientRegistry(force: true);
    expect(registry.refreshCalls, 1);

    registry.pendingRefresh!.complete(Result.success(1));
    await first;

    unawaited(activity.loadClientRegistry(force: true));
    await Future<void>.delayed(Duration.zero);
    expect(registry.refreshCalls, 2, reason: 'the next one runs normally');
    registry.pendingRefresh!.complete(Result.success(1));
  });
}
