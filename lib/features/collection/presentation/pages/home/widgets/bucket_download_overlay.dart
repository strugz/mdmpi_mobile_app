import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Full-screen transition shown while "Download Bucket" pulls a fresh bucket
/// from the server: a blurred scrim with a card that animates data packets
/// flowing from the server to the bucket, then resolves into a success check
/// or an error mark before fading away.
///
/// Renders nothing when [phase] is [BucketDownloadPhase.idle]. Purely
/// presentational — the caller (home screen) drives [phase] from the controller.
class BucketDownloadOverlay extends StatelessWidget {
  const BucketDownloadOverlay({
    super.key,
    required this.phase,
    this.itemCount = 0,
    this.bucketImageAsset = 'assets/images/bucket-list.png',
  });

  final BucketDownloadPhase phase;

  /// Item count reported on success ("12 items to collect").
  final int itemCount;
  final String bucketImageAsset;

  static const Duration fadeDuration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final visible = phase != BucketDownloadPhase.idle;

    // Positioned.fill must be a direct Stack child, so it wraps the switcher
    // rather than living inside the fade transition.
    return Positioned.fill(
      child: IgnorePointer(
        // Absorb taps while active so the screen behind can't be interacted with.
        ignoring: !visible,
        child: AnimatedSwitcher(
          duration: fadeDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: visible
              ? _Scrim(
                  key: const ValueKey('bucket-download-scrim'),
                  child: _DownloadCard(
                    phase: phase,
                    itemCount: itemCount,
                    bucketImageAsset: bucketImageAsset,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('bucket-download-hidden')),
        ),
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: BCollectionColors.ink.withValues(alpha: 0.45),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
          child: child,
        ),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({
    required this.phase,
    required this.itemCount,
    required this.bucketImageAsset,
  });

  final BucketDownloadPhase phase;
  final int itemCount;
  final String bucketImageAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Material(
        color: BCollectionColors.surface,
        elevation: 12,
        shadowColor: BCollectionColors.ink.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              BSizes.lg, BSizes.lg, BSizes.lg, BSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 96,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(
                        parent: anim, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: switch (phase) {
                    BucketDownloadPhase.success => const _ResultBadge(
                        key: ValueKey('success'),
                        icon: Iconsax.tick_circle5,
                        color: BCollectionColors.success,
                      ),
                    BucketDownloadPhase.error => const _ResultBadge(
                        key: ValueKey('error'),
                        icon: Iconsax.close_circle5,
                        color: BCollectionColors.danger,
                      ),
                    _ => _DataTransferAnimation(
                        key: const ValueKey('transfer'),
                        bucketImageAsset: bucketImageAsset,
                      ),
                  },
                ),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Text(
                switch (phase) {
                  BucketDownloadPhase.success => 'Bucket updated',
                  BucketDownloadPhase.error => 'Download failed',
                  _ => 'Downloading bucket',
                },
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BSizes.xs),
              SizedBox(
                height: 20,
                child: switch (phase) {
                  BucketDownloadPhase.success => _Caption(
                      itemCount == 0
                          ? 'No items in bucket'
                          : '$itemCount item${itemCount == 1 ? '' : 's'} to collect',
                    ),
                  BucketDownloadPhase.error =>
                    const _Caption('Check your connection and try again.'),
                  _ => const _CyclingStatusText(),
                },
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              // Only mounted while downloading: an indeterminate bar keeps
              // animating even when invisible, which would hold the result
              // state "busy" forever.
              SizedBox(
                height: 4,
                child: phase == BucketDownloadPhase.downloading
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor:
                              BCollectionColors.primary.withValues(alpha: 0.12),
                          color: BCollectionColors.primary,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: BCollectionColors.inkMuted),
    );
  }
}

/// Rotates through short status lines so a slow server still feels alive.
/// The lines are cosmetic; the repository does not expose real phases.
class _CyclingStatusText extends StatefulWidget {
  const _CyclingStatusText();

  static const List<String> lines = [
    'Connecting to server…',
    'Fetching collection items…',
    'Saving to this device…',
  ];

  @override
  State<_CyclingStatusText> createState() => _CyclingStatusTextState();
}

class _CyclingStatusTextState extends State<_CyclingStatusText> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _CyclingStatusText.lines.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: _Caption(
        _CyclingStatusText.lines[_index],
        key: ValueKey(_index),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
        ),
        child: Icon(icon, size: 56, color: color),
      ),
    );
  }
}

/// Server → bucket transfer: a pulsing server node on the left, the bucket on
/// the right, and data packets streaming along a dotted track between them.
class _DataTransferAnimation extends StatefulWidget {
  const _DataTransferAnimation({super.key, required this.bucketImageAsset});
  final String bucketImageAsset;

  @override
  State<_DataTransferAnimation> createState() => _DataTransferAnimationState();
}

class _DataTransferAnimationState extends State<_DataTransferAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const nodeSize = 64.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Gentle pulse on the server node, in step with the packet stream.
        final pulse = 1 + 0.05 * math.sin(t * 2 * math.pi);

        return Row(
          children: [
            Transform.scale(
              scale: pulse,
              child: _Node(
                size: nodeSize,
                ringOpacity: 0.35 - 0.2 * math.sin(t * 2 * math.pi).abs(),
                child: const Icon(Iconsax.cloud_connection,
                    size: 32, color: BCollectionColors.primary),
              ),
            ),
            Expanded(
              child: CustomPaint(
                painter: _PacketTrackPainter(
                    progress: t, color: BCollectionColors.primary),
                child: const SizedBox(height: nodeSize),
              ),
            ),
            _Node(
              size: nodeSize,
              ringOpacity: 0.15,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child:
                    Image.asset(widget.bucketImageAsset, fit: BoxFit.contain),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Node extends StatelessWidget {
  const _Node(
      {required this.size, required this.ringOpacity, required this.child});
  final double size;
  final double ringOpacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BCollectionColors.primary.withValues(alpha: 0.08),
        border: Border.all(
            color: BCollectionColors.primary.withValues(alpha: ringOpacity),
            width: 3),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Draws a dotted track and [packetCount] rounded packets travelling left to
/// right, fading in at the start and out at the end of the run.
class _PacketTrackPainter extends CustomPainter {
  const _PacketTrackPainter({required this.progress, required this.color});

  final double progress;
  final Color color;
  static const int packetCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const inset = 8.0;
    final start = inset;
    final end = size.width - inset;
    if (end <= start) return;

    // Dotted baseline.
    final dotPaint = Paint()..color = color.withValues(alpha: 0.25);
    for (double x = start; x <= end; x += 8) {
      canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
    }

    // Packets.
    const packetW = 14.0;
    const packetH = 8.0;
    for (var i = 0; i < packetCount; i++) {
      final p = (progress + i / packetCount) % 1.0;
      final x = start + (end - start) * p;
      // Ease alpha in/out at the ends of the track.
      final alpha = math.sin(p * math.pi).clamp(0.0, 1.0);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: packetW, height: packetH),
        const Radius.circular(3),
      );
      canvas.drawRRect(
          rect, Paint()..color = color.withValues(alpha: 0.25 + 0.75 * alpha));
    }
  }

  @override
  bool shouldRepaint(_PacketTrackPainter old) =>
      old.progress != progress || old.color != color;
}
