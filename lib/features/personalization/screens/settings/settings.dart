import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/app_build_info.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:mdmpi_mobile_app/common/widgets/list_tiles/user_profile_tile.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/profile/profile.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/unfinished_requests_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/data_test/local_storage_data_viewer.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/contact_directory_screen.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_department_theme.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_hard_reset_section.dart';

import 'package:mdmpi_mobile_app/features/personalization/controller/realtime_location_saver_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/visit_location.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_settings_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/settings/collection_theme_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/settings/default_area_sheet.dart';

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
        BSettingsMenuTile(
          icon: Iconsax.task_square,
          title: 'Unfinished requests',
          subTitle: 'Requests not yet delivered, taken out or received',
          onTap: () => Get.toNamed(BRoutes.unfinishedRequests),
        ),
        if (GetPlatform.isAndroid) const _UnfinishedReminderTile(),
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
        const _AboutTile(),
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
        if (GetPlatform.isAndroid) const _SmsOutboxTile(),
        BSettingsMenuTile(
          icon: Iconsax.document_download,
          title: 'Reports',
          subTitle: 'Activity, collectors summary, reconciliation; save or share as CSV',
          onTap: () => Get.toNamed(BRoutes.collectionReports),
        ),
        const SizedBox(height: BSizes.spaceBtwItems),
        const BSectionHeading(title: 'My Team', showActionButton: false),
        const SizedBox(height: BSizes.spaceBtwItems),
        const _MyHeadTile(),
        const _ContactDirectoryTile(),
        const SizedBox(height: BSizes.spaceBtwItems),
        const BSectionHeading(title: 'Preferences', showActionButton: false),
        const SizedBox(height: BSizes.spaceBtwItems),
        BSettingsMenuTile(
          key: const ValueKey('settings-theme-tile'),
          icon: Iconsax.brush_2,
          title: 'Theme',
          subTitle: CollectionThemeScreen.summary(),
          onTap: () => Get.toNamed(BRoutes.collectionTheme),
        ),
        const _DefaultAreaTile(),
        const _CollectedScopeTile(),
        if (GetPlatform.isAndroid) const _FollowUpRemindersTile(),
        if (GetPlatform.isAndroid) const _VisitLocationTile(),
        BSettingsMenuTile(
          icon: Iconsax.folder_2,
          title: 'Storage',
          subTitle: 'Local data size, cached pictures, re-download the bucket',
          onTap: () => Get.toNamed(BRoutes.collectionStorage),
        ),
        const _AboutTile(),
        const BSectionHeading(
            title: 'Developer Tools', showActionButton: false),
        const SizedBox(height: BSizes.spaceBtwItems),
        const _LocalStorageViewerTile(),
      ],
    );
  }
}

/// Settings → About, for every department. The subtitle carries the version
/// itself, so it can be read out over chat without opening the screen.
/// The build is read during the splash, so the subtitle is right on the
/// first frame; Settings is opened too often for it to visibly change text.
class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBuildInfo>(
      future: BAppBuildInfo.current(),
      initialData: BAppBuildInfo.cached,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return BSettingsMenuTile(
          key: const ValueKey('settings-about-tile'),
          icon: Iconsax.info_circle,
          title: 'About',
          subTitle: info != null && info.hasVersion
              ? 'Version ${info.label} · what\'s new'
              : 'App version and what\'s new',
          onTap: () => Get.toNamed(BRoutes.about),
        );
      },
    );
  }
}

/// Collection TODO item 15: the territory the bucket opens on.
class _DefaultAreaTile extends StatelessWidget {
  const _DefaultAreaTile();

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<CollectionSettingsController>();
    return Obx(() => BSettingsMenuTile(
          icon: Iconsax.location,
          title: 'Default area',
          subTitle: settings.defaultArea.value.isEmpty
              ? 'All areas · the bucket opens unfiltered'
              : 'The bucket opens on ${settings.defaultAreaLabel}',
          onTap: () async {
            final code = await DefaultAreaSheet.show(context,
                selected: settings.defaultArea.value);
            if (code == null) return;
            await settings.setDefaultArea(code);
          },
        ));
  }
}

/// What Collected this Month on the home screen counts: this collector's
/// own work, or every collector's.
class _CollectedScopeTile extends StatelessWidget {
  const _CollectedScopeTile();

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<CollectionSettingsController>();
    return Obx(() {
      final all = settings.collectedAllCollectors.value;
      return BSettingsMenuTile(
        icon: Iconsax.money,
        title: 'Collected this Month',
        subTitle: all
            ? 'All collectors · needs internet, counts uploaded work'
            : 'Me only · what I collected',
        trailing: Switch(
          key: const ValueKey('settings-collected-all'),
          value: all,
          onChanged: settings.setCollectedAllCollectors,
        ),
        onTap: () => settings.setCollectedAllCollectors(!all),
      );
    });
  }
}

