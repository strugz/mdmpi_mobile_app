import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_date_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/upload_candidate.dart';

/// One saved request on the Upload Data page: a round tick when it can be
/// sent (otherwise an icon saying why not), the client, the delivery date,
/// and the phone's and server's status as the same pills the delivery lists
/// use.
class UploadCandidateTile extends StatelessWidget {
  const UploadCandidateTile({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onToggle,
    this.onCompare,
  });

  final UploadCandidate candidate;
  final bool selected;
  final VoidCallback onToggle;

  /// Opens the phone-vs-server comparison. Rows that cannot be ticked open
  /// it on tap; every row also has a compare button.
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectable = candidate.group.isSelectable;
    final muted = scheme.onSurfaceVariant;

    final content = Padding(
      padding: EdgeInsets.fromLTRB(14, 14, onCompare == null ? 16 : 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: selectable
                ? _RoundTick(selected: selected)
                : _GroupIcon(group: candidate.group),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selectable ? scheme.onSurface : muted,
                        ),
                      ),
                    ),
                    if (candidate.isHotlineDirect) ...[
                      const SizedBox(width: 8),
                      _Badge(label: 'Hotline Direct', color: scheme.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 10),
                _StatusLine(candidate: candidate),
              ],
            ),
          ),
          if (onCompare != null)
            IconButton(
              onPressed: onCompare,
              tooltip: 'Compare with server',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.compare_arrows_rounded, size: 20, color: muted),
            ),
        ],
      ),
    );

    return Semantics(
      checked: selectable ? selected : null,
      label: '${candidate.clientName}, ${candidate.reason}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: selectable ? onToggle : onCompare,
          // A soft wash on ticked rows, so the selection reads at a glance
          // without a second accent colour.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            color: selected && selectable
                ? scheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            child: content,
          ),
        ),
      ),
    );
  }

  String get _meta {
    final day = BUploadDateFilter.parseDay(candidate.local.deliveryDate);
    final when =
        day == null ? 'No delivery date' : DateFormat('EEE, MMM d').format(day);
    return '#${candidate.id} · $when';
  }
}

/// Phone status → server status, or a single pill when they agree.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.candidate});

  final UploadCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final caption =
        Theme.of(context).textTheme.labelSmall?.copyWith(color: muted);
    final phone = candidate.local.status;
    final server = candidate.server?.status;

    final children = switch (candidate.group) {
      UploadCandidateGroup.sameStatus => [
          StatusChip(status: phone, compact: true),
          Text('on phone and server', style: caption),
        ],
      UploadCandidateGroup.notOnServer => [
          StatusChip(status: phone, compact: true),
          Text('not on the server', style: caption),
        ],
      _ => [
          Text('Phone', style: caption),
          StatusChip(status: phone, compact: true),
          Icon(Icons.arrow_forward_rounded, size: 14, color: muted),
          Text('Server', style: caption),
          StatusChip(status: server ?? '', compact: true),
        ],
    };

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// A round tick that fills with the accent when selected. The check grows
/// in from 0.6, never from nothing.
class _RoundTick extends StatelessWidget {
  const _RoundTick({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: selected
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.28),
          width: 1.6,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0.6,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: selected ? 1 : 0,
          duration: const Duration(milliseconds: 140),
          child: Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary),
        ),
      ),
    );
  }
}

class _GroupIcon extends StatelessWidget {
  const _GroupIcon({required this.group});

  final UploadCandidateGroup group;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: muted.withValues(alpha: 0.1),
      ),
      alignment: Alignment.center,
      child: Icon(
        group == UploadCandidateGroup.sameStatus
            ? Icons.check_rounded
            : Iconsax.cloud_remove,
        size: 15,
        color: muted,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
