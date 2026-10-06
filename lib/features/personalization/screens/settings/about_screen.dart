import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/whats_new.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The running build: name, version, build number.
class AppBuildInfo {
  const AppBuildInfo(
      {required this.appName, required this.version, required this.build});

  final String appName;
  final String version;
  final String build;

  /// "1.1.110 (110)", or just the version when the build number repeats it.
  String get label =>
      build.isEmpty || build == version ? version : '$version ($build)';
}

typedef BuildInfoLoader = Future<AppBuildInfo> Function();

/// Backs Settings → About (Collection TODO item 15).
class AboutController extends GetxController {
  AboutController({BuildInfoLoader? load}) : _load = load ?? _fromPackageInfo;

  final BuildInfoLoader _load;

  final info = Rxn<AppBuildInfo>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _read();
  }

  Future<void> _read() async {
    try {
      info.value = await _load();
    } catch (e) {
      logDebug('AboutController: package info unavailable: $e');
      info.value = const AppBuildInfo(appName: 'MDMPI App', version: '', build: '');
    } finally {
      isLoading.value = false;
    }
  }

  WhatsNewGroup? get whatsNew =>
      BWhatsNew.forVersion(info.value?.version ?? '');

  static Future<AppBuildInfo> _fromPackageInfo() async {
    final p = await PackageInfo.fromPlatform();
    return AppBuildInfo(
        appName: p.appName, version: p.version, build: p.buildNumber);
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AboutController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const BAppBar(title: Text('About'), showBackArrow: true),
      body: Obx(() {
        final info = controller.info.value;
        final group = controller.whatsNew;
        return ListView(
          padding: EdgeInsets.fromLTRB(
              BSizes.defaultSpace,
              BSizes.defaultSpace,
              BSizes.defaultSpace,
              BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
          children: [
            Card(
              child: ListTile(
                key: const ValueKey('about-version'),
                leading: const CircleAvatar(child: Icon(Iconsax.mobile)),
                title: Text(info?.appName.isNotEmpty == true
                    ? info!.appName
                    : 'MDMPI App'),
                subtitle: Text(controller.isLoading.value
                    ? 'Reading version…'
                    : info == null || info.version.isEmpty
                        ? 'Version unavailable'
                        : 'Version ${info.label}'),
                trailing: info == null || info.version.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('about-copy'),
                        tooltip: 'Copy version',
                        icon: const Icon(Iconsax.copy, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: info.label));
                          BLoaders.customToast(
                              message: 'Version ${info.label} copied');
                        },
                      ),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
            if (group != null) ...[
              BSectionHeading(
                  title: "What's new in ${group.version}",
                  showActionButton: false),
              if (info != null &&
                  info.version.isNotEmpty &&
                  info.version != group.version)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'You are on ${info.version}; this is the newest list.',
                    key: const ValueKey('about-newer-note'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: BSizes.sm),
              for (final item in group.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: BSizes.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(Iconsax.tick_circle, size: 18),
                      ),
                      const SizedBox(width: BSizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.area == null
                                  ? item.title
                                  : '${item.area} · ${item.title}',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(item.detail, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ] else
              Text('No release notes for this build.',
                  style: theme.textTheme.bodySmall),
          ],
        );
      }),
    );
  }
}
