import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

import '../../../../../base/utils/constants/colors.dart';
import 'b_request_text_scanner.dart';
import '../../../controllers/request_controller.dart';

class BDocumentReference extends StatelessWidget {
  const BDocumentReference({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<RequestController>();
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
                        Get.to(() => TextScanner(controller: controller));
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
