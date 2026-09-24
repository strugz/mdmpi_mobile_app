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
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_department_theme.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_hard_reset_section.dart';

import 'package:mdmpi_mobile_app/features/personalization/controller/realtime_location_saver_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDepartmentTheme(
      child: Scaffold(
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
                    /// Department-specific items; the shared ones (Contact
                    /// Directory, Local Storage Viewer) appear for everyone.
                    _DepartmentAware(
                      logistics: const _LogisticsSettings(),
                      collection: const _CollectionSettings(),
                    ),

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
      ),
    );
  }
}

/// Shows [collection] to Collection users and [logistics] to everyone else,
/// matching [SettingsDepartmentTheme] and the bottom navigation.
class _DepartmentAware extends StatelessWidget {
  const _DepartmentAware({required this.logistics, required this.collection});

  final Widget logistics;
  final Widget collection;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserController>()) return logistics;
    final user = Get.find<UserController>().user;
    return Obx(
      () => SettingsDepartmentTheme.isCollection(user.value.department)
          ? collection
          : logistics,
    );
  }
}

/// Logistics: request uploads and hard resets, the location saver the
/// Air / Sea forms read, and the proof signature/image outboxes.
class _LogisticsSettings extends StatelessWidget {
  const _LogisticsSettings();

  @override
  Widget build(BuildContext context) {
    final realtimeLocationSaverController =
        Get.find<RealtimeLocationSaverController>();
    return Column(
      children: [
        BSectionHeading(title: 'Data Settings', showActionButton: false),
        const SizedBox(height: BSizes.spaceBtwItems),
        BSettingsMenuTile(
          icon: Iconsax.document_upload,
          title: 'Upload Data',
          subTitle: 'Upload Data to your Cloud Server',
          onTap: () => Get.toNamed(BRoutes.uploadData),
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
        const _ContactDirectoryTile(),
        const BSectionHeading(
            title: 'Developer Tools', showActionButton: false),
        const SizedBox(height: BSizes.spaceBtwItems),
        const _LocalStorageViewerTile(),
        BSettingsMenuTile(
          icon: Iconsax.pen_add,
          title: 'Signature Outbox',
          subTitle: 'Review pending or failed receiver signature uploads',
          onTap: () => Get.toNamed(BRoutes.signatureOutbox),
        ),
        BSettingsMenuTile(
          icon: Iconsax.gallery,
          title: 'Image Outbox',
          subTitle: 'Review pending or failed proof image uploads',
          onTap: () => Get.toNamed(BRoutes.imageOutbox),
        ),
      ],
    );
  }
}

/// Collection: its own upload queue in place of the Logistics request upload.
/// The hard resets, location saver and proof outboxes only hold Logistics
/// data, so they are left out.
class _CollectionSettings extends StatelessWidget {
  const _CollectionSettings();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BSectionHeading(title: 'Data Settings', showActionButton: false),
        const SizedBox(height: BSizes.spaceBtwItems),
        BSettingsMenuTile(
          icon: Iconsax.document_upload,
          title: 'Upload Data',
          subTitle: 'Review and upload your queued collections',
          onTap: () => Get.toNamed(BRoutes.collectionUploadOutbox),
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
        const _ContactDirectoryTile(),
        const BSectionHeading(
            title: 'Developer Tools', showActionButton: false),
        const SizedBox(height: BSizes.spaceBtwItems),
        const _LocalStorageViewerTile(),
      ],
    );
  }
}

class _ContactDirectoryTile extends StatelessWidget {
  const _ContactDirectoryTile();

  @override
  Widget build(BuildContext context) {
    return BSettingsMenuTile(
      icon: Iconsax.call,
      title: 'Contact Directory',
      subTitle: 'View and manage local contacts',
      onTap: () => Get.to(() => ContactDirectoryScreen()),
    );
  }
}

class _LocalStorageViewerTile extends StatelessWidget {
  const _LocalStorageViewerTile();

  @override
  Widget build(BuildContext context) {
    return BSettingsMenuTile(
      icon: Iconsax.data,
      title: 'Local Storage Viewer',
      subTitle: 'View and manage local database tables',
      onTap: () => Get.to(() => const LocalStorageDataViewer()),
    );
  }
}
