import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/loaders/animation_loader.dart';
import 'package:mdmpi_mobile_app/data/controllers/client_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/request_modal.dart';

import '../../../common/widgets/signature/signature_pad.dart';
import '../../../common/widgets/texts/product_title_text.dart';
import '../../../data/controllers/app_data/user_initial_controller.dart';
import '../../../features/authentication/controllers/signup/signup_controller.dart';
import '../../../features/logistics/controllers/request_controller.dart';
import '../../../features/logistics/models/request_model.dart';

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
  static void showRequestForReleasingDialog1(
      BuildContext context, RequestModel requestModel, VoidCallback onPressed) {
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
                      requestModel.status != "New Request"
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
                          requestModel.status == "For Delivery" ||
                                  requestModel.status == "Done Delivery"
                              ? BProductTitleText(
                                  title: "Delivered By: MAR",
                                  maxLines: 2,
                                  smallSize: true)
                              : Container(),
                          const SizedBox(height: BSizes.xs),
                          requestModel.status == "Done Delivery"
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
                    child: requestModel.status == "Done Delivery"
                        ? Container()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onPressed,
                              child: requestModel.status == "New Request"
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
  static void showSearchSheet(BuildContext context,
      ClientController clientController, RequestController requestController) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Important for height
      builder: (BuildContext context) {
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
      BuildContext context, RequestController requestController) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final dark = BHelperFunctions.isDarkMode(context);
        return AlertDialog(
          backgroundColor: dark ? BColors.black : BColors.light,
          contentPadding: EdgeInsets.zero, // Remove default padding
          titlePadding: EdgeInsets.zero,
          content: SizedBox(
            width: 400,
            height: 345, // Give it a fixed size
            child: SingleChildScrollView(
              // To handle potential overflow if content is too tall
              child: Column(
                children: [
                  SignaturePadWidget(
                    onSave: (Uint8List? signatureBytes) {
                      requestController.setSignature(signatureBytes);
                      Navigator.of(dialogContext).pop(); // Close the dialog
                      if (signatureBytes != null) {
                        BHelperFunctions.showSnackBar("Signature saved!");
                      } else {
                        BHelperFunctions.showSnackBar(
                            "Signature pad was empty.");
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showRequestForReleasingDialog(BuildContext context,
      RequestModel requestModel, VoidCallback onPressed, bool status) {
    final dark = BHelperFunctions.isDarkMode(context);
    showModalBottomSheet<void>(
      backgroundColor: dark ? BColors.black : BColors.light,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: RequestModal(
            requestModel: requestModel,
            onPressed: onPressed,
            status: status,
          ),
        );
      },
    );
  }
}
