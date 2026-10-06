import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/upload_data_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_date_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/upload_candidate.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_department_theme.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/upload_candidate_tile.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/upload_compare_sheet.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/upload_data_dialog.dart';

// Filter chips change colour on tap, tens of times at most: short and eased
// out so the press reads as instant.
const _chipChange = Duration(milliseconds: 180);

/// Settings > Upload Data: the phone's saved requests compared with the
/// server, filtered by delivery date, grouped, with a tick on each one that
/// can be uploaded.
///
/// Wears the department theme: the Logistics blue header (Collection's navy
/// for Collection users) over a tinted canvas with white cards.
class UploadDataPage extends StatefulWidget {
  const UploadDataPage({super.key});

  @override
  State<UploadDataPage> createState() => _UploadDataPageState();
}

class _UploadDataPageState extends State<UploadDataPage> {
  late final UploadDataController controller = Get.find<UploadDataController>();

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDepartmentTheme(
      child: _UploadDataView(controller: controller),
    );
  }
}

class _UploadDataView extends StatelessWidget {
  const _UploadDataView({required this.controller});

  final UploadDataController controller;

  Future<void> _upload(BuildContext context) async {
    final count = controller.selected.length;
    if (count == 0) return;
    final plural = count == 1 ? 'request' : 'requests';
    await showUploadDataDialog(
      context,
      upload: controller.uploadSelected,
      confirmTitle: 'Upload $count $plural?',
      confirmMessage:
          'Only the ticked $plural will be sent. Requests with the same '
          'status as the server are not sent.',
    );
  }

  Future<void> _takeServerCopies() async {
    final result = await controller.takeServerCopies();
    if (result.isFailure) {
      BLoaders.errorSnackBar(title: 'Not updated', message: result.error);
      return;
    }
    final n = result.value;
    BLoaders.successSnackBar(
      title: 'Updated from server',
      message: n == 1
          ? "This phone now has the server's copy of 1 request."
          : "This phone now has the server's copy of $n requests.",
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final current = controller.dateRange.value;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: current == null
          ? DateTimeRange(
              start: now.subtract(const Duration(days: 6)), end: now)
          : DateTimeRange(start: current.start, end: current.end),
      helpText: 'Delivery dates',
    );
    if (picked == null) return;
    controller.setDateFilter(UploadDateFilter.range,
        range: UploadDateRange(picked.start, picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final canvas = SettingsStatusColors.of(context).canvas;
    return Scaffold(
      backgroundColor: canvas,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(controller: controller)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedBar(
              color: canvas,
              child: _DateFilterBar(
                controller: controller,
                onPickRange: () => _pickRange(context),
              ),
            ),
          ),
          Obx(() => _content(context)),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final ready = !controller.isLoading.value &&
            !controller.isOffline.value &&
            controller.loadError.value == null &&
            controller.candidates.isNotEmpty;
        if (!ready) return const SizedBox.shrink();
        return _UploadBar(
          count: controller.selected.length,
          onUpload: () => _upload(context),
        );
      }),
    );
  }

  Widget _content(BuildContext context) {
    if (controller.isLoading.value) {
      return const _FillMessage(
        icon: null,
        title: 'Comparing with the server…',
        message: 'Checking which saved requests the server is missing.',
      );
    }
    if (controller.isOffline.value) {
      return _FillMessage(
        icon: Icons.wifi_off_rounded,
        title: "You're offline",
        message: 'Connect to the internet to check what needs uploading.',
        actionLabel: 'Retry',
        onAction: controller.load,
      );
    }
    final error = controller.loadError.value;
    if (error != null) {
      return _FillMessage(
        icon: Iconsax.warning_2,
        title: 'Could not compare',
        message: error,
        actionLabel: 'Retry',
        onAction: controller.load,
      );
    }
    if (controller.candidates.isEmpty) {
      return const _FillMessage(
        icon: Iconsax.tick_circle,
        title: 'Nothing to upload',
        message: 'This phone has no saved requests past New Request.',
      );
    }
    if (controller.visible.isEmpty) {
      return _FillMessage(
        icon: Iconsax.calendar_1,
        title: 'No requests in this range',
        message: 'No saved request is due for delivery on these dates.',
        actionLabel: 'Show all dates',
        onAction: () => controller.setDateFilter(UploadDateFilter.all),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        for (final group in _groupOrder)
          if (controller.countOf(group) > 0) ...[
            SliverToBoxAdapter(
              child: _GroupHeader(
                group: group,
                count: controller.countOf(group),
                action: switch (group) {
                  UploadCandidateGroup.ready => TextButton(
                      onPressed: controller.toggleAllReady,
                      child: Text(
                          controller.allReadySelected ? 'Clear' : 'Select all'),
                    ),
                  UploadCandidateGroup.serverAhead => TextButton(
                      onPressed: _takeServerCopies,
                      child: const Text('Take all server copies'),
                    ),
                  _ => null,
                },
              ),
            ),
            _GroupCard(controller: controller, group: group),
          ],
        const SliverToBoxAdapter(
            child: SizedBox(height: BSizes.spaceBtwSections)),
      ],
    );
  }
}

