import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_evaluation.dart';

/// The case's stages in order (SOA → Follow up → Collection letter): done
/// ones with their date, the current one ringed, later ones locked. Tapping
/// an unlocked stage calls [onLog] with its step, when the collector may log.
class ReconStageTrack extends StatelessWidget {
  const ReconStageTrack({super.key, required this.evaluation, this.onLog});

  final ReconEvaluation evaluation;
  final ValueChanged<ReconActivityType>? onLog;

  static final DateFormat _date = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final current = evaluation.currentStage;
    final children = <Widget>[];
    for (final stage in ReconStage.values) {
      if (stage.index > 0) {
        children.add(Expanded(
          flex: 1,
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(top: 13),
            color: evaluation.stageProgress(stage).done
                ? BCollectionColors.primary
                : BCollectionColors.outline,
          ),
        ));
      }
      final unlocked = evaluation.stageUnlocked(stage);
      children.add(Expanded(
        flex: 3,
        child: _StageNode(
          progress: evaluation.stageProgress(stage),
          isCurrent: stage == current && !evaluation.isClosed,
          locked: !unlocked,
          onTap: onLog != null && unlocked && !evaluation.isClosed
              ? () => onLog!(stage.type)
              : null,
        ),
      ));
    }
    return Row(
      key: const ValueKey('recon-stage-track'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.progress,
    required this.isCurrent,
    required this.locked,
    this.onTap,
  });

  final ReconStageProgress progress;
  final bool isCurrent;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = progress;
    final Color color = p.done || isCurrent
        ? BCollectionColors.primary
        : BCollectionColors.inkMuted;
    final String detail = p.done
        ? [
            ReconStageTrack._date.format(p.lastAt!),
            if (p.count > 1) '×${p.count}',
          ].join(' ')
        : locked
            ? 'after ${p.stage.previous!.inSentence}'
            : 'next';
    return InkWell(
      key: ValueKey('recon-stage-${p.stage.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.done ? BCollectionColors.primary : Colors.transparent,
              border: Border.all(
                  color: p.done || isCurrent
                      ? BCollectionColors.primary
                      : BCollectionColors.outline,
                  width: isCurrent ? 2.5 : 1.5),
            ),
            child: Icon(
              p.done
                  ? Icons.check
                  : locked
                      ? Icons.lock_outline
                      : Icons.circle_outlined,
              size: 14,
              color: p.done ? Colors.white : color,
            ),
          ),
          const SizedBox(height: BSizes.xs),
          Text(p.stage.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: p.done || isCurrent
                      ? BCollectionColors.ink
                      : BCollectionColors.inkMuted,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500)),
          Text(detail,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: BCollectionColors.inkMuted)),
        ],
      ),
    );
  }
}
