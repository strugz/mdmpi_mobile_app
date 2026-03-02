import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/loaders/animation_loader.dart';
import 'package:mdmpi_mobile_app/data/controllers/client_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_modal.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_modal.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/widgets/pick_up_modal.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/air_sea/widgets/air_sea_modal.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/air_sea_modal_config.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_modal_config.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/signature_capture_dialog.dart';

import '../../../common/widgets/texts/product_title_text.dart';
import '../../../data/controllers/app_data/user_initial_controller.dart';
import '../../../features/authentication/presentation/controllers/signup_controller.dart';
import '../../../features/logistics/controllers/air_sea_controller.dart';
import '../../../features/logistics/controllers/standard_delivery_controller.dart';
import '../../../features/logistics/models/standard_delivery_model.dart';
import '../../../features/logistics/models/pull_out_model.dart';
import '../../../features/logistics/models/pick_up_model.dart';
import '../../../features/logistics/models/air_sea_model.dart';
import '../../../common/widgets/dividers/text_divider.dart';
import '../../../common/widgets/modals/b_cancel_remarks.dart';
import '../../../common/widgets/modals/request_modal_scaffold.dart';
import '../../../common/widgets/buttons/status_action_button.dart';
import '../../../features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_modal_header.dart';
import '../../../features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_request_modal_footer.dart';