const _groupOrder = [
  UploadCandidateGroup.ready,
  UploadCandidateGroup.notOnServer,
  UploadCandidateGroup.sameStatus,
  UploadCandidateGroup.serverAhead,
];

// ─── Header ──────────────────────────────────────────────────────────────────

/// The department's curved header (Logistics blue, Collection navy) with the
/// white app bar and a frosted panel of counts.
class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final UploadDataController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The bar sits on the header colour, so it is transparent and white.
    final onHeader = theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
    );

    return BPrimaryHeaderContainer(
      child: Column(
        children: [
          Theme(
            data: onHeader,
            child: BAppBar(
              showBackArrow: true,
              title: Text(
                'Upload Data',
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              actions: [
                Obx(() => IconButton(
                      onPressed:
                          controller.isLoading.value ? null : controller.load,
                      tooltip: 'Compare again',
                      icon: const Icon(Iconsax.refresh, color: Colors.white),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.xs,
                BSizes.defaultSpace, BSizes.spaceBtwSections * 1.6),
            child: Obx(() => _SummaryPanel(
                  loading: controller.isLoading.value,
                  ready: controller.countOf(UploadCandidateGroup.ready),
                  same: controller.countOf(UploadCandidateGroup.sameStatus),
                  ahead: controller.countOf(UploadCandidateGroup.serverAhead),
                  missing: controller.countOf(UploadCandidateGroup.notOnServer),
                  caption: _caption(controller),
                )),
          ),
        ],
      ),
    );
  }

  static String _caption(UploadDataController c) {
    final total = c.visible.length;
    final filter = c.dateFilter.value;
    final range = c.dateRange.value;
    final when = switch (filter) {
      UploadDateFilter.all => 'all delivery dates',
      UploadDateFilter.range when range != null => _rangeLabel(range),
      _ => filter.label.toLowerCase(),
    };
    return '$total saved ${total == 1 ? 'request' : 'requests'} · $when';
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.loading,
    required this.ready,
    required this.same,
    required this.ahead,
    required this.missing,
    required this.caption,
  });

  final bool loading;
  final int ready, same, ahead, missing;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stats = <(String, int)>[
      ('Ready', ready),
      ('Same status', same),
      ('Server ahead', ahead),
      if (missing > 0) ('Not on server', missing),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loading ? 'Comparing with the server…' : caption,
            style: text.labelMedium
                ?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    VerticalDivider(
                      width: 20,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  Expanded(
                    child: _Stat(
                      label: stats[i].$1,
                      value: loading ? null : stats[i].$2,
                      emphasised: i == 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.label, required this.value, this.emphasised = false});

  final String label;

  /// Null while loading: shows a dash.
  final int? value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shown = value?.toString() ?? '–';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The number rises in when it changes (a new date filter, a reload),
        // so the eye catches which count moved.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.25), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: Text(
            shown,
            key: ValueKey(shown),
            style: text.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: emphasised ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall
              ?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
        ),
      ],
    );
  }
}

// ─── Date filter ─────────────────────────────────────────────────────────────

String _rangeLabel(UploadDateRange r) {
  final f = DateFormat('MMM d');
  return r.start == r.end
      ? f.format(r.start)
      : '${f.format(r.start)} – ${f.format(r.end)}';
}

class _PinnedBar extends SliverPersistentHeaderDelegate {
  _PinnedBar({required this.child, required this.color});

  final Widget child;
  final Color color;

  static const double _height = 60;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // A hairline appears once rows scroll under the bar.
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: overlapsContent || shrinkOffset > 0
            ? Border(
                bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.06)))
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_PinnedBar old) =>
      old.child != child || old.color != color;
}

