import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_request_transport_mobile.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

import '../../../../../../base/utils/constants/colors.dart';
import '../../../../../../base/utils/constants/sizes.dart';
import '../../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../../../data/controllers/app_data/user_initial_controller.dart';
import '../../../../models/request_model.dart';

class RequestModalHeader extends StatelessWidget {
  const RequestModalHeader({
    super.key,
    required this.requestModel,
  });

  final RequestModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final userController = Get.find<UserInitialController>();
    final requestController = Get.find<RequestController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Client name
        BProductTitleText(
            title: requestModel.client.name,
            maxLines: 1,
            bold: true,
            fontColor: dark ? BColors.light : BColors.black),
        const SizedBox(height: BSizes.xs),

        /// Client address
        requestModel.client.address.isEmpty
            ? Container()
            : BProductTitleText(
                title: requestModel.client.address,
                maxLines: 1,
                smallSize: true,
                fontColor: dark ? BColors.light : BColors.black),
        const SizedBox(height: BSizes.xs),

        /// Request status
        requestModel.status != BTexts.statusNewRequest
            ? BProductTitleText(
                title: requestModel.status != BTexts.statusNewRequest &&
                        requestModel.status == BTexts.statusGettingSuppliesReady
                    ? "Preparing By: ${requestModel.itemPreparedBy}"
                    : "Prepared By: ${requestModel.itemPreparedBy}",
                maxLines: 2,
                smallSize: true,
                fontColor: dark ? BColors.light : BColors.black)
            : Container(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (requestModel.itemPreparedAt.isNotEmpty)
              BProductTitleText(
                  title:
                      'From: ${requestModel.itemPreparedAt.substring(0, 16)}',
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black),
            if (requestModel.itemPreparedEndAt.isNotEmpty)
              BProductTitleText(
                  title:
                      'To: ${requestModel.itemPreparedEndAt.substring(0, 16)}',
                  maxLines: 2,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.black)
          ],
        ),
        const SizedBox(height: BSizes.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Trip ticket number label
            if (requestModel.tripTicketNumber.isNotEmpty)
              BProductTitleText(
                title:
                    'Trip Ticket No: ${requestModel.tripTicketNumber.substring(0, min(16, requestModel.tripTicketNumber.length))}',
                maxLines: 2,
                fontColor: dark ? BColors.light : BColors.black,
              ),

            /// Trip ticket number text field
            if (requestModel.status == BTexts.statusGettingSuppliesReady &&
                requestModel.tripTicketNumber.isEmpty)
              TextFormField(
                controller:
                    RequestController.instance.formState.tripTicketNumber,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Trip Ticket No',
                  labelStyle: TextStyle(
                    color: dark ? BColors.light : BColors.black,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: dark ? BColors.light : BColors.black,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: dark ? BColors.light : BColors.black,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: dark ? BColors.light : BColors.black,
                      width: 2.0,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: dark ? BColors.light : BColors.black,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
          ],
        ),
        const SizedBox(height: BSizes.sm),
        if (requestModel.status == BTexts.statusGettingSuppliesReady)
          Column(
            children: [
              // Driver dropdown
              Obx(
                () => userController.userList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownList(
                        label: 'Driver',
                        dropdownList: userController.userList,
                        controller: requestController.formState.selectedDriver,
                        getValue: (user) => user.initial,
                        getDisplay: (user) => user.initial,
                        onChanged: (UserModel? value) {
                          requestController.formState.selectedDriver.text =
                              value?.initial ?? '';
                        },
                      ),
              ),
              const SizedBox(height: BSizes.sm),
              Obx(
                () => userController.userList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownList(
                        label: 'Helper',
                        dropdownList: userController.userList,
                        controller: requestController.formState.selectedHelper,
                        getValue: (user) => user.initial,
                        getDisplay: (user) => user.initial,
                        onChanged: (UserModel? value) {
                          requestController.formState.selectedHelper.text =
                              value?.initial ?? '';
                        },
                      ),
              ),
              const SizedBox(height: BSizes.sm),
              BRequestTransportMobile(requestController: requestController)
            ],
          ),
      ],
    );
  }
}
