import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Document references, compact.
///
/// A delivery can carry 15–20 references (DR / SI / PO numbers). One tall row
/// per reference, each with its own copy icon, pushed everything else off the
/// screen. Instead: references are grouped by their prefix ("DRNo.", "SINo.",
/// "PONo."), each group is a row of small chips holding just the number, a
/// chip copies its full reference on tap, and past [collapsedLimit] the list
/// folds behind a "Show all N" toggle. A single "Copy all" copies every
/// reference, one per line.
class DocumentReferenceList extends StatefulWidget {
  final List<String> documentReferences;
  final Color textColor;

  /// How many references are shown before the list folds.
  final int collapsedLimit;

  const DocumentReferenceList({
    super.key,
    required this.documentReferences,
    required this.textColor,
    this.collapsedLimit = 6,
  });

  /// De-duplicates, trims and groups references by the text before the first
  /// ':' (e.g. `DRNo.:690013618` → group `DRNo.`, value `690013618`).
  /// References without a prefix land in the `''` group. First-seen order is
  /// kept for groups and for values within a group.
  static Map<String, List<DocumentReference>> group(
      Iterable<String> references) {
    final seen = <String>{};
    // Dart map literals are insertion-ordered.
    final groups = <String, List<DocumentReference>>{};
    for (final raw in references) {
      final reference = raw.trim();
      if (reference.isEmpty || !seen.add(reference)) continue;
      final colon = reference.indexOf(':');
      final prefix = colon > 0 ? reference.substring(0, colon).trim() : '';
      final value =
          colon > 0 ? reference.substring(colon + 1).trim() : reference;
      groups.putIfAbsent(prefix, () => []).add(
            DocumentReference(full: reference, prefix: prefix, value: value),
          );
    }
    return groups;
  }

  @override
  State<DocumentReferenceList> createState() => _DocumentReferenceListState();
}

class DocumentReference {
  const DocumentReference(
      {required this.full, required this.prefix, required this.value});
  final String full;
  final String prefix;
  final String value;
}

class _DocumentReferenceListState extends State<DocumentReferenceList> {
  bool _expanded = false;

  Future<void> _copy(String text, {required String toast}) async {
    await Clipboard.setData(ClipboardData(text: text));
    BHelperFunctions.showSnackBar(toast);
  }

  @override
  Widget build(BuildContext context) {
    final groups = DocumentReferenceList.group(widget.documentReferences);
    final all = groups.values.expand((g) => g).toList();
    if (all.isEmpty) return const SizedBox.shrink();

    final dark = BHelperFunctions.isDarkMode(context);
    final muted = widget.textColor.withValues(alpha: 0.6);
    final folded = !_expanded && all.length > widget.collapsedLimit;

    // Take the first N references in display order when folded, so the
    // collapsed view still shows the first few of each group in turn.
    var budget = folded ? widget.collapsedLimit : all.length;
    final visibleGroups = <String, List<DocumentReference>>{};
    for (final entry in groups.entries) {
      if (budget <= 0) break;
      final take = entry.value.take(budget).toList();
      visibleGroups[entry.key] = take;
      budget -= take.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in visibleGroups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: BSizes.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.key.isNotEmpty)
                  SizedBox(
                    width: 52,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _shortPrefix(entry.key),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: muted, letterSpacing: 0.4),
                      ),
                    ),
                  ),
                Expanded(
                  child: Wrap(
                    spacing: BSizes.xs,
                    runSpacing: BSizes.xs,
                    children: [
                      for (final ref in entry.value)
                        _ReferenceChip(
                          reference: ref,
                          dark: dark,
                          textColor: widget.textColor,
                          onTap: () =>
                              _copy(ref.full, toast: 'Copied ${ref.full}'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (all.length > 1 || folded)
          Row(
            children: [
              if (all.length > widget.collapsedLimit)
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: BSizes.xs),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    _expanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                    size: 14,
                  ),
                  label: Text(_expanded
                      ? 'Show less'
                      : 'Show all ${all.length}'),
                ),
              const Spacer(),
              if (all.length > 1)
                TextButton.icon(
                  onPressed: () => _copy(
                    all.map((r) => r.full).join('\n'),
                    toast: 'Copied ${all.length} references',
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: BSizes.xs),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Iconsax.copy, size: 14),
                  label: const Text('Copy all'),
                ),
            ],
          ),
      ],
    );
  }

  /// `DRNo.` → `DR`, `PONo.` → `PO`; anything else is shown as typed.
  static String _shortPrefix(String prefix) {
    final match = RegExp(r'^([A-Za-z]{2,4})No\.?$').firstMatch(prefix);
    return match?.group(1) ?? prefix;
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({
    required this.reference,
    required this.dark,
    required this.textColor,
    required this.onTap,
  });

  final DocumentReference reference;
  final bool dark;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? BColors.darkerGrey : BColors.softGrey,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: BSizes.sm, vertical: 5),
          child: Text(
            reference.value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ),
      ),
    );
  }
}
