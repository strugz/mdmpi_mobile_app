import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/chart/widgets/indicator.dart';

import '../../../../base/utils/constants/sizes.dart';
import '../../controllers/chart_controller.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChartController>();

    return Obx(() {
      // Obx widget rebuilds when observable variables change
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.errorMessage.value != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(BSizes.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'On-going development',
                  // controller.errorMessage.value!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: BSizes.sm),
                ElevatedButton(
                  onPressed: () => controller.refreshChartData(),
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        );
      }
      if (controller.chartData.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No data available to display the chart.'),
              const SizedBox(height: BSizes.sm),
              ElevatedButton(
                onPressed: () => controller.refreshChartData(),
                child: const Text('Refresh'),
              )
            ],
          ),
        );
      }
      return AspectRatio(
        aspectRatio: 1.6,
        child: Row(
          children: <Widget>[
            const SizedBox(height: BSizes.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 50,
                    borderData: FlBorderData(show: false),
                    sections: controller.chartData.map((data) {
                      return PieChartSectionData(
                        value: data.value,
                        color: data.color,
                        title: data.title,
                        radius: 50, // Example: You might want to adjust radius
                        titleStyle: const TextStyle(
                          fontSize: 12, // Example
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Example
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(right: BSizes.sm, bottom: BSizes.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...controller.chartData.map((data) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Indicator(
                        color: data.color,
                        text: data.legendText,
                        isSquare: true,
                      ),
                    );
                  }),
                  if (controller.chartData.isNotEmpty)
                    const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
