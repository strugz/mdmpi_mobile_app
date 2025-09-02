import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/camera/camera_preview.dart';
import 'package:mdmpi_mobile_app/common/controllers/camera_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';
import '../../../controllers/request_controller.dart';
import '../../../models/request_model.dart';

class BRequestTransportDropOffCapture extends StatelessWidget {
  const BRequestTransportDropOffCapture(
      {super.key, required this.request, required this.requestController});

  final RequestModel request;
  final RequestController requestController;

  @override
  Widget build(BuildContext context) {
    final CameraHandlerController cameraController =
        Get.find<CameraHandlerController>();
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;
    final dark = BHelperFunctions.isDarkMode(context);
    final iconColor = dark ? BColors.light : BColors.black;

    // Define the overlay for this specific screen
    Widget buildScanTextOverlay() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BSizes.defaultSpace),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: IconButton(
              onPressed: () {
                cameraController.takePictureWithAnimation(request.requestID);
              },
              icon: Icon(Icons.camera, size: 52, color: iconColor)),
        ),
      );
    }

    return SafeArea(
      bottom: !isGestureNavigation,
      child: Scaffold(
        appBar: BAppBar(
          title: const Text('Proof Picture'),
          showBackArrow: true,
        ),
        body: Obx(
          () => Stack(
            children: [
              CameraPreview(
                cameraController: cameraController,
                overlayWidget:
                    buildScanTextOverlay(), // Pass the specific overlay
              ),
              if (cameraController.isFlashing.value)
                FadeTransition(
                  opacity: cameraController.flashOpacity,
                  child: Container(
                    color: Colors.white,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
