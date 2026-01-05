import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'local_storage_data_controller.dart';

/// Widget to view all local storage tables with dropdown selection
class LocalStorageDataViewer extends StatelessWidget {
  const LocalStorageDataViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LocalStorageDataController());

    return Scaffold(
      appBar: BAppBar(
        title: Text(
          'Local Storage Data Viewer',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        showBackArrow: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => controller.clearTable(),
            tooltip: 'Clear Table',
          ),
        ],
      ),
      body: Column(
        children: [
          // Table selector dropdown
          Padding(
            padding: const EdgeInsets.all(BSizes.defaultSpace),
            child: Obx(() {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: BColors.grey),
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                ),
                child: DropdownButton<String>(
                  value: controller.selectedTable.value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: controller.availableTables.map((table) {
                    return DropdownMenuItem<String>(
                      value: table,
                      child: Text(table),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectTable(value);
                    }
                  },
                ),
              );
            }),
          ),

          // Table info and refresh button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() {
                  return Text(
                    'Total: ${controller.tableData.length} rows',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => controller.loadTableData(),
                ),
              ],
            ),
          ),

          const SizedBox(height: BSizes.spaceBtwItems),

          // Data display
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.tableData.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data in ${controller.selectedTable.value}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                itemCount: controller.tableData.length,
                itemBuilder: (context, index) {
                  final row = controller.tableData[index];
                  return Dismissible(
                    key: Key('${controller.selectedTable.value}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: BSizes.spaceBtwItems),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text('Are you sure you want to delete this row?'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      controller.deleteRow(row);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: BSizes.spaceBtwItems),
                      child: ExpansionTile(
                        title: Text(
                          'Row ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _getRowSummary(row),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(BSizes.borderRadiusMd),
                                bottomRight: Radius.circular(BSizes.borderRadiusMd),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: row.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: BColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: SelectableText(
                                          entry.value?.toString() ?? 'null',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Get a summary of the row for display in subtitle
  String _getRowSummary(Map<String, dynamic> row) {
    final keys = row.keys.take(3).toList();
    return keys.map((key) => '$key: ${row[key]}').join(', ');
  }
}

