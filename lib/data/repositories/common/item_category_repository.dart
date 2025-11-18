import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

import '../../models/item_category_model.dart';

/// Repository to retrieve Item Categories from backend.
class ItemCategoryRepository extends GetxController {
  static ItemCategoryRepository get instance => Get.find();

  String get _baseUrl {
    try {
      if (dotenv.isInitialized) return dotenv.env['API_URL'] ?? '';
    } catch (_) {
    }
    return '';
  }
  Uri _uri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    final base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  static const String _resource = '/api4/Category';
  static const String _publicFallback = 'https://inventory.mdmpi.com.ph/api4/Category';

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

  Future<List<ItemCategoryModel>> getAll({http.Client? client}) async {
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
        list = (decoded['data'] as List?) ?? (decoded['items'] as List?) ??
            (decoded.values.firstWhere((v) => v is List, orElse: () => const []) as List);
      } else {
        list = const [];
      }

      list = list.where((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final type = (m['type'] ?? m['Type'] ?? '').toString().toUpperCase();
        return type == 'ITEM';
      }).toList();

      return list
          .map((e) => ItemCategoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } finally {
      if (client == null) c.close();
    }
  }
}
