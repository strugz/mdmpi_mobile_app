import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_upload_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// The motion this screen uses: short, ease-out, one curve throughout, so
/// state changes read as one system (Collection's "a screen changing state"
/// rung: 200ms easeOutCubic).
const Duration _fast = Duration(milliseconds: 200);
const Curve _ease = Curves.easeOutCubic;

/// Review and upload the offline collection queue (end-of-day "Upload All").
///
/// Top to bottom: the outcome of the last run (a banner that slides down from
/// the app bar), what is waiting (a summary by kind, then the rows), and the
/// one action. While uploading, a progress panel counts "12 of 30" and rows
/// leave the list as their batch is accepted.
class CollectionUploadOutboxScreen extends StatelessWidget {
  const CollectionUploadOutboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CollectionUploadController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Collections'),
        actions: [
          Obx(() => controller.isResetting.value
              ? const Padding(
                  padding: EdgeInsets.all(BSizes.md),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : (controller.pending.isEmpty || controller.busy)
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Discard all',
                      icon: const Icon(Iconsax.trash),
                      onPressed: () => _confirmDiscardAll(controller),
                    )),
        ],
      ),
      body: Column(
        children: [
          _BannerHost(controller: controller),
          Expanded(
            child: Obx(() {
              final busy = controller.busy;
              final Widget content;
              if (controller.isLoading.value &&
                  controller.pending.isEmpty &&
                  !busy) {
                content = const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(),
                );
              } else if (controller.pending.isEmpty && !busy) {
                content = const _EmptyState(key: ValueKey('empty'));
              } else {
                content = _Queue(
                  key: const ValueKey('queue'),
                  controller: controller,
                  busy: busy,
                );
              }
              return AnimatedSwitcher(
                duration: _fast,
                switchInCurve: _ease,
                switchOutCurve: _ease,
                child: content,
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace, BSizes.sm,
              BSizes.defaultSpace, BSizes.defaultSpace),
          child: Obx(() => _UploadAllButton(
                count: controller.pending.length,
                busy: controller.busy,
                done: controller.uploadDone.value,
                total: controller.uploadTotal.value,
                onPressed: controller.uploadAll,
              )),
        ),
      ),
    );
  }

  void _confirmDiscardAll(CollectionUploadController controller) {
    Get.defaultDialog(
      title: 'Discard all and reset?',
      middleText:
          'Everything queued is removed without uploading, and this phone goes '
          "back to the server's copy: cases, calendar entries, claims and "
          'payments recorded since your last upload disappear. Needs internet.',
      textConfirm: 'Discard',
      textCancel: 'Cancel',
      confirmTextColor: BCollectionColors.surface,
      buttonColor: BCollectionColors.danger,
      onConfirm: () async {
        Get.back();
        final result = await controller.discardAll();
        if (result.isSuccess) {
          BLoaders.successSnackBar(title: 'Reset', message: result.value);
        } else {
          BLoaders.errorSnackBar(title: 'Not reset', message: result.error);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Banner
// ---------------------------------------------------------------------------

/// Slides the outcome banner down from under the app bar and back up: the
/// same direction in and out, so it reads as one object arriving and
/// leaving. A "done" banner leaves by itself after a few seconds; one that
/// needs the collector stays until read. Reduced motion: a fade only.
class _BannerHost extends StatefulWidget {
  const _BannerHost({required this.controller});

  final CollectionUploadController controller;

  @override
  State<_BannerHost> createState() => _BannerHostState();
}

class _BannerHostState extends State<_BannerHost> {
  Timer? _autoDismiss;
  late final Worker _worker;

  static const Duration _doneFor = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _worker = ever<UploadBanner?>(widget.controller.banner, (banner) {
      _autoDismiss?.cancel();
      if (banner != null && banner.autoDismiss) {
        _autoDismiss = Timer(_doneFor, widget.controller.dismissBanner);
      }
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _worker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Obx(() {
      final banner = widget.controller.banner.value;
      return AnimatedSize(
        duration: _fast,
        curve: _ease,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: _fast,
          // Leaving is quicker than arriving: the system is answering, not
          // asking for attention.
          reverseDuration: const Duration(milliseconds: 150),
          switchInCurve: _ease,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            final fade = FadeTransition(opacity: animation, child: child);
            if (reduceMotion) return fade;
            return SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero)
                      .animate(animation),
              child: fade,
            );
          },
          child: banner == null
              ? const SizedBox(
                  key: ValueKey('no-banner'), width: double.infinity)
              : _UploadBannerCard(
                  key: ValueKey('${banner.kind}-${banner.title}'),
                  banner: banner,
                  onRetry: widget.controller.uploadAll,
                  onDismiss: widget.controller.dismissBanner,
                ),
        ),
      );
    });
  }
}

class _UploadBannerCard extends StatelessWidget {
  const _UploadBannerCard({
    super.key,
    required this.banner,
    required this.onRetry,
    required this.onDismiss,
  });

  final UploadBanner banner;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = switch (banner.kind) {
      UploadBannerKind.done => (BCollectionColors.success, Iconsax.tick_circle),
      UploadBannerKind.issues => (BCollectionColors.warning, Iconsax.warning_2),
      UploadBannerKind.stopped => (
          BCollectionColors.danger,
          Iconsax.wifi_square
        ),
    };
    return Padding(
      key: const ValueKey('upload-banner'),
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, BSizes.sm, BSizes.defaultSpace, 0),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              BSizes.md, BSizes.sm + 2, BSizes.xs, BSizes.sm + 2),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
                color.withValues(alpha: 0.10), BCollectionColors.surface),
            borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: BSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(banner.title,
                        key: const ValueKey('upload-banner-title'),
                        style: theme.textTheme.titleSmall?.copyWith(
                            color: BCollectionColors.ink,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(banner.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: BCollectionColors.inkSecondary,
                            height: 1.35)),
                    if (banner.canRetry) ...[
                      const SizedBox(height: BSizes.sm),
                      BPressableScale(
                        onTap: onRetry,
                        child: Container(
                          key: const ValueKey('upload-retry'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: BSizes.md, vertical: BSizes.xs + 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius:
                                BorderRadius.circular(BSizes.borderRadiusMd),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.refresh,
                                  size: 16, color: BCollectionColors.onPrimary),
                              const SizedBox(width: BSizes.xs),
                              Text('Retry',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      color: BCollectionColors.onPrimary,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close,
                    size: 18, color: BCollectionColors.inkMuted),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Queue
// ---------------------------------------------------------------------------

/// What is waiting: a progress panel while uploading, else a summary by
/// kind, then the rows. Rows are dimmed and inert while a batch is in
/// flight, so one cannot be discarded halfway through being sent.
class _Queue extends StatelessWidget {
  const _Queue({super.key, required this.controller, required this.busy});

  final CollectionUploadController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final rows = controller.pending;
    return RefreshIndicator(
      onRefresh: controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                BSizes.defaultSpace, BSizes.md, BSizes.defaultSpace, BSizes.sm),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: _fast,
                switchInCurve: _ease,
                switchOutCurve: _ease,
                child: busy
                    ? Obx(() => _ProgressPanel(
                          key: const ValueKey('progress'),
                          done: controller.uploadDone.value,
                          total: controller.uploadTotal.value,
                        ))
                    : _Summary(key: const ValueKey('summary'), rows: rows),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                BSizes.defaultSpace, 0, BSizes.defaultSpace, BSizes.md),
            sliver: SliverList.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: BSizes.xs),
              itemBuilder: (context, index) {
                final change = rows[index];
                return IgnorePointer(
                  ignoring: busy,
                  child: AnimatedOpacity(
                    opacity: busy ? 0.5 : 1,
                    duration: _fast,
                    curve: _ease,
                    child: _PendingRow(
                      key: ValueKey('pending-${change.id}'),
                      change: change,
                      onDiscard: change.id == null
                          ? null
                          : () => controller.discard(change.id!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "12 of 30" with a bar that eases to each new count rather than jumping,
/// so steady progress reads as steady.
class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(BSizes.md),
      decoration: BoxDecoration(
        color: BCollectionColors.primarySoft,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BCollectionColors.primary),
              ),
              const SizedBox(width: BSizes.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Uploading  '),
                    TextSpan(
                      text: '$done',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' of $total'),
                  ]),
                  key: const ValueKey('upload-progress-text'),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: BCollectionColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: BSizes.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: const Duration(milliseconds: 250),
            curve: _ease,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                color: BCollectionColors.primary,
                backgroundColor: BCollectionColors.surface,
              ),
            ),
          ),
          const SizedBox(height: BSizes.xs),
          Text(
            'Keep the app open. If the connection drops, what was sent stays '
            'sent and the rest goes when you are back online.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: BCollectionColors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

/// "8 waiting" and the count of each kind, so a long list is read at a
/// glance before it is scrolled.
class _Summary extends StatelessWidget {
  const _Summary({super.key, required this.rows});

  final List<PendingChange> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byKind = <String, int>{};
    var needAttention = 0;
    for (final c in rows) {
      byKind.update(_operationLabel(c.operation), (n) => n + 1,
          ifAbsent: () => 1);
      if (c.retryCount > 0) needAttention++;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '${rows.length}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
                text: rows.length == 1 ? ' item waiting' : ' items waiting'),
          ]),
          key: const ValueKey('upload-summary'),
          style: theme.textTheme.titleMedium
              ?.copyWith(color: BCollectionColors.ink),
        ),
        const SizedBox(height: BSizes.xs),
        Wrap(
          spacing: BSizes.xs,
          runSpacing: BSizes.xs,
          children: [
            for (final MapEntry(key: label, value: n) in byKind.entries)
              _Chip(label: '$n $label', color: BCollectionColors.neutral),
            if (needAttention > 0)
              _Chip(
                  label: '$needAttention need attention',
                  color: BCollectionColors.danger),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

/// One queued change: what it is, which invoice or reference, and, when the
/// server refused it, why. Discard is quiet (muted) until it is the thing
/// the collector is reaching for.
class _PendingRow extends StatelessWidget {
  const _PendingRow({super.key, required this.change, this.onDiscard});

  final PendingChange change;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rejected = change.retryCount > 0;
    final tint =
        rejected ? BCollectionColors.danger : BCollectionColors.primary;
    final reason = change.lastError?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(
          BSizes.sm + 2, BSizes.sm + 2, BSizes.xs, BSizes.sm + 2),
      decoration: BoxDecoration(
        color: BCollectionColors.surface,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        border: Border.all(
            color: rejected
                ? BCollectionColors.danger.withValues(alpha: 0.35)
                : BCollectionColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
                rejected ? Iconsax.warning_2 : _operationIcon(change.operation),
                size: 17,
                color: tint),
          ),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_operationLabel(change.operation),
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: BCollectionColors.ink,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(_reference(change),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BCollectionColors.inkSecondary)),
                if (rejected) ...[
                  const SizedBox(height: BSizes.xs),
                  Text(
                    reason.isEmpty
                        ? 'Refused by the server · tried ${change.retryCount}×'
                        : '$reason · tried ${change.retryCount}×',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: BCollectionColors.danger,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Discard',
            visualDensity: VisualDensity.compact,
            icon: Icon(Iconsax.close_circle,
                size: 20, color: BCollectionColors.inkMuted),
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }
}

/// Upload All, with the run's count while it goes ("Uploading 12/30").
///
/// Stays primary-coloured while busy: the theme paints a disabled button
/// grey-on-grey, which reads as "dead" rather than "working". Taps are absorbed
/// instead. The label crossfades with a slight scale (ease-out, 200ms) so the
/// change of state shows the instant the button is pressed, and the button
/// itself gives under the finger (0.97).
class _UploadAllButton extends StatelessWidget {
  const _UploadAllButton({
    required this.count,
    required this.busy,
    required this.done,
    required this.total,
    required this.onPressed,
  });

  final int count;
  final bool busy;
  final int done;
  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget child = busy
        ? Row(
            key: const ValueKey('busy'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: BCollectionColors.surface,
                ),
              ),
              const SizedBox(width: BSizes.sm),
              Text(total == 0 ? 'Uploading…' : 'Uploading $done/$total',
                  key: const ValueKey('upload-button-progress')),
            ],
          )
        : Row(
            key: ValueKey('idle-$count'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.cloud_plus),
              const SizedBox(width: BSizes.sm),
              Text(count == 0 ? 'Nothing to upload' : 'Upload All ($count)'),
            ],
          );

    return _PressScale(
      enabled: count > 0 && !busy,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: count == 0 && !busy ? null : (busy ? () {} : onPressed),
          child: AnimatedSwitcher(
            duration: _fast,
            switchInCurve: _ease,
            switchOutCurve: _ease,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Gives under the finger (0.97, ease-out) without taking the tap: a
/// [Listener] sees the pointer but does not enter the gesture arena, so the
/// button inside still gets its press and its ripple.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: widget.enabled ? (_) => _set(true) : null,
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: _ease,
          child: widget.child,
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.tick_circle,
              size: 56, color: BCollectionColors.success),
          const SizedBox(height: BSizes.sm),
          Text(
            'All collections uploaded',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: BSizes.xs),
          Text(
            'Nothing waiting to sync.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: BCollectionColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// "Invoice 700011347" for bucket work, "Ref ACT-…" for an activity (a
/// deposit, CWT pick-up, reconciliation).
String _reference(PendingChange change) {
  final id = change.itemId ?? '—';
  return id.startsWith('ACT-') ? 'Ref $id' : 'Invoice $id';
}

IconData _operationIcon(String operation) => switch (operation.toUpperCase()) {
      'CLAIM' => Iconsax.user_add,
      'SAVE_ACTIVITY' || 'BATCH_ACTIVITY' => Iconsax.money_recive,
      'DEPOSIT' => Iconsax.bank,
      'ADVANCED_PAYMENT' || 'ASSIGN_ADVANCE' => Iconsax.card_send,
      'RECONCILIATION' ||
      'RECON_OPEN_CASE' ||
      'RECON_ACTIVITY' =>
        Iconsax.status_up,
      _ => Iconsax.document_upload,
    };

String _operationLabel(String operation) {
  switch (operation.toUpperCase()) {
    case 'CLAIM':
      return 'Acquire account';
    case 'SAVE_ACTIVITY':
      return 'Collection recorded';
    case 'BATCH_ACTIVITY':
      return 'Batch collection';
    case 'OFFICE_ACTIVITY':
      return 'Office activity';
    case 'DEPOSIT':
      return 'Deposit';
    case 'CWT_PICKUP':
      return 'CWT Pick-up';
    case 'ROUTING_DOCUMENTS':
      return 'Routing of Documents';
    case 'RECONCILIATION':
      return 'Reconciliation';
    case 'RECON_OPEN_CASE':
      return 'Reconciliation case opened';
    case 'RECON_ACTIVITY':
      return 'Reconciliation step';
    case 'ADVANCED_PAYMENT':
      return 'Advanced payment';
    case 'ASSIGN_ADVANCE':
      return 'Advance assigned to invoice';
    case 'LINK_ADVANCE':
      return 'Advance linked to its account';
    case 'SET_TARGET':
      return 'Monthly target';
    case 'DEFER':
      return 'Deferred engagement';
    case 'CLEAR':
      return 'Cleared engagement';
    default:
      return operation;
  }
}
