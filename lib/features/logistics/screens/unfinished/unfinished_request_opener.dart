import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/air_sea_hd_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/unfinished/unfinished_request.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/air_sea_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/hotline_direct/hotline_direct_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/pick_up_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/pull_out_return_pick_up_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/standard_delivery_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/stock_receive/stock_receive_list.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// Opens an unfinished request the same way its own list does on a tap:
/// same role rules, same screen or sheet, same actions.
abstract final class BUnfinishedRequestOpener {
  static void open(BuildContext context, UnfinishedRequest request) {
    final user = Get.find<UserController>();
    final source = request.source;
    try {
      switch (request.type) {
        case FormCategoryType.standardDelivery:
          if (source is! StandardDeliveryModel) return;
          final c = Get.find<StandardDeliveryController>();
          c.currentSelectedRequest.value = source;
          handleStandardDeliveryTap(context, source, c, user);
        case FormCategoryType.hotlineDirect:
          if (source is! StandardDeliveryModel) return;
          final c = Get.find<HotlineDirectController>();
          c.currentSelectedRequest.value = source;
          HotlineDirectList.showAppropriateDialog(context, source, user, c);
        case FormCategoryType.pullOutReturn:
          if (source is! PullOutModel) return;
          final c = Get.find<PullOutController>();
          c.currentSelectedPullOut.value = source;
          handlePullOutTap(context, source, c, user);
        case FormCategoryType.stockReceive:
          if (source is! PullOutModel) return;
          final c = Get.find<StockReceiveController>();
          c.currentSelectedStockReceive.value = source;
          handleStockReceiveTap(context, source, c, user);
        case FormCategoryType.pickUp:
          if (source is! PickUpModel) return;
          final c = Get.find<PickUpController>();
          c.currentSelectedPickUp.value = source;
          handlePickUpTap(context, source, c, user);
        case FormCategoryType.airSea:
        case FormCategoryType.airSeaHd:
          if (source is! AirSeaModel) return;
          final AirSeaController c = request.type == FormCategoryType.airSeaHd
              ? Get.find<AirSeaHdController>()
              : Get.find<AirSeaController>();
          c.currentSelectedAirSea.value = source;
          handleAirSeaTap(context, source, c, user);
      }
    } catch (e) {
      logDebug('BUnfinishedRequestOpener: could not open ${request.id}: $e');
    }
  }
}