/// A utility class for managing a full-screen loading dialog.
class BFullScreenLoader {
  /// Open a full-screen loading dialog with a given text and animation.
  /// This method doesn't return anything.
  ///
  ///   Parameters:
  ///   - text: The text t be displayed in the loading dialog.
  ///   - animation: The Lottie animation to be shown.
  static void openLoadingDialog(String text, String animation) {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          color: BHelperFunctions.isDarkMode(Get.context!)
              ? BColors.dark
              : BColors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 250),
              BAnimationLoaderWidget(text: text, animation: animation)
            ],
          ),
        ),
      ),
    );
  }

  /// Open a half screen dialog for Pick and Dispatch Items and Delivery of Items
  static void showRequestForReleasingDialog1(BuildContext context,
      StandardDeliveryModel requestModel, VoidCallback onPressed) {
    showModalBottomSheet<void>(
        enableDrag: true,
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: BRoundedContainer(
              radius: 0,
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      BProductTitleText(
                          title: requestModel.client.name,
                          maxLines: 2,
                          bold: true),
                      BProductTitleText(
                          title: requestModel.client.address,
                          maxLines: 2,
                          smallSize: true),
                      const SizedBox(height: BSizes.xs),
                      requestModel.status != BTexts.statusNewRequest
                          ? BProductTitleText(
                              title: "Item Prepared By: CLC",
                              maxLines: 2,
                              smallSize: true)
                          : Container(),
                      const SizedBox(height: BSizes.xs),
                      const Divider(),
                      const SizedBox(height: BSizes.xs),
                      ListView.separated(
                        shrinkWrap: true,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: BSizes.spaceBtwItems),
                        itemCount: requestModel.documentReference.length,
                        itemBuilder: (_, index) {
                          String reference =
                              requestModel.documentReference[index];
                          return BProductTitleText(
                              title: reference, maxLines: 1, smallSize: true);
                        },
                      ),
                      const SizedBox(height: BSizes.spaceBtwSections),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          requestModel.status == BTexts.statusForDelivery ||
                                  requestModel.status ==
                                      BTexts.statusDoneDelivery
                              ? BProductTitleText(
                                  title: "Delivered By: MAR",
                                  maxLines: 2,
                                  smallSize: true)
                              : Container(),
                          const SizedBox(height: BSizes.xs),
                          requestModel.status == BTexts.statusDoneDelivery
                              ? BProductTitleText(
                                  title: "Received By: MDD",
                                  maxLines: 2,
                                  smallSize: true)
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 20.0,
                    left: 0,
                    right: 0,
                    child: requestModel.status == BTexts.statusDoneDelivery
                        ? Container()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onPressed,
                              child:
                                  requestModel.status == BTexts.statusNewRequest
                                      ? Text("Prepare Item")
                                      : requestModel.status == "Dispatch Items"
                                          ? Text("Dispatch")
                                          : Text("Drop Off"),
                            ),
                          ),
                  )
                ],
              ),
            ),
          );
        });
  }

  /// Stop the currently open loading dialog.
  /// This method doesn't return anything.
  static void stopLoading() {
    Navigator.of(Get.overlayContext!)
        .pop(); //  Close the dialog using the Navigator
  }

  /// Open a half screen dialog with a text and list to search for a client to select
  static void showSearchSheet(
      BuildContext context,
      ClientController clientController,
      StandardDeliveryController requestController) {
    final FocusNode searchFocusNode = FocusNode();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Important for height
      builder: (BuildContext context) {
        // Request focus when modal is shown
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchFocusNode.requestFocus();
        });

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  focusNode: searchFocusNode,
                  controller: clientController.query,
                  decoration: InputDecoration(
                      labelText: 'Search by Client:',
                      prefixIcon: Icon(Iconsax.user)),
                  onFieldSubmitted: (value) {
                    clientController.filterClientFromDb(value);
                  },
                ),
                SizedBox(height: BSizes.spaceBtwItems),
                Expanded(
                  child: ListView.builder(
                    itemCount: clientController.searchClient.length,
                    itemBuilder: (_, index) {
                      final client = clientController.searchClient[index];
                      return InkWell(
                        onTap: () {
                          requestController
                              .updateRequestClientInformation(client);
                          Navigator.of(context).pop();
                        },
                        child: ListTile(
                          title: Text(client.name),
                          subtitle: Text(client.address),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Open a half screen dialog with a text and list to search for a client to select
  static void showRoleChecklistItem(
      BuildContext context, SignupController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Important for height
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.3,
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Obx(
                    () => ListView(
                      children: controller.roles.value.map(
                        (role) {
                          return CheckboxListTile(
                            value: role.status,
                            title: Text(role.role),
                            onChanged: (bool? newValue) {
                              role.status = newValue!;
                              controller.updateRole(role.role);
                              controller.roles.refresh();
                            },
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showUserChecklistItem({
    required BuildContext context,
    required TextEditingController currentSelectionController,
    required String dialogTitle, // Add a title for clarity
  }) {
    final userController = Get.find<UserInitialController>();

    // Function to update the TextEditingController when selections change
    void updateTextField() {
      final selectedUser = userController.userList
          .where((user) => user.status == true)
          .map((user) => user.initial)
          .toList();
      currentSelectionController.text =
          selectedUser.isEmpty ? '' : selectedUser.join(', ');
    }

    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            padding: EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
            child: Obx(() {
              // Sort the list based on the current selection
              userController.userList.sort((a, b) {
                final statusA = a.status;
                final statusB = b.status;
                if (statusA != statusB) {
                  return statusA ? -1 : 1;
                }
                return a.fullName.compareTo(b.fullName);
              });
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: BSizes.md),
                    child: Text(
                      '$dialogTitle: ${currentSelectionController.text}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  // Use ListView.builder for better performance
                  Expanded(
                    child: ListView.builder(
                      // Use ListView.builder for better performance
                      itemCount: userController.userList.length,
                      itemBuilder: (context, index) {
                        final user = userController.userList[index];
                        return CheckboxListTile(
                          value: user.status,
                          title: Text(user.fullName),
                          onChanged: (bool? newValue) {
                            if (newValue != null) {
                              // Update the user's status
                              user.status = newValue;
                              // Update the local list
                              userController.userList.refresh();
                              // Update the text field
                              updateTextField();
                            }
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: BSizes.spaceBtwSections),
                  SafeArea(
                    bottom: !isGestureNavigation,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // The TextEditingController is already updated by onChanged
                          Navigator.of(context).pop();
                        },
                        child: Text('Done'),
                      ),
                    ),
                  ),
                  SizedBox(height: BSizes.md),
                ],
              );
            }),
          ),
        );
      },
    ).whenComplete(() {
      // This is a good place to ensure the text field is updated one last time
      // in case the dialog is dismissed by other means (e.g., back button).
      updateTextField();
    });
  }

  static void showRequestTransportSignatureDialog(
      BuildContext context, IDeliveryRequestController requestController) {
    BSignatureCaptureDialog.show(
      context: context,
      onSave: (Uint8List? signatureBytes) {
        requestController.setSignature(signatureBytes);
      },
    );
  }

  static void showSignatureDialogForPullOut(
      BuildContext context, PullOutController requestController) {
    BSignatureCaptureDialog.show(
      context: context,
      onSave: (Uint8List? signatureBytes) {
        requestController.setSignature(signatureBytes);
      },
    );
  }

  static void showRequestForReleasingDialog(BuildContext context,
      StandardDeliveryModel requestModel, VoidCallback onPressed, bool status,
      IDeliveryRequestController requestController) {
    final dark = BHelperFunctions.isDarkMode(context);

    showModalBottomSheet<void>(
      backgroundColor: dark ? BColors.black : BColors.light,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: BModal(
            requestModel: requestModel,
            onPressed: onPressed,
            requestController: requestController,
            status: status,
          ),
        );
      },
    );
  }

  /// Show Pull Out request modal dialog driven by [PullOutModalConfig].
  static void showPullOutDialog(
    BuildContext context,
    PullOutModel requestModel,
    PullOutModalConfig config,
  ) {
    final dark = BHelperFunctions.isDarkMode(context);
    showModalBottomSheet<void>(
      backgroundColor: dark ? BColors.black : BColors.light,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: PullOutModal(
              requestModel: requestModel,
              config: config,
            ),
          ),
        );
      },
    );
  }

  static void showSignatureDialogForPickUp(
      BuildContext context, PickUpController requestController) {
    BSignatureCaptureDialog.show(
      context: context,
      onSave: (Uint8List? signatureBytes) {
        requestController.formState.setSignature(signatureBytes);
      },
    );
  }

  static void showPickUpDialog(
    BuildContext context,
    PickUpModel requestModel,
    VoidCallback onPressed,
    bool isActionVisible,
  ) {
    final dark = BHelperFunctions.isDarkMode(context);
    showModalBottomSheet<void>(
      backgroundColor: dark ? BColors.black : BColors.light,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: PickUpModal(
            requestModel: requestModel,
            onPressed: onPressed,
            isActionVisible: isActionVisible,
          ),
        );
      },
    );
  }

  /// Show Air/Sea request modal dialog driven by [AirSeaModalConfig].
  static void showAirSeaDialog(
    BuildContext context,
    AirSeaModel requestModel,
    AirSeaModalConfig config,
  ) {
    final dark = BHelperFunctions.isDarkMode(context);
    showModalBottomSheet<void>(
      backgroundColor: dark ? BColors.black : BColors.light,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: AirSeaModal(
              requestModel: requestModel,
              config: config,
            ),
          ),
        );
      },
    );
  }

  /// Show signature capture dialog for Air/Sea
  static void showSignatureDialogForAirSea(
      BuildContext context, AirSeaController controller) {
    BSignatureCaptureDialog.show(
      context: context,
      onSave: (bytes) {
        controller.formState.setSignature(bytes);
      },
    );
  }

  /// Show Stock Receive modal dialog
  static void showStockReceiveDialog(
    BuildContext context,
    PullOutModel requestModel,
    VoidCallback onPressed,
    bool isActionVisible,
  ) {
    final dark = BHelperFunctions.isDarkMode(context);
    showModalBottomSheet<void>(
      backgroundColor: dark ? BColors.black : BColors.light,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // Import StockReceiveModal dynamically to avoid circular dependencies
        // Implement as a factory that creates the appropriate modal
        return _buildStockReceiveModal(
          context,
          requestModel,
          onPressed,
          isActionVisible,
        );
      },
    );
  }

  /// Helper to build stock receive modal (avoids circular dependency)
  static Widget _buildStockReceiveModal(
    BuildContext context,
    PullOutModel requestModel,
    VoidCallback onPressed,
    bool isActionVisible,
  ) {
    // Dynamic import or inline the modal build
    return SafeArea(
      child: _StockReceiveModalContent(
        requestModel: requestModel,
        onPressed: onPressed,
        isActionVisible: isActionVisible,
      ),
    );
  }
}

