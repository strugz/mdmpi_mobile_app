import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/cwt_pickup_form.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/client_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Picking an existing client for a CWT Pick-up. The account was typed
/// freehand, so a name spelled differently from the registry saved with no
/// client id. It is now picked from the registry (a_tblcollectionclient),
/// searched as the collector types, with the phone's own accounts when the
/// registry cannot be reached.

ClientModel _client(String code, String name, [String address = '']) =>
    ClientModel(
      id: code,
      code: code,
      name: name,
      address: address,
      contact: '',
      emailAddress: '',
    );

final _registry = [
  _client('C-100', 'Antipolo Doctors Hospital', 'Antipolo City, Rizal'),
  _client('C-200', "5'R's Medical Supply"),
  _client('C-300', 'Accuteqs Diagnostics Corp.'),
];

/// Registry search as the server does it: code or name, case-insensitive.
Future<Result<List<ClientModel>>> _online(String term) async {
  final q = term.trim().toLowerCase();
  return Result.success([
    for (final c in _registry)
      if (q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q))
        c,
  ]);
}

Future<Result<List<ClientModel>>> _offline(String term) async =>
    Result.failure('Client search is unavailable offline');

List<ClientModel> _known(String term) =>
    [_client('C-200', "5'R's Medical Supply")];

Future<ClientModel?> _open(
  WidgetTester tester, {
  ClientRegistrySearch search = _online,
}) async {
  ClientModel? picked;
  await tester.pumpWidget(MaterialApp(
    theme: BCollectionTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async => picked = await ClientPickerSheet.show(
                context,
                search: search,
                searchKnown: _known),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return picked;
}

class _Activity extends CollectionActivityController {
  final saved = <({String? clientId, String accountName})>[];

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<Result<List<ClientModel>>> searchClientRegistry(String term) =>
      _online(term);

  @override
  List<ClientModel> searchKnownAccounts(String term) => _known(term);

  @override
  Future<void> saveGlobalActivity({
    required String type,
    required String accountName,
    required String remarks,
    double totalCollected = 0,
    String? bankName,
    String? checkNumber,
    String? clientId,
    List<String> documentIds = const [],
  }) async =>
      saved.add((clientId: clientId, accountName: accountName));
}

void main() {
  tearDown(Get.reset);

  group('the picker', () {
    testWidgets('lists the registry and narrows as the collector types',
        (tester) async {
      await _open(tester);

      expect(find.text('Choose an account'), findsOneWidget);
      expect(find.text('Antipolo Doctors Hospital'), findsOneWidget);
      expect(find.text('C-100 · Antipolo City, Rizal'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('client-picker-search')), 'accu');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Accuteqs Diagnostics Corp.'), findsOneWidget);
      expect(find.text('Antipolo Doctors Hospital'), findsNothing);
    });

    testWidgets('searches by client code too', (tester) async {
      await _open(tester);
      await tester.enterText(
          find.byKey(const ValueKey('client-picker-search')), 'c-200');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text("5'R's Medical Supply"), findsOneWidget);
      expect(find.text('Accuteqs Diagnostics Corp.'), findsNothing);
    });

    testWidgets('says when nothing matches', (tester) async {
      await _open(tester);
      await tester.enterText(
          find.byKey(const ValueKey('client-picker-search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('No client matches "zzz".'), findsOneWidget);
    });

    testWidgets('offline, it says so and shows the phone\'s accounts',
        (tester) async {
      await _open(tester, search: _offline);

      expect(
          find.byKey(const ValueKey('client-picker-offline')), findsOneWidget);
      expect(find.text("5'R's Medical Supply"), findsOneWidget);
    });

    testWidgets('a slow earlier reply never replaces a newer one',
        (tester) async {
      final slow = Completer<Result<List<ClientModel>>>();
      Future<Result<List<ClientModel>>> search(String term) =>
          term == 'anti' ? slow.future : _online(term);

      await _open(tester, search: search);
      final field = find.byKey(const ValueKey('client-picker-search'));
      await tester.enterText(field, 'anti');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(field, 'accu');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // "anti" answers last, with Antipolo; the list must stay on "accu".
      slow.complete(Result.success([_registry.first]));
      await tester.pumpAndSettle();
      expect(find.text('Accuteqs Diagnostics Corp.'), findsOneWidget);
      expect(find.text('Antipolo Doctors Hospital'), findsNothing);
    });
  });

  group('the CWT Pick-up form', () {
    Future<_Activity> pumpForm(WidgetTester tester) async {
      final activity = _Activity();
      Get.put<CollectionActivityController>(activity);
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: const CWTPickupFormScreen(),
      ));
      await tester.pumpAndSettle();
      return activity;
    }

    testWidgets('the account is picked, and saves with its client id',
        (tester) async {
      final activity = await pumpForm(tester);

      await tester.tap(find.byKey(const ValueKey('cwt-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antipolo Doctors Hospital'));
      await tester.pumpAndSettle();

      expect(find.text('Antipolo Doctors Hospital'), findsOneWidget,
          reason: 'the field shows the chosen client');
      expect(find.text('C-100'), findsOneWidget,
          reason: 'with its code under it');

      await tester.tap(find.text('Record CWT pick-up'));
      await tester.pumpAndSettle();

      expect(activity.saved.single.clientId, 'C-100');
      expect(activity.saved.single.accountName, 'Antipolo Doctors Hospital');

      // Let the form's success snackbar run out its timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('cannot be recorded without an account', (tester) async {
      final activity = await pumpForm(tester);

      await tester.tap(find.text('Record CWT pick-up'));
      await tester.pumpAndSettle();

      expect(find.text('Choose the account'), findsOneWidget);
      expect(activity.saved, isEmpty);
    });

    testWidgets('the account field cannot be typed into', (tester) async {
      await pumpForm(tester);
      final field = tester.widget<TextField>(find.descendant(
          of: find.byKey(const ValueKey('cwt-account')),
          matching: find.byType(TextField)));
      expect(field.readOnly, isTrue);
    });
  });
}
