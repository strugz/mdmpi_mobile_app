import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

class ChartSectionData {
  final double value;
  final Color color;
  final String title;
  final String legendText;

  ChartSectionData({
    required this.value,
    required this.color,
    required this.title,
    required this.legendText,
  });

  // Factory constructor to create a ChartSectionData from a JSON object
  factory ChartSectionData.fromJson(Map<String, dynamic> json) {
    return ChartSectionData(
      value: (json['Value'] as num).toDouble(), // Ensure value is a double
      color: _parseColor(json['Color'] as String),
      title: json['Title'] as String,
      legendText: json['Legend'] as String,
    );
  }

  // Helper function to parse color from hex string (e.g., "#FF0000")
  static Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      // Return a default color if parsing fails
      logDebug('Error parsing color: $colorString. Error: $e');
      return Colors.grey;
    }
  }
}
