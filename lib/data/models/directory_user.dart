/// One person in the user directory: CNTMST and Firestore `Users` merged.
///
/// A person is keyed by one code, `CNTMNN` in CNTMST and `initial` in
/// Firestore (the same code for the same person), trimmed and upper-cased so
/// " jca" and "JCA" are one person. See [UserDirectoryRepository].
class DirectoryUser {
  const DirectoryUser({
    required this.key,
    required this.name,
    this.department = '',
    this.phone = '',
    this.inCntmst = false,
    this.inFirestore = false,
    this.firestoreId = '',
    this.email = '',
    this.username = '',
  });

  /// The code, trimmed and upper-cased: `CNTMNN` / `initial`.
  final String key;

  /// Display name; the key when neither source has one.
  final String name;

  final String department;

  /// Mobile number for SMS; '' when unknown.
  final String phone;

  final bool inCntmst;
  final bool inFirestore;

  /// The Firestore `Users` document id (Firebase uid); '' when CNTMST only.
  final String firestoreId;

  final String email;

  /// The Firestore `Username`; '' when CNTMST only. It is the code the
  /// Collection backend files a collector's uploads under (`?collector=`),
  /// which is why the Head's picker needs it.
  final String username;

  /// What the Collection backend knows this person as: the username, or the
  /// directory key for someone who has no app account (and so no uploads).
  String get collectorCode => username.isNotEmpty ? username : key;

  bool get hasPhone => phone.trim().isNotEmpty;

  /// Trimmed and upper-cased: the one way two sources compare codes.
  static String normalizeKey(String? code) => (code ?? '').trim().toUpperCase();

  @override
  bool operator ==(Object other) =>
      other is DirectoryUser &&
      other.key == key &&
      other.name == name &&
      other.department == department &&
      other.phone == phone &&
      other.inCntmst == inCntmst &&
      other.inFirestore == inFirestore &&
      other.firestoreId == firestoreId &&
      other.email == email &&
      other.username == username;

  @override
  int get hashCode => Object.hash(key, name, department, phone, inCntmst,
      inFirestore, firestoreId, email, username);

  @override
  String toString() => 'DirectoryUser($key, $name, $department)';
}