/// The 8 AM phone reminder of this user's unfinished Logistics requests
/// (docs/application/UNFINISHED_REQUESTS_REMINDER_PLAN.md).
class _UnfinishedReminderTile extends StatelessWidget {
  const _UnfinishedReminderTile();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UnfinishedRequestsController>();
    return Obx(() {
      final on = controller.reminderOn.value;
      return BSettingsMenuTile(
        icon: Iconsax.notification,
        title: 'Unfinished requests reminder',
        subTitle: on
            ? 'At 8 AM, and the first time you open the app each day'
            : 'Off · the list is still here in Settings',
        trailing: Switch(
          key: const ValueKey('settings-unfinished-reminder'),
          value: on,
          onChanged: controller.setReminderOn,
        ),
        onTap: () => controller.setReminderOn(!on),
      );
    });
  }
}

/// The 8 AM phone reminder for a reconciliation follow up that is due
/// (docs/application/COLLECTION_RECON_FOLLOWUP_REMINDERS_PLAN.md, Phase 3).
class _FollowUpRemindersTile extends StatelessWidget {
  const _FollowUpRemindersTile();

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<CollectionSettingsController>();
    return Obx(() {
      final on = settings.followUpReminders.value;
      return BSettingsMenuTile(
        icon: Iconsax.notification,
        title: 'Follow-up reminders',
        subTitle: on
            ? 'A notification at 8 AM on a reconciliation follow-up date'
            : 'Off · follow ups still show on the calendar',
        trailing: Switch(
          key: const ValueKey('settings-followup-reminders'),
          value: on,
          onChanged: settings.setFollowUpReminders,
        ),
        onTap: () => settings.setFollowUpReminders(!on),
      );
    });
  }
}

/// Tells the collector, truthfully, that the phone's location is recorded on
/// every engagement they save, and whether it is working right now. A tap
/// asks for the permission, or opens the phone's settings where only they
/// can allow it.
class _VisitLocationTile extends StatefulWidget {
  const _VisitLocationTile();

  @override
  State<_VisitLocationTile> createState() => _VisitLocationTileState();
}

class _VisitLocationTileState extends State<_VisitLocationTile> {
  final settings = Get.find<CollectionSettingsController>();

  @override
  void initState() {
    super.initState();
    settings.refreshVisitLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = settings.visitLocation.value;
      final subTitle = switch (state) {
        VisitLocationState.on =>
          'On · your location is recorded each time you save an engagement',
        VisitLocationState.needsPermission =>
          'Needs permission · tap to allow; your location is recorded on '
              'each saved engagement',
        VisitLocationState.blocked =>
          'Blocked · tap to allow it in the phone settings',
        VisitLocationState.serviceOff =>
          "Location is off · tap to turn on the phone's location",
        VisitLocationState.unsupported => 'Not available on this device',
        null => 'Checking…',
      };
      return BSettingsMenuTile(
        key: const ValueKey('settings-visit-location'),
        icon: Iconsax.location_tick,
        title: 'Visit location',
        subTitle: subTitle,
        trailing: Icon(
          state == VisitLocationState.on
              ? Iconsax.tick_circle
              : Iconsax.warning_2,
          color: state == VisitLocationState.on
              ? BCollectionColors.success
              : BCollectionColors.warning,
        ),
        onTap: state == VisitLocationState.on
            ? null
            : settings.turnOnVisitLocation,
      );
    });
  }
}

/// Collection TODO item 13: who receives the Done Engagement notices.
/// Settings → SMS Outbox, with how many messages are not sent yet.
class _SmsOutboxTile extends StatelessWidget {
  const _SmsOutboxTile();

  static const _idle = "Today's Collection SMS, sent in the background";

  @override
  Widget build(BuildContext context) {
    void open() => Get.toNamed(BRoutes.collectionSmsOutbox);
    if (!Get.isRegistered<CollectionSmsService>()) {
      return BSettingsMenuTile(
          icon: Iconsax.sms, title: 'SMS Outbox', subTitle: _idle, onTap: open);
    }
    final count = CollectionSmsService.instance.needsAttention;
    return Obx(() => BSettingsMenuTile(
          key: const ValueKey('settings-sms-outbox'),
          icon: Iconsax.sms,
          title: 'SMS Outbox',
          subTitle: count.value == 0
              ? _idle
              : '${count.value} SMS not sent yet · tap to see',
          onTap: open,
        ));
  }
}

class _MyHeadTile extends StatelessWidget {
  const _MyHeadTile();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserController>()) {
      return BSettingsMenuTile(
        icon: Iconsax.user_tick,
        title: 'My Head',
        subTitle: 'Choose who receives your Done Engagement notices',
        onTap: () => Get.toNamed(BRoutes.myHead),
      );
    }
    final user = Get.find<UserController>().user;
    return Obx(() {
      final name = user.value.headName.trim();
      final key = user.value.headKey.trim();
      return BSettingsMenuTile(
        icon: Iconsax.user_tick,
        title: 'My Head',
        subTitle: key.isEmpty
            ? 'Not set · choose who receives your Done Engagement notices'
            : (name.isEmpty ? key : '$name ($key)'),
        onTap: () => Get.toNamed(BRoutes.myHead),
      );
    });
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