/// Internal widget for rendering stock receive modal content
/// This avoids circular dependency issues by being defined here
class _StockReceiveModalContent extends StatelessWidget {
  final PullOutModel requestModel;
  final VoidCallback onPressed;
  final bool isActionVisible;

  const _StockReceiveModalContent({
    required this.requestModel,
    required this.onPressed,
    this.isActionVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = requestModel.requestStatus == BTexts.statusCancelled;
    final controller = Get.find<StockReceiveController>();

    // Load cancel remarks if cancelled
    if (isCancelled) {
      controller.loadCancelRemarks(requestModel.id);
    }

    return RequestModalScaffold(
      header: PullOutRequestModalHeader(requestModel: requestModel),
      documentReferences: requestModel.documentReference,
      bottomAction: StatusActionButton(
        status: requestModel.requestStatus,
        onPressed: onPressed,
        isVisible: isActionVisible,
        statusToTextMapper: (status) {
          if (status == null) return 'Proceed';
          switch (status) {
            case 'New Request':
              return 'Set In Transit';
            case 'In Transit':
              return 'Mark Taken Out';
            case 'Taken Out':
              return '';
            default:
              return 'Proceed';
          }
        },
      ),
      children: [
        if (isCancelled) BTextDivider(text: 'Cancel Remarks'),
        Obx(() {
          controller.loadCancelRemarks(requestModel.id);
          final remarks = controller.cancelRemarks.value;
          if (remarks == null || remarks.remarks.isEmpty) {
            return const SizedBox.shrink();
          }
          return BCancelRemarks(
            remarks: remarks.remarks,
            date: remarks.date,
            user: remarks.userUpdated,
          );
        }),
        PullOutRequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
