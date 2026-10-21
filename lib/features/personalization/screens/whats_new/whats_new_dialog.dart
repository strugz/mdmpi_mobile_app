import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/whats_new.dart';

/// The update's What's new, one card at a time over Home. Nothing closes it
/// but the button on the last card: no close icon, no tap outside, no system
/// back, no swipe. Back is there to reread a card, never to skip one.
///
/// Pops `true` when the last card is done.
class WhatsNewDialog extends StatefulWidget {
  const WhatsNewDialog({super.key, required this.group});

  final WhatsNewGroup group;

  @override
  State<WhatsNewDialog> createState() => _WhatsNewDialogState();
}

class _WhatsNewDialogState extends State<WhatsNewDialog> {
  static const _easeOut = Cubic(0.23, 1, 0.32, 1);
  static const _duration = Duration(milliseconds: 240);

  int _index = 0;
  bool _forward = true;

  List<WhatsNewItem> get _items => widget.group.items;
  bool get _isLast => _index == _items.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _forward = true;
      _index++;
    });
  }

  void _back() {
    if (_index == 0) return;
    setState(() {
      _forward = false;
      _index--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : _duration;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
            horizontal: BSizes.lg, vertical: BSizes.defaultSpace),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                BSizes.lg, BSizes.lg, BSizes.lg, BSizes.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text("What's new in ${widget.group.version}",
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: cs.primary, fontWeight: FontWeight.w700)),
                    ),
                    Text('${_index + 1} of ${_items.length}',
                        key: const ValueKey('whats-new-step'),
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: BSizes.sm),
                _Progress(
                    count: _items.length, done: _index + 1, duration: duration),
                const SizedBox(height: BSizes.lg),
                Flexible(
                  child: SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: duration,
                      switchInCurve: _easeOut,
                      switchOutCurve: Curves.easeOut,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, if (current != null) current],
                      ),
                      transitionBuilder: (child, animation) {
                        final incoming = child.key == ValueKey(_index);
                        if (!incoming) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        }
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: Offset(_forward ? 0.06 : -0.06, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _Card(key: ValueKey(_index), item: _items[_index]),
                    ),
                  ),
                ),
                const SizedBox(height: BSizes.lg),
                Row(
                  children: [
                    // Keeps its space on the first card so Next never moves.
                    Visibility(
                      visible: _index > 0,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: TextButton(
                        key: const ValueKey('whats-new-back'),
                        onPressed: _index > 0 ? _back : null,
                        child: const Text('Back'),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const ValueKey('whats-new-next'),
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(128, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(_isLast ? 'Got it' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One segment per card, filled up to the current one, so the length of the
/// walk is visible from the first card.
class _Progress extends StatelessWidget {
  const _Progress(
      {required this.count, required this.done, required this.duration});

  final int count;
  final int done;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              height: 4,
              decoration: BoxDecoration(
                color: i < done ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.item});

  final WhatsNewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(item.icon, size: 30, color: cs.primary),
        ),
        const SizedBox(height: BSizes.md),
        Text((item.area ?? 'Everyone').toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
        const SizedBox(height: BSizes.xs),
        Text(item.title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: BSizes.sm),
        Text(item.detail,
            style: theme.textTheme.bodyLarge
                ?.copyWith(height: 1.45, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
