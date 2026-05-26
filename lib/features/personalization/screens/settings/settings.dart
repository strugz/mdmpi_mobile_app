import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:mdmpi_mobile_app/common/widgets/list_tiles/user_profile_tile.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/profile/profile.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/data_test/local_storage_data_viewer.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/contact_directory_screen.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_hard_reset_section.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../logistics/controllers/standard_delivery_controller.dart';
import '../../controller/realtime_location_saver_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<StandardDeliveryController>();
    final realtimeLocationSaverController =
        Get.find<RealtimeLocationSaverController>();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ///  -- Header
            BPrimaryHeaderContainer(
              child: Column(
                children: [
                  /// AppBar
                  BAppBar(
                    title: Text(
                      'Account',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .apply(color: Colors.white),
                    ),
                  ),

                  /// User Profile Card
                  BUserProfileTile(
                      onPressed: () => Get.to(() => ProfileScreen())),
                  const SizedBox(height: BSizes.spaceBtwSections),
                ],
              ),
            ),

            ///  -- Body
            Padding(
              padding: EdgeInsets.all(BSizes.defaultSpace),
              child: Column(
                children: [
                  /// -- Account Settings
                  BSectionHeading(
                      title: 'Data Settings', showActionButton: false),
                  const SizedBox(height: BSizes.spaceBtwItems),
                  BSettingsMenuTile(
                    icon: Iconsax.document_upload,
                    title: 'Upload Data',
                    subTitle: 'Upload Data to your Cloud Server',
                    onTap: () {
                      // Show a confirmation dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Data Upload'),
                            content: const Text(
                                'Are you sure you want to upload data to the cloud server?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                              ),
                              TextButton(
                                child: const Text('Upload'),
                                onPressed: () {
                                  requestController.dataManager
                                      .uploadModifiedRequest();
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SettingsHardResetSection(),
                  Obx(
                    () => BSettingsMenuTile(
                      icon: Iconsax.location,
                      title: 'Realtime Location Saver',
                      subTitle:
                          'Save latest location locally; delivery tracking handles live sharing',
                      trailing: Switch(
                        value: realtimeLocationSaverController.isEnabled.value,
                        onChanged: realtimeLocationSaverController.toggle,
                      ),
                      onTap: () {
                        realtimeLocationSaverController.toggle(
                          !realtimeLocationSaverController.isEnabled.value,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: BSizes.spaceBtwItems),
                  BSettingsMenuTile(
                    icon: Iconsax.call,
                    title: 'Contact Directory',
                    subTitle: 'View and manage local contacts',
                    onTap: () => Get.to(() => ContactDirectoryScreen()),
                  ),

                  if (kDebugMode) ...[
                    const BSectionHeading(
                        title: 'Developer Tools', showActionButton: false),
                    const SizedBox(height: BSizes.spaceBtwItems),
                    BSettingsMenuTile(
                      icon: Iconsax.data,
                      title: 'Local Storage Viewer',
                      subTitle: 'View and manage local database tables',
                      onTap: () {
                        Get.to(() => const LocalStorageDataViewer());
                      },
                    ),
                    BSettingsMenuTile(
                      icon: Iconsax.pen_add,
                      title: 'Signature Outbox',
                      subTitle:
                          'Review pending or failed receiver signature uploads',
                      onTap: () => Get.toNamed(BRoutes.signatureOutbox),
                    ),
                    BSettingsMenuTile(
                      icon: Iconsax.gallery,
                      title: 'Image Outbox',
                      subTitle: 'Review pending or failed proof image uploads',
                      onTap: () => Get.toNamed(BRoutes.imageOutbox),
                    ),
                  ],

                  /// --  Logout Button
                  const SizedBox(height: BSizes.spaceBtwSections),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: () async {
                          await AuthenticationRepository.instance.logout();
                        },
                        child: const Text('Logout')),
                  ),
                  const SizedBox(
                    height: BSizes.spaceBtwSections * 2.5,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
