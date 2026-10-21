import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/client_match_result.dart';

/// The top candidates for a scanned customer name, best first. Nothing is
/// pre-selected: the user taps one to confirm it (plan §3, §4.4).
class ClientMatchPicker extends StatelessWidget {
  const ClientMatchPicker({
    super.key,
    required this.match,
    required this.onPick,
  });

  final ClientMatchResult match;
  final ValueChanged<ClientCandidate> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final candidate in match.candidates)
          ListTile(
            key: Key('candidate-${candidate.client.id}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(candidate.client.name,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(candidate.client.address,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: BSizes.sm, vertical: BSizes.xxs),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(BSizes.sm),
              ),
              child: Text(candidate.label, style: theme.textTheme.labelSmall),
            ),
            onTap: () => onPick(candidate),
          ),
      ],
    );
  }
}
