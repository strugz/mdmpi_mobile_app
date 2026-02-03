/// Text-based Local Storage Service
///
/// Provides a reusable interface for storing and retrieving text data locally
/// using GetStorage (key-value storage, not database).
///
/// Usage:
/// ```dart
/// final storage = TextStorageService();
/// await storage.saveText('userEmail', 'user@example.com');
/// final email = await storage.getText('userEmail');
/// await storage.removeText('userEmail');
/// ```

import 'package:get_storage/get_storage.dart';

class TextStorageService {
  late final GetStorage _box;

  TextStorageService() {
    _box = GetStorage();
  }

  /// Saves text data to local storage.
  ///
  /// [key] The unique identifier for the stored text
  /// [value] The text value to store
  ///
  /// Returns a Future that completes when the operation is done.
  Future<void> saveText(String key, String value) async {
    await _box.write(key, value);
  }

  /// Retrieves text data from local storage.
  ///
  /// [key] The unique identifier for the stored text
  ///
  /// Returns the stored text value, or null if not found.
  String? getText(String key) {
    return _box.read<String>(key);
  }

  /// Retrieves text data with a default value if not found.
  ///
  /// [key] The unique identifier for the stored text
  /// [defaultValue] The value to return if key is not found
  ///
  /// Returns the stored text value, or [defaultValue] if not found.
  String getTextOrDefault(String key, String defaultValue) {
    return _box.read<String>(key) ?? defaultValue;
  }

  /// Removes text data from local storage.
  ///
  /// [key] The unique identifier for the stored text
  ///
  /// Returns a Future that completes when the operation is done.
  Future<void> removeText(String key) async {
    await _box.remove(key);
  }

  /// Checks if a text value exists in local storage.
  ///
  /// [key] The unique identifier to check
  ///
  /// Returns true if the key exists, false otherwise.
  bool hasText(String key) {
    return _box.hasData(key);
  }

  /// Clears all text data from local storage.
  ///
  /// ⚠️ Use with caution - this removes ALL stored data!
  ///
  /// Returns a Future that completes when the operation is done.
  Future<void> clearAll() async {
    await _box.erase();
  }

  /// Saves multiple text entries at once.
  ///
  /// [entries] A map of key-value pairs to store
  ///
  /// Returns a Future that completes when all operations are done.
  Future<void> saveMultiple(Map<String, String> entries) async {
    for (final entry in entries.entries) {
      await _box.write(entry.key, entry.value);
    }
  }

  /// Retrieves all stored data as a map.
  ///
  /// Returns a Map containing all stored key-value pairs.
  Map<String, dynamic> getAll() {
    return _box.getValues();
  }
}
