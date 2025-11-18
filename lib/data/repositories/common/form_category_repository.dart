import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

import '../../models/form_category_model.dart';

/// Repository to retrieve Form Categories from backend.
class FormCategoryRepository extends GetxController {
  static FormCategoryRepository get instance => Get.find();

  String get _baseUrl => dotenv.env['API_URL'] ?? '';
  Uri _uri(String path) => Uri.parse("$_baseUrl$path");

  static const String _resource = '/api4/Category';

  Future<List<FormCategoryModel>> getAll() async {
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

    return list
        .map((e) => FormCategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
