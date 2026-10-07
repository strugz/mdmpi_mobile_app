import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/my_head_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// Settings → My Head (Collection TODO item 13): the choice, the suggestion
/// from the CNTMST hierarchy, search, and what a failed save leaves behind.

const _mdd = DirectoryUser(
    key: 'MDD', name: 'Maria Dela Cruz', department: 'COLLECTION');
const _ajs =
    DirectoryUser(key: 'AJS', name: 'Andres Santos', department: 'IMS');
const _jca = DirectoryUser(key: 'JCA', name: 'Jay Abaoag', department: 'IMS');

UserModel _user({String head = '', String headName = ''}) => UserModel(
    id: 'uid',
    firstName: 'Jay',
    lastName: 'Abaoag',
    username: 'u',
    email: 'e',
    phoneNumber: '',
    profilePicture: '',
    initial: 'jca',
    headKey: head,
    headName: headName);

void main() {
  tearDown(Get.reset);

  late List<({String key, String name})> saved;
  late UserModel user;
  late Result<List<DirectoryUser>> directory;
  late String? suggested;
  late String? saveError;

  MyHeadController build() => MyHeadController(
        directory: ({bool refresh = false}) async => directory,
        currentUser: () => user,
        suggestedHeadKey: (own) async => suggested,
        save: ({required String key, required String name}) async {
          if (saveError != null) throw saveError!;
          saved.add((key: key, name: name));
        },
      );

  setUp(() {
    saved = [];
    user = _user();
    directory = Result.success(const [_ajs, _jca, _mdd]);
    suggested = null;
    saveError = null;
  });

  test('a saved Head is shown from the directory', () async {
    user = _user(head: 'mdd', headName: 'Old Name');
    final c = build();
    await c.load();

    expect(c.hasHead, isTrue);
    expect(c.head.value, _mdd);
    expect(c.headDisplayName, 'Maria Dela Cruz',
        reason: 'the directory name is current; the saved one is a fallback');
    expect(c.isHead(_mdd), isTrue);
    expect(c.suggestion.value, isNull, reason: 'no suggestion once chosen');
  });

  test('a Head no longer in the directory still shows by the saved name',
      () async {
    user = _user(head: 'XYZ', headName: 'Former Head');
    final c = build();
    await c.load();

    expect(c.hasHead, isTrue);
    expect(c.head.value, isNull);
    expect(c.headDisplayName, 'Former Head');
  });

  test('with no Head, the first CNTTGP manager is suggested', () async {
    suggested = 'MDD';
    final c = build();
    await c.load();

    expect(c.hasHead, isFalse);
    expect(c.suggestion.value, _mdd);
  });

  test('the user is never suggested as their own Head', () async {
    suggested = 'JCA';
    final c = build();
    await c.load();
    expect(c.suggestion.value, isNull);
  });

  test('choose saves key and name, and drops the suggestion', () async {
    suggested = 'MDD';
    final c = build();
    await c.load();

    expect(await c.choose(_ajs), isNull);

    expect(saved, [(key: 'AJS', name: 'Andres Santos')]);
    expect(c.head.value, _ajs);
    expect(c.hasHead, isTrue);
    expect(c.suggestion.value, isNull);
  });

  test('clear saves blanks and forgets the Head', () async {
    user = _user(head: 'MDD', headName: 'Maria Dela Cruz');
    final c = build();
    await c.load();

    expect(await c.clear(), isNull);

    expect(saved, [(key: '', name: '')]);
    expect(c.hasHead, isFalse);
    expect(c.head.value, isNull);
    expect(c.headDisplayName, '');
  });

  test('a failed save returns the message and keeps the previous Head',
      () async {
    user = _user(head: 'MDD', headName: 'Maria Dela Cruz');
    saveError = 'Something went wrong. Please try again';
    final c = build();
    await c.load();

    final message = await c.choose(_ajs);

    expect(message, contains('Something went wrong'));
    expect(c.head.value, _mdd);
    expect(c.savedHeadKey.value, 'MDD');
    expect(c.isSaving.value, isFalse);
  });

  test('search matches name, code or department, case-insensitively',
      () async {
    final c = build();
    await c.load();

    expect(c.filtered, [_ajs, _jca, _mdd]);
    c.search('maria');
    expect(c.filtered, [_mdd]);
    c.search('ims');
    expect(c.filtered, [_ajs, _jca]);
    c.search('ajs');
    expect(c.filtered, [_ajs]);
    c.search('nobody');
    expect(c.filtered, isEmpty);
  });

  test('a directory failure is reported and the saved Head is still known',
      () async {
    user = _user(head: 'MDD', headName: 'Maria Dela Cruz');
    directory = Result.failure('Could not load the user directory: offline');
    final c = build();
    await c.load();

    expect(c.error.value, contains('offline'));
    expect(c.people, isEmpty);
    expect(c.hasHead, isTrue);
    expect(c.headDisplayName, 'Maria Dela Cruz');
  });

  group('firstManagerOf', () {
    test('skips the company-wide EGL group', () {
      expect(MyHeadController.firstManagerOf('EGL/MDD/AJS'), 'MDD');
      expect(MyHeadController.firstManagerOf('MDD/AJS'), 'MDD');
      expect(MyHeadController.firstManagerOf(' egl / ajs '), 'ajs');
    });

    test('nothing when the chain is empty or EGL only', () {
      expect(MyHeadController.firstManagerOf(null), isNull);
      expect(MyHeadController.firstManagerOf(''), isNull);
      expect(MyHeadController.firstManagerOf('EGL'), isNull);
      expect(MyHeadController.firstManagerOf('EGL//'), isNull);
    });
  });
}