class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({required this.controller, required this.onPickRange});

  final UploadDataController controller;
  final VoidCallback onPickRange;

  static const _quick = [
    UploadDateFilter.all,
    UploadDateFilter.today,
    UploadDateFilter.tomorrow,
    UploadDateFilter.yesterday,
    UploadDateFilter.last7Days,
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.dateFilter.value;
      final range = controller.dateRange.value;
      return ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: BSizes.defaultSpace, vertical: 12),
        children: [
          for (final filter in _quick) ...[
            _FilterChip(
              label: filter.label,
              selected: active == filter,
              onTap: () => controller.setDateFilter(filter),
            ),
            const SizedBox(width: 8),
          ],
          _FilterChip(
            label: active == UploadDateFilter.range && range != null
                ? _rangeLabel(range)
                : UploadDateFilter.range.label,
            icon: Iconsax.calendar_1,
            selected: active == UploadDateFilter.range,
            onTap: onPickRange,
            onClear: active == UploadDateFilter.range
                ? () => controller.setDateFilter(UploadDateFilter.all)
                : null,
          ),
        ],
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: BPressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _chipChange,
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              left: icon == null ? 14 : 10, right: onClear == null ? 14 : 6),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.08),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.close_rounded, size: 16, color: fg),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Groups ──────────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, required this.count, this.action});

  final UploadCandidateGroup group;
  final int count;
  final Widget? action;

  String get _hint => switch (group) {
        UploadCandidateGroup.ready =>
          'The phone is further along than the server.',
        UploadCandidateGroup.notOnServer =>
          'The server has no request with this ID. Tick only if you are sure.',
        UploadCandidateGroup.sameStatus =>
          'The server already has this status. Not sent.',
        UploadCandidateGroup.serverAhead =>
          'The server is further along or finished. Not sent.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, BSizes.md, BSizes.sm, BSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Shrinks before the action button does on narrow phones.
                    Flexible(
                      child: Text(group.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('$count',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_hint,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// One white card per group, built lazily: each row draws its own slice of
/// the card (rounded top on the first, rounded bottom on the last), so a
/// group of 130 rows still only builds what is on screen.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.controller, required this.group});

  final UploadDataController controller;
  final UploadCandidateGroup group;

  void _openCompare(BuildContext context, UploadCandidate candidate) {
    showUploadCompareSheet(
      context,
      candidate: candidate,
      onTakeServerCopy: () async {
        final result = await controller.takeServerCopy(candidate);
        if (result.isFailure) return result.error;
        BLoaders.successSnackBar(
          title: 'Updated from server',
          message: "This phone now has the server's copy of "
              'request ${candidate.id}.',
        );
        return null;
      },
    );
  }

  static const _radius = Radius.circular(18);

  @override
  Widget build(BuildContext context) {
    final rows = controller.inGroup(group);
    final scheme = Theme.of(context).colorScheme;
    final edge = scheme.onSurface.withValues(alpha: 0.06);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
      sliver: SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final first = i == 0;
          final last = i == rows.length - 1;
          final candidate = rows[i];
          return DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.vertical(
                top: first ? _radius : Radius.zero,
                bottom: last ? _radius : Radius.zero,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: first ? _radius : Radius.zero,
                    bottom: last ? _radius : Radius.zero,
                  ),
                  child: Obx(() => UploadCandidateTile(
                        candidate: candidate,
                        selected: controller.isSelected(candidate.id),
                        onToggle: () => controller.toggle(candidate),
                        onCompare: () => _openCompare(context, candidate),
                      )),
                ),
                if (!last)
                  Divider(
                      height: 1,
                      thickness: 1,
                      indent: 60,
                      endIndent: 16,
                      color: edge),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Bottom bar and messages ─────────────────────────────────────────────────

/// Bottom bar: pads for the navigation bar once, here at the outermost
/// bottom widget ([Scaffold.bottomNavigationBar] already handles the keyboard).
class _UploadBar extends StatelessWidget {
  const _UploadBar({required this.count, required this.onUpload});

  final int count;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = count == 0
        ? 'Tick requests to upload'
        : 'Upload $count ${count == 1 ? 'request' : 'requests'}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              BSizes.defaultSpace, 12, BSizes.defaultSpace, 12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: count == 0 ? null : onUpload,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Iconsax.document_upload, size: 18),
              label: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

class _FillMessage extends StatelessWidget {
  const _FillMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Null shows a progress indicator instead.
  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.1),
              ),
              alignment: Alignment.center,
              child: icon == null
                  ? SizedBox.square(
                      dimension: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: scheme.primary))
                  : Icon(icon, size: 28, color: scheme.primary),
            ),
            const SizedBox(height: BSizes.md),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: BSizes.xs),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: BSizes.md),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
