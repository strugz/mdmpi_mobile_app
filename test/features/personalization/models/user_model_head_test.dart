import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// The chosen Head (Collection TODO item 13) rides on the user record, so it
/// follows the user to another phone (Firestore) and reads offline (cache).
void main() {
  test('HeadKey and HeadName round-trip through the Firestore and cache JSON',
      () {
    final user = UserModel(
        id: 'uid-1',
        firstName: 'Jay',
        lastName: 'Abaoag',
        username: 'cwt_jay',
        email: 'j@x',
        phoneNumber: '0917',
        profilePicture: '',
        initial: 'JCA',
        headKey: 'MDD',
        headName: 'Maria Dela Cruz');

    expect(user.toJson()['HeadKey'], 'MDD');
    expect(user.toJson()['HeadName'], 'Maria Dela Cruz');

    final back = UserModel.fromJson(user.toLocalJson());
    expect(back.id, 'uid-1');
    expect(back.headKey, 'MDD');
    expect(back.headName, 'Maria Dela Cruz');
  });

  test('a record without a Head reads as empty, not null', () {
    final back = UserModel.fromJson({'FirstName': 'Jay'});
    expect(back.headKey, '');
    expect(back.headName, '');
    expect(UserModel.empty().headKey, '');
  });
}
