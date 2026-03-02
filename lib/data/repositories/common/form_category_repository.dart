import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

import '../../models/form_category_model.dart';
import '../../local/database_helper.dart';

/// Repository to retrieve Form Categories from backend with local caching.
class FormCategoryRepository extends GetxController {
  static FormCategoryRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';
  Uri _uri(String path) => Uri.parse("$_baseUrl$path");

  static const String _resource = '/api4/Category';

  Future<List<FormCategoryModel>> getAll({bool forceRefresh = false}) async {
    // Try loading from local DB first if not forcing refresh
    if (!forceRefresh) {
      try {
        final dao = await DatabaseHelper.instance.formCategoryDao;
        final hasData = await dao.hasData();
        if (hasData) {
          logDebug('FormCategoryRepository.getAll: Loading from local DB');
          return await dao.getAll();
        }
      } catch (e) {
        logDebug('FormCategoryRepository.getAll: Local DB error: $e');
      }
    }

    // Fetch from API
    final url = _uri(_resource);
    logDebug('FormCategoryRepository.getAll: GET $url');
    final res = await http.get(url).timeout(const Duration(seconds: 60));
    logDebug('FormCategoryRepository.getAll: status=${res.statusCode}');

    if (res.statusCode != 200) {
      throw Exception('Failed to load form categories (${res.statusCode})');
    }

    final raw = res.body;
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = raw;
    }

    List list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = (decoded['data'] as List?) ?? (decoded['items'] as List?) ??
          (decoded.values.firstWhere((v) => v is List, orElse: () => const []) as List);
    } else {
      list = const [];
    }

    list = list.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final type = (m['type'] ?? m['Type'] ?? '').toString().toUpperCase();
      return type == 'FORM';
    }).toList();

    final forms = list
        .map((e) => FormCategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Cache to local DB
    try {
      final dao = await DatabaseHelper.instance.formCategoryDao;
      await dao.deleteAll();
      await dao.insertFormCategories(forms);
      logDebug('FormCategoryRepository.getAll: Cached ${forms.length} forms to local DB');
    } catch (e) {
      logDebug('FormCategoryRepository.getAll: Failed to cache: $e');
    }

    return forms;
  }

  /// Get form categories from local database only
  Future<List<FormCategoryModel>> getFromLocal() async {
    final dao = await DatabaseHelper.instance.formCategoryDao;
    return await dao.getAll();
  }

  /// Save form categories to local database
  Future<void> saveToLocal(List<FormCategoryModel> forms) async {
    final dao = await DatabaseHelper.instance.formCategoryDao;
    await dao.deleteAll();
    await dao.insertFormCategories(forms);
  }

  /// Clear local cache
  Future<void> clearLocal() async {
    final dao = await DatabaseHelper.instance.formCategoryDao;
    await dao.deleteAll();
  }

  /// Fetch form category by ID
  /// Checks local DB first, if not found fetches all from API and caches them
  Future<FormCategoryModel?> fetchFormCategory(String id) async {
    try {
      // First, try to get from local DB
      final dao = await DatabaseHelper.instance.formCategoryDao;
      final localForm = await dao.getById(id);

      if (localForm != null) {
        logDebug('FormCategoryRepository.fetchFormCategory: Found ID=$id in local DB');
        return localForm;
      }

      logDebug('FormCategoryRepository.fetchFormCategory: ID=$id not in local DB, fetching from API');

      // Not in local DB, fetch all from API and cache
      final forms = await getAll(forceRefresh: true);

      // Try to find the requested ID in the fetched forms
      try {
        return forms.firstWhere((form) => form.id == id);
      } catch (_) {
        logDebug('FormCategoryRepository.fetchFormCategory: ID=$id not found even after API fetch');
        return null;
      }
    } catch (e) {
      logDebug('FormCategoryRepository.fetchFormCategory: Error fetching ID=$id: $e');
      return null;
    }
  }
}
