import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/app_build_info.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/whats_new.dart';

export 'package:mdmpi_mobile_app/base/utils/app_build_info.dart'
    show AppBuildInfo, BuildInfoLoader;

/// Backs Settings → About (Collection TODO item 15).
class AboutController extends GetxController {
  AboutController({BuildInfoLoader? load})
      : _load = load ?? BAppBuildInfo.current,
        // Already read during the splash: no "Reading version…" frame.
        _seed = load == null ? BAppBuildInfo.cached : null;

  final BuildInfoLoader _load;
  final AppBuildInfo? _seed;

  final info = Rxn<AppBuildInfo>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (_seed != null) {
      info.value = _seed;
      isLoading.value = false;
      return;
    }
    _read();
  }

  Future<void> _read() async {
    try {
      info.value = await _load();
    } catch (e) {
      logDebug('AboutController: package info unavailable: $e');
      info.value = AppBuildInfo.unknown;
    } finally {
      isLoading.value = false;
    }
  }

  WhatsNewGroup? get whatsNew =>
      BWhatsNew.forVersion(info.value?.version ?? '');
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
            _VersionHeader(
              appName: info?.appName.isNotEmpty == true
                  ? info!.appName
                  : 'MDMPI App',
              version: controller.isLoading.value
                  ? 'Reading version…'
                  : info == null || info.version.isEmpty
                      ? 'Version unavailable'
                      : 'Version ${info.label}',
              copyLabel: info == null || info.version.isEmpty
                  ? null
                  : info.label,
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
            if (group != null) ...[
              Text("What's new in ${group.version}",
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (info != null &&
                  info.version.isNotEmpty &&
                  info.version != group.version)
                Padding(
                  padding: const EdgeInsets.only(top: BSizes.xs),
                  child: Text(
                    'You are on ${info.version}; this is the newest list.',
                    key: const ValueKey('about-newer-note'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: BSizes.spaceBtwItems),
              _WhatsNewList(items: group.items),
            ] else
              Text('No release notes for this build.',
                  style: theme.textTheme.bodySmall),
          ],
        );
      }),
    );
  }
}

/// The app and its version on a soft tint of the primary colour, set apart
/// from the list without a second heavy band under the app bar; the version
/// is the first thing read (and copied) when someone asks for it.
class _VersionHeader extends StatelessWidget {
  const _VersionHeader({
    required this.appName,
    required this.version,
    required this.copyLabel,
  });

  final String appName;
  final String version;

  /// The label copied by the copy button; null hides it.
  final String? copyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      key: const ValueKey('about-version'),
      padding: const EdgeInsets.fromLTRB(
          BSizes.md, BSizes.md, BSizes.sm, BSizes.md),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Iconsax.mobile, color: cs.onPrimary),
          ),
          const SizedBox(width: BSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(version,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (copyLabel case final label?)
            IconButton(
              key: const ValueKey('about-copy'),
              tooltip: 'Copy version',
              color: cs.primary,
              icon: const Icon(Iconsax.copy, size: 20),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: label));
                BLoaders.customToast(message: 'Version $label copied');
              },
            ),
        ],
      ),
    );
  }
}

/// The release notes, grouped by area so the area is said once, each change
/// a card with its own icon so the list can be scanned before it is read.
///
/// The cards ease in one after another the first time the screen opens: a
/// screen seen once per release can afford the moment, and it never blocks a
/// tap. Off when the system asks for reduced motion.
class _WhatsNewList extends StatefulWidget {
  const _WhatsNewList({required this.items});

  final List<WhatsNewItem> items;

  @override
  State<_WhatsNewList> createState() => _WhatsNewListState();
}

class _WhatsNewListState extends State<_WhatsNewList>
    with SingleTickerProviderStateMixin {
  static const _each = Duration(milliseconds: 260);
  static const _stagger = Duration(milliseconds: 40);

  /// Cards after this one start with it, so a long list is not kept waiting.
  static const _maxStaggered = 8;

  static const _easeOut = Cubic(0.23, 1, 0.32, 1);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: _each + _stagger * _maxStaggered,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _curveFor(int index) {
    final total = _entrance.duration!.inMicroseconds;
    final start =
        (_stagger * index.clamp(0, _maxStaggered)).inMicroseconds / total;
    final end = (start + _each.inMicroseconds / total).clamp(0.0, 1.0);
    return CurvedAnimation(
        parent: _entrance, curve: Interval(start, end, curve: _easeOut));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Areas in the order they first appear; items without one go last.
    final byArea = <String?, List<WhatsNewItem>>{};
    for (final item in widget.items) {
      byArea.putIfAbsent(item.area, () => []).add(item);
    }
    final areas = [
      ...byArea.keys.whereType<String>(),
      if (byArea.containsKey(null)) null,
    ];

    var index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final area in areas) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: BSizes.sm),
            child: Row(
              children: [
                Text((area ?? 'Everyone').toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1)),
                const SizedBox(width: BSizes.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                      '${byArea[area]!.length} '
                      '${byArea[area]!.length == 1 ? 'update' : 'updates'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          for (final item in byArea[area]!)
            _Entrance(
              animation: _curveFor(index++),
              child: _WhatsNewCard(item: item),
            ),
          const SizedBox(height: BSizes.spaceBtwItems),
        ],
      ],
    );
  }
}

/// Fades a card in while it rises 8 px into place.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, 8 * (1 - animation.value)),
            child: child,
          ),
          child: child,
        ),
      );
}

class _WhatsNewCard extends StatelessWidget {
  const _WhatsNewCard({required this.item});

  final WhatsNewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: BSizes.sm),
      child: Container(
        padding: const EdgeInsets.all(BSizes.md - 2),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 20, color: cs.primary),
            ),
            const SizedBox(width: BSizes.md - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700, height: 1.25)),
                  const SizedBox(height: BSizes.xs),
                  Text(item.detail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
