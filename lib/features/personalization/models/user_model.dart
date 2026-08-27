import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// Model class representing user data.
class UserModel {
  //  Keep those values final which you do not want to update
  final String id;
  String firstName;
  String lastName;
  final String username;
  final String email;
  String phoneNumber;
  String profilePicture;
  String initial;
  String department;
  String role;
  bool status;

  /// Constructor for UserModel
  UserModel(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.username,
      required this.email,
      required this.phoneNumber,
      required this.profilePicture,
      this.initial = '',
      this.department = '',
      this.role = '',
      this.status = false});

  /// Helper function to get the full name.
  String get fullName => '$firstName $lastName';

  /// Helper function to get initials.
  String get initials {
    if (initial.isNotEmpty) return initial;
    String first = firstName.isNotEmpty ? firstName[0] : '';
    String last = lastName.isNotEmpty ? lastName[0] : '';
    return (first + last).toUpperCase();
  }

  /// Helper function to format phone number.
  String get formattedPhoneNo => BFormatter.formatPhoneNumber(phoneNumber);

  /// Static function to split full name into first and last name.
  static List<String> nameParts(String fullName) => fullName.split(" ");

  /// Static function to generate a username from the full name.
  static String generateUsername(String fullName) {
    List<String> nameParts = fullName.split(" ");
    String firstName = nameParts.isNotEmpty ? nameParts[0].toLowerCase() : '';
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join('').toLowerCase() : "";

    String camelCaseUsername = "$firstName$lastName"; // Combine first and last name
    String usernameWithPrefix = "cwt_$camelCaseUsername"; //  Add "cwt_" prefix
    return usernameWithPrefix;
  }

  /// Static function to create on empty user model.
  static UserModel empty() => UserModel(
      id: '',
      firstName: '',
      lastName: '',
      username: '',
      email: '',
      phoneNumber: '',
      profilePicture: '',
      initial: '',
      department: '',
      role: '');

  /// Convert model to JSON structure for storing data in Firebase.
  Map<String, dynamic> toJson() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'Username': username,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'ProfilePicture': profilePicture,
      'Initial': initial,
      'Department': department,
      'Role': role,
      'Status': status
    };
  }

  /// Convert model to JSON including [id] for local caching (e.g. GetStorage).
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      ...toJson(),
    };
  }

  /// Build a payload map suitable for updates or API payloads.
  /// Omits null values and empty strings to keep the payload small.
  Map<String, dynamic> toMapper() {
    final Map<String, dynamic> data = {};

    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      data[key] = value;
    }

    put('FirstName', firstName);
    put('LastName', lastName);
    put('Username', username);
    put('Email', email);
    put('PhoneNumber', phoneNumber);
    put('ProfilePicture', profilePicture);
    put('Initial', initial);
    put('Department', department);
    put('Role', role);
    put('Status', status);

    return data;
  }

  /// Factory method to create a UserModel from a Firebase document snapshot.
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;

      return UserModel(
          id: document.id,
          firstName: data['FirstName'] ?? '',
          lastName: data['LastName'] ?? '',
          username: data['Username'] ?? '',
          email: data['Email'] ?? '',
          phoneNumber: data['PhoneNumber'] ?? '',
          profilePicture: data['ProfilePicture'] ?? '',
          initial: data['Initial'] ?? '',
          department: data['Department'] ?? '',
          role: data['Role'] ?? '',
          status: false);
    } else {
      return UserModel.empty();
    }
  }

  /// Factory method to create a UserModel from a JSON object.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ??
          '', // Assuming 'id' might be in the JSON or handled elsewhere
      firstName: json['FirstName'] ?? '',
      lastName: json['LastName'] ?? '',
      username: json['Username'] ?? '',
      email: json['Email'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? '',
      profilePicture: json['ProfilePicture'] ?? '',
      initial: json['Initial'] ?? '',
      department: json['Department'] ?? '',
      role: json['Role'] ?? '',
      status: false,
    );
  }
}
