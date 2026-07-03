import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/api_environment.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

import '../../models/item_category_model.dart';
import '../../local/database_helper.dart';

/// Repository to retrieve Item Categories from backend with local caching.
class ItemCategoryRepository extends GetxController {
  static ItemCategoryRepository get instance => Get.find();

  String get _baseUrl => BApiEnvironment.api4BaseUrl;

  Uri _uri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  static const String _resource = '/api4/Category';
  static const String _publicFallback =
      'https://inventory.mdmpi.com.ph/api4/Category';

  String get _resourceUrl {
    try {
      if (dotenv.isInitialized) {
        final envOverride = dotenv.env['CATEGORY_API'];
        if (envOverride != null && envOverride.isNotEmpty) return envOverride;
      }
    } catch (_) {}
    if (_baseUrl.isNotEmpty) return '$_baseUrl$_resource';
    return _publicFallback;
  }

  Future<List<ItemCategoryModel>> getAll(
      {http.Client? client, bool forceRefresh = false}) async {
    // Try loading from local DB first if not forcing refresh
    if (!forceRefresh) {
      try {
        final dao = await DatabaseHelper.instance.itemCategoryDao;
        final hasData = await dao.hasData();
        if (hasData) {
          logDebug('ItemCategoryRepository.getAll: Loading from local DB');
          return await dao.getAll();
        }
      } catch (e) {
        logDebug('ItemCategoryRepository.getAll: Local DB error: $e');
      }
    }

    final canCheckNetwork = Get.isRegistered<NetworkManager>();
    if (client == null &&
        canCheckNetwork &&
        !await NetworkManager.instance.isConnected()) {
      logDebug('ItemCategoryRepository.getAll: Offline with no local data');
      return <ItemCategoryModel>[];
    }

    // Fetch from API
    final c = client ?? http.Client();
    try {
      final url = _uri(_resourceUrl);
      logDebug('ItemCategoryRepository.getAll: GET $url');
      final res = await c.get(url).timeout(const Duration(seconds: 60));
      logDebug('ItemCategoryRepository.getAll: status=${res.statusCode}');

      if (res.statusCode != 200) {
        throw Exception('Failed to load item categories (${res.statusCode})');
      }

      final raw = res.body;
      if (raw.trim().isEmpty) return <ItemCategoryModel>[];

      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        return <ItemCategoryModel>[];
      }

      List list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        list = (decoded['data'] as List?) ??
            (decoded['items'] as List?) ??
            (decoded.values.firstWhere((v) => v is List, orElse: () => const [])
                as List);
      } else {
        list = const [];
      }

      list = list.where((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final type = (m['type'] ?? m['Type'] ?? '').toString().toUpperCase();
        return type == 'ITEM';
      }).toList();

      final items = list
          .map((e) => ItemCategoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Cache to local DB
      try {
        final dao = await DatabaseHelper.instance.itemCategoryDao;
        await dao.deleteAll();
        await dao.insertItemCategories(items);
        logDebug(
            'ItemCategoryRepository.getAll: Cached ${items.length} items to local DB');
      } catch (e) {
        logDebug('ItemCategoryRepository.getAll: Failed to cache: $e');
      }

      return items;
    } finally {
      if (client == null) c.close();
    }
  }

  /// Get item categories from local database only
  Future<List<ItemCategoryModel>> getFromLocal() async {
    final dao = await DatabaseHelper.instance.itemCategoryDao;
    return await dao.getAll();
  }

  /// Save item categories to local database
  Future<void> saveToLocal(List<ItemCategoryModel> items) async {
    final dao = await DatabaseHelper.instance.itemCategoryDao;
    await dao.deleteAll();
    await dao.insertItemCategories(items);
  }

  /// Clear local cache
  Future<void> clearLocal() async {
    final dao = await DatabaseHelper.instance.itemCategoryDao;
    await dao.deleteAll();
  }

  /// Fetch item category by ID
  /// Checks local DB first, if not found fetches all from API and caches them
  Future<String?> fetchItemCategory(String id) async {
    try {
      // First, try to get from local DB
      final dao = await DatabaseHelper.instance.itemCategoryDao;
      final localItem = await dao.getById(id);

      if (localItem != null) {
        logDebug(
            'ItemCategoryRepository.fetchItemCategory: Found ID=$id in local DB');
        return localItem.name;
      }
    } catch (e) {
      logDebug(
          'ItemCategoryRepository.fetchItemCategory: Error fetching ID=$id: $e');
      return null;
    }
    return null;
  }
}
