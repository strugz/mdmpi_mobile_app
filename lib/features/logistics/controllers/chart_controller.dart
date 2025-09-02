import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/chart_section_model.dart';

class ChartController extends GetxController {
  // Observable list to hold chart data
  var chartData = <ChartSectionData>[].obs;
  // Observable to track loading status
  var isLoading = true.obs;
  // Observable to hold error messages
  var errorMessage = RxnString(); // RxnString allows null values

  @override
  void onInit() {
    super.onInit();
    fetchChartData(); // Fetch data when the controller is initialized
  }

  Future<void> fetchChartData() async {
    // Replace with your actual API endpoint
    final String apiUrl = 'https://your-api-endpoint.com/chart-data';
    try {
      isLoading(true); // Set loading to true
      errorMessage(null); // Clear previous errors

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body) as List<dynamic>;
        chartData.value = jsonData
            .map((item) => ChartSectionData.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        errorMessage('Failed to load chart data. Status code: ${response.statusCode}');
        print('Failed to load chart data: ${response.body}');
      }
    } catch (e) {
      errorMessage('Error fetching chart data: $e');
      print('Error fetching chart data: $e');
    } finally {
      isLoading(false); // Set loading to false regardless of outcome
    }
  }

  // Optional: A method to manually refresh data
  void refreshChartData() {
    fetchChartData();
  }
}