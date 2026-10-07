import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/my_head_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/my_head_screen.dart';

const _mdd = DirectoryUser(
    key: 'MDD', name: 'Maria Dela Cruz', department: 'COLLECTION');
const _ajs =
    DirectoryUser(key: 'AJS', name: 'Andres Santos', department: 'IMS');

UserModel _user({String head = '', String headName = ''}) => UserModel(
    id: 'uid',
    firstName: 'Jay',
    lastName: 'Abaoag',
    username: 'u',
    email: 'e',
    phoneNumber: '',
    profilePicture: '',
    initial: 'JCA',
    headKey: head,
    headName: headName);

void main() {
  tearDown(Get.reset);

  late List<({String key, String name})> saved;

  Future<void> pump(WidgetTester tester,
      {UserModel? user, String? suggested}) async {
    saved = [];
    Get.put(MyHeadController(
      directory: ({bool refresh = false}) async =>
          Result.success(const [_ajs, _mdd]),
      currentUser: () => user ?? _user(),
      suggestedHeadKey: (_) async => suggested,
      save: ({required String key, required String name}) async =>
          saved.add((key: key, name: name)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: MyHeadScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> drainSnackbar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('shows Not set, the suggestion and everyone in the directory',
      (tester) async {
    await pump(tester, suggested: 'MDD');

    expect(find.text('Not set'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-head-suggestion')), findsOneWidget);
    expect(find.text('Suggested: Maria Dela Cruz'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-head-person-AJS')), findsOneWidget);
    expect(find.byKey(const ValueKey('my-head-person-MDD')), findsOneWidget);
    expect(find.byKey(const ValueKey('my-head-clear')), findsNothing);
  });

  testWidgets('tapping a person asks first, then saves them as the Head',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('my-head-person-AJS')));
    await tester.pumpAndSettle();
    expect(find.text('Set as your Head?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('my-head-confirm')));
    await tester.pumpAndSettle();

    expect(saved, [(key: 'AJS', name: 'Andres Santos')]);
    expect(find.text('Andres Santos'), findsWidgets);
    expect(find.byKey(const ValueKey('my-head-clear')), findsOneWidget);
    await drainSnackbar(tester);
  });

  testWidgets('Cancel in the confirmation saves nothing', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('my-head-person-AJS')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(saved, isEmpty);
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('Use on the suggestion goes through the same confirmation',
      (tester) async {
    await pump(tester, suggested: 'MDD');

    await tester.tap(find.byKey(const ValueKey('my-head-use-suggestion')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-head-confirm')));
    await tester.pumpAndSettle();

    expect(saved, [(key: 'MDD', name: 'Maria Dela Cruz')]);
    expect(find.byKey(const ValueKey('my-head-suggestion')), findsNothing);
    await drainSnackbar(tester);
  });

  testWidgets('Clear removes the saved Head', (tester) async {
    await pump(tester, user: _user(head: 'MDD', headName: 'Maria Dela Cruz'));
    expect(find.text('Not set'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('my-head-clear')));
    await tester.pumpAndSettle();

    expect(saved, [(key: '', name: '')]);
    expect(find.text('Not set'), findsOneWidget);
    await drainSnackbar(tester);
  });

  testWidgets('search narrows the list', (tester) async {
    await pump(tester);

    await tester.enterText(
        find.byKey(const ValueKey('my-head-search')), 'collection');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('my-head-person-MDD')), findsOneWidget);
    expect(find.byKey(const ValueKey('my-head-person-AJS')), findsNothing);
  });
}
