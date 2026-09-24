import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/status_chip.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_comparison.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_date_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/upload_candidate.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_department_theme.dart';

/// Opens the phone-vs-server comparison for one saved request.
///
/// [onTakeServerCopy] is offered for server-ahead requests; it should replace
/// the phone's copy and return null on success or an error message.
Future<void> showUploadCompareSheet(
  BuildContext context, {
  required UploadCandidate candidate,
  Future<String?> Function()? onTakeServerCopy,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The app's sheet theme draws a dark handle; this sheet draws its own,
    // lighter one inside the scroll view so dragging it resizes the sheet.
    showDragHandle: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => UploadCompareSheet(
      candidate: candidate,
      onTakeServerCopy: onTakeServerCopy,
    ),
  );
}

/// Side-by-side Phone | Server view of one request, differing fields first
/// and highlighted, so it is obvious what the server has that the phone does
/// not (and why an upload would be refused).
class UploadCompareSheet extends StatefulWidget {
  const UploadCompareSheet({
    super.key,
    required this.candidate,
    this.onTakeServerCopy,
  });

  final UploadCandidate candidate;
  final Future<String?> Function()? onTakeServerCopy;

  @override
  State<UploadCompareSheet> createState() => _UploadCompareSheetState();
}

class _UploadCompareSheetState extends State<UploadCompareSheet> {
  late final List<ComparisonField> _fields =
      BUploadComparison.fields(widget.candidate.local, widget.candidate.server);
  late final int _differing = _fields.where((f) => f.differs).length;

  /// Differences only by default, when there are any.
  late bool _onlyDifferences = _differing > 0;
  bool _busy = false;

  List<ComparisonField> get _shown =>
      _onlyDifferences ? _fields.where((f) => f.differs).toList() : _fields;

  Future<void> _takeServerCopy() async {
    setState(() => _busy = true);
    final error = await widget.onTakeServerCopy!();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = widget.candidate;
    final canTake = c.group == UploadCandidateGroup.serverAhead &&
        c.server != null &&
        widget.onTakeServerCopy != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _Title(candidate: c),
                const SizedBox(height: 14),
                _Verdict(candidate: c, differing: _differing),
                const SizedBox(height: 18),
                if (c.server != null) ...[
                  _ModeSwitch(
                    onlyDifferences: _onlyDifferences,
                    differing: _differing,
                    total: _fields.length,
                    onChanged: (v) => setState(() => _onlyDifferences = v),
                  ),
                  const SizedBox(height: 14),
                ],
                const _ColumnHeads(),
                const SizedBox(height: 6),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: Column(
                      key: ValueKey(_onlyDifferences),
                      children: [
                        for (final field in _shown)
                          _FieldRow(field: field, hasServer: c.server != null),
                        if (_shown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Every field matches the server.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Footer pads for the navigation bar once, here at the bottom.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  if (canTake) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _takeServerCopy,
                        icon: _busy
                            ? SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: scheme.onPrimary))
                            : const Icon(Iconsax.import_1, size: 18),
                        label: const Text('Take server copy'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.candidate});

  final UploadCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(candidate.clientName,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          '#${candidate.id}'
          '${candidate.isHotlineDirect ? ' · Hotline Direct' : ' · Standard Delivery'}',
          style: theme.textTheme.labelMedium?.copyWith(color: muted),
        ),
      ],
    );
  }
}

/// One sentence on what the comparison means, in the group's colour.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.candidate, required this.differing});

  final UploadCandidate candidate;
  final int differing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = SettingsStatusColors.of(context);
    final phone = candidate.local.status.trim();
    final server = candidate.server?.status.trim() ?? '';
    final others =
        differing == 1 ? '1 field differs' : '$differing fields differ';

    final (IconData icon, Color color, String title, String body) =
        switch (candidate.group) {
      UploadCandidateGroup.serverAhead => (
          Iconsax.cloud_remove,
          status.warning,
          'The server is ahead',
          'The server has it as $server; this phone still has it as '
              '$phone. Uploading would be refused. $others.',
        ),
      UploadCandidateGroup.ready => (
          Iconsax.document_upload,
          scheme.primary,
          'The phone is ahead',
          'This phone has it as $phone; the server still has it as '
              '$server. $others.',
        ),
      UploadCandidateGroup.sameStatus => (
          Iconsax.tick_circle,
          status.success,
          'Same status',
          differing <= 1
              ? 'Both have $phone. Nothing to upload.'
              : 'Both have $phone, but ${differing - 1} other '
                  '${differing - 1 == 1 ? 'field differs' : 'fields differ'}.',
        ),
      UploadCandidateGroup.notOnServer => (
          Iconsax.warning_2,
          status.danger,
          'Not on the server',
          'The server has no request ${candidate.id}. Only the phone has it.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Differences (3) | All fields (12)" as a two-segment switch.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.onlyDifferences,
    required this.differing,
    required this.total,
    required this.onChanged,
  });

  final bool onlyDifferences;
  final int differing;
  final int total;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget segment(String label, bool value) {
      final selected = onlyDifferences == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color:
                        selected ? scheme.onSurface : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          segment('Differences ($differing)', true),
          segment('All fields ($total)', false),
        ],
      ),
    );
  }
}

class _ColumnHeads extends StatelessWidget {
  const _ColumnHeads();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600);
    Widget head(IconData icon, String label) => Expanded(
          child: Row(
            children: [
              Icon(icon,
                  size: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: style),
            ],
          ),
        );
    return Row(
      children: [
        head(Iconsax.mobile, 'Phone'),
        const SizedBox(width: 10),
        head(Iconsax.cloud, 'Server'),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field, required this.hasServer});

  final ComparisonField field;
  final bool hasServer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warn = SettingsStatusColors.of(context).warning;
    final differs = field.differs;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (differs) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: warn, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                field.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: differs ? warn : scheme.onSurfaceVariant,
                  fontWeight: differs ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _Cell(field: field, value: field.phone)),
                const SizedBox(width: 10),
                Expanded(
                  child: hasServer
                      ? _Cell(
                          field: field,
                          value: field.server,
                          highlight: differs,
                        )
                      : const _Cell.missing(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(
      {required this.field, required this.value, this.highlight = false})
      : missing = false;

  const _Cell.missing()
      : field = null,
        value = '',
        highlight = false,
        missing = true;

  final ComparisonField? field;
  final String value;

  /// The server's side of a differing field: tinted, so the eye goes to
  /// what the server holds.
  final bool highlight;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warn = SettingsStatusColors.of(context).warning;

    Widget child;
    if (missing) {
      child = Text('No record',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant));
    } else if (value.isEmpty) {
      child = Text('—',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant));
    } else if (field!.kind == ComparisonKind.status) {
      // A long status ("Getting supplies ready") scales down to fit the
      // half-width cell rather than overflowing it.
      child = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: StatusChip(status: value, compact: true));
    } else {
      child = Text(
        _format(field!.kind, value),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? warn.withValues(alpha: 0.10)
            : scheme.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? warn.withValues(alpha: 0.35) : Colors.transparent,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  static String _format(ComparisonKind kind, String value) {
    switch (kind) {
      case ComparisonKind.stamp:
        return BFormatter.formatDateWithAmPm(value);
      case ComparisonKind.date:
        final day = BUploadDateFilter.parseDay(value);
        return day == null ? value : DateFormat('EEE, MMM d, yyyy').format(day);
      case ComparisonKind.status:
      case ComparisonKind.text:
        return value;
    }
  }
}
