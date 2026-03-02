import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import 'b_text_scanner.dart';

class BDocumentReference extends StatelessWidget {
  const BDocumentReference({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<StandardDeliveryController>();
    final dark = BHelperFunctions.isDarkMode(context);
    return Center(
      child: Obx(
        () => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: requestController.formState.documentReferenceControllers.map((controller) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
                  child: TextFormField(
                    onTap: () {
                      if (controller.text.isEmpty) {
                        Get.to(() => BTextScanner(controller: controller));
                      }
                    },
                    controller: controller,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Iconsax.document_code),
                        labelText: 'Document Reference',
                        labelStyle: TextStyle(color: dark ? BColors.light : BColors.darkerGrey),
                        suffixIcon: IconButton(
                            onPressed: () {
                              requestController.removeDocumentReferenceField(controller);
                            },
                            icon: Icon(Iconsax.close_circle))),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Document Reference is required';
                      // Optional: prevent duplicates
                      final all = requestController.formState.documentReferenceControllers
                          .map((c) => c.text.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      final count = all.where((s) => s == text).length;
                      if (count > 1) return 'Duplicate document reference';
                      return null;
                    },
                  ),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: requestController.addDocumentReferenceField,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.md),
                child: Text('Add Document Reference'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
