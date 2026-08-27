import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';

class StockReceiveForm extends StatelessWidget {
  const StockReceiveForm({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<RequestController>();

    return Scaffold(
      appBar: BAppBar(
        title: Text(
          BTexts.getRequestFormTitle(
            requestController.currentSelectedCategory.value?.name,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        showBackArrow: true,
      ),
    );
  }
}
