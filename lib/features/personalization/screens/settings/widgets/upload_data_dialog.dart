import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_upload_summary.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_department_theme.dart';

/// Runs the upload, reporting (done, total) as requests go up.
typedef UploadDataRunner = Future<Result<RequestUploadSummary>> Function(
    void Function(int done, int total) onProgress);

/// Settings > Upload Data: confirm, upload with live progress, show the
/// result, all in one dialog that changes state in place.
Future<void> showUploadDataDialog(
  BuildContext context, {
  required UploadDataRunner upload,
  String? confirmTitle,
  String? confirmMessage,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UploadDataDialog(
      upload: upload,
      confirmTitle: confirmTitle,
      confirmMessage: confirmMessage,
    ),
  );
}

enum UploadDataPhase { confirm, uploading, done }

enum _Outcome { success, warning, failure }

// Motion tokens. Upload is an occasional action, so it can animate, but the
// state changes stay under 300ms: the dialog should feel like it is
// responding, not performing.
const _stateChange = Duration(milliseconds: 220);
const _progressStep = Duration(milliseconds: 280);
const _arrowCycle = Duration(milliseconds: 1100);

/// The confirm → uploading → result dialog.
///
/// One dialog that morphs, rather than a confirm dialog followed by a
/// snackbar: the user watches the same surface the whole time, so the result
/// lands where they were looking. Colours come from the ambient theme, which
/// Settings sets per department ([SettingsDepartmentTheme]).
class UploadDataDialog extends StatefulWidget {
  const UploadDataDialog({
    super.key,
    required this.upload,
    this.confirmTitle,
    this.confirmMessage,
    this.minimumUploadingTime = const Duration(milliseconds: 600),
  });

  final UploadDataRunner upload;

  /// Overrides the confirm step's wording, e.g. "Upload 3 requests?".
  final String? confirmTitle;
  final String? confirmMessage;

  /// Keeps the uploading state on screen at least this long, so an upload
  /// with nothing to send does not flash a frame of progress and vanish.
  final Duration minimumUploadingTime;

  @override
  State<UploadDataDialog> createState() => _UploadDataDialogState();
}

class _UploadDataDialogState extends State<UploadDataDialog> {
  UploadDataPhase _phase = UploadDataPhase.confirm;
  int _done = 0;
  int _total = 0;
  _Outcome? _outcome;
  String _resultTitle = '';
  String _resultMessage = '';

  /// Every request is sent; the server's copies of skipped ones are loading.
  bool get _checking => _total > 0 && _done >= _total;

  Future<void> _start() async {
    setState(() => _phase = UploadDataPhase.uploading);
    final watch = Stopwatch()..start();

    final result = await widget.upload((done, total) {
      if (!mounted) return;
      setState(() {
        _done = done;
        _total = total;
      });
    });

    final remaining = widget.minimumUploadingTime - watch.elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);
    if (!mounted) return;

    setState(() {
      _phase = UploadDataPhase.done;
      if (result.isFailure) {
        _outcome = _Outcome.failure;
        _resultTitle = 'Upload failed';
        _resultMessage = result.error;
        return;
      }
      final summary = result.value;
      _outcome = summary.failed.isNotEmpty
          ? _Outcome.failure
          : summary.skipped.isNotEmpty
              ? _Outcome.warning
              : _Outcome.success;
      _resultTitle = summary.title;
      _resultMessage = summary.message;
    });
  }

  Color _accent(ColorScheme scheme, SettingsStatusColors status) =>
      switch (_outcome) {
        _Outcome.success => status.success,
        _Outcome.warning => status.warning,
        _Outcome.failure => status.danger,
        null => scheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _accent(scheme, SettingsStatusColors.of(context));

    return PopScope(
      canPop: _phase != UploadDataPhase.uploading,
      child: Dialog(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: AnimatedSize(
            duration: _stateChange,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UploadBadge(
                  phase: _phase,
                  progress: _ringProgress,
                  accent: accent,
                  outcome: _outcome,
                ),
                const SizedBox(height: 20),
                _Swap(
                  child: Text(
                    _title,
                    key: ValueKey(_title),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                _Swap(child: _body(theme, accent)),
                const SizedBox(height: 20),
                _Swap(child: _actions()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Null while the total is unknown or the server check is running, which
  /// the ring shows as indeterminate.
  double? get _ringProgress => switch (_phase) {
        UploadDataPhase.confirm => 0,
        UploadDataPhase.uploading =>
          _total == 0 || _checking ? null : _done / _total,
        UploadDataPhase.done => 1,
      };

  String get _title => switch (_phase) {
        UploadDataPhase.confirm => widget.confirmTitle ?? 'Upload data?',
        UploadDataPhase.uploading => 'Uploading…',
        UploadDataPhase.done => _resultTitle,
      };

  Widget _body(ThemeData theme, Color accent) {
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    switch (_phase) {
      case UploadDataPhase.confirm:
        return Text(
          widget.confirmMessage ??
              "Send this phone's saved changes to the server. Requests the "
                  'server already has newer data for are skipped.',
          key: const ValueKey('confirm'),
          textAlign: TextAlign.center,
          style: muted,
        );
      case UploadDataPhase.uploading:
        final label = _total == 0
            ? 'Preparing…'
            : _checking
                ? 'Checking with the server…'
                : 'Request ${_done + 1} of $_total';
        return Column(
          key: const ValueKey('uploading'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(label, textAlign: TextAlign.center, style: muted),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: _ringProgress == null
                  ? LinearProgressIndicator(
                      minHeight: 6,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: 0.12),
                    )
                  : TweenAnimationBuilder<double>(
                      tween: Tween(end: _ringProgress),
                      duration: _progressStep,
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: 0.12),
                      ),
                    ),
            ),
          ],
        );
      case UploadDataPhase.done:
        return ConstrainedBox(
          key: const ValueKey('done'),
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Text(
              _resultMessage,
              textAlign: _resultMessage.contains('\n')
                  ? TextAlign.start
                  : TextAlign.center,
              style: muted,
            ),
          ),
        );
    }
  }

  Widget _actions() {
    switch (_phase) {
      case UploadDataPhase.confirm:
        return Row(
          key: const ValueKey('confirm-actions'),
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Iconsax.document_upload, size: 18),
              label: const Text('Upload'),
            ),
          ],
        );
      case UploadDataPhase.uploading:
        // Nothing to press while requests are in flight; the space collapses
        // with the dialog's AnimatedSize.
        return const SizedBox.shrink(key: ValueKey('no-actions'));
      case UploadDataPhase.done:
        return Align(
          key: const ValueKey('done-actions'),
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        );
    }
  }
}

/// Crossfades a child when its key changes, with a slight rise so the new
/// state reads as arriving rather than blinking in.
class _Swap extends StatelessWidget {
  const _Swap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _stateChange,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// The round badge at the top: an empty ring on confirm, a filling progress
/// ring with a rising arrow while uploading, then a full ring and the result
/// icon in the outcome's colour.
class _UploadBadge extends StatelessWidget {
  const _UploadBadge({
    required this.phase,
    required this.progress,
    required this.accent,
    required this.outcome,
  });

  final UploadDataPhase phase;
  final double? progress;
  final Color accent;
  final _Outcome? outcome;

  static const double _size = 76;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: accent),
      duration: _stateChange,
      curve: Curves.easeOutCubic,
      builder: (context, color, _) {
        final tint = color ?? accent;
        return SizedBox.square(
          dimension: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: _ring(tint)),
              Container(
                width: _size - 16,
                height: _size - 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: 0.12),
                ),
              ),
              AnimatedSwitcher(
                duration: _stateChange,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                // Never from scale 0: the icon arrives from 0.8 with a fade.
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: _icon(tint),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(Color tint) {
    final track = tint.withValues(alpha: 0.12);
    if (progress == null) {
      return CircularProgressIndicator(
        strokeWidth: 3,
        color: tint,
        backgroundColor: track,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress),
      duration: _progressStep,
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => CircularProgressIndicator(
        value: value,
        strokeWidth: 3,
        strokeCap: StrokeCap.round,
        color: tint,
        backgroundColor: track,
      ),
    );
  }

  Widget _icon(Color tint) {
    switch (phase) {
      case UploadDataPhase.confirm:
        return Icon(Iconsax.document_upload,
            key: const ValueKey('icon-confirm'), color: tint, size: 30);
      case UploadDataPhase.uploading:
        return _RisingArrow(key: const ValueKey('icon-uploading'), color: tint);
      case UploadDataPhase.done:
        final (icon, key) = switch (outcome) {
          _Outcome.warning => (Iconsax.warning_2, 'icon-warning'),
          _Outcome.failure => (Iconsax.close_circle, 'icon-failure'),
          _ => (Iconsax.tick_circle, 'icon-success'),
        };
        return Icon(icon, key: ValueKey(key), color: tint, size: 32);
    }
  }
}

/// An arrow that rises out of the top of its box while the next one rises in
/// from the bottom: a conveyor that says "sending up" without a spinner.
///
/// Eased in-out because it is on-screen movement, and it rests briefly
/// between strokes so it reads as pulses rather than a blur. With reduced
/// motion the arrow stands still; the progress ring still shows activity.
class _RisingArrow extends StatefulWidget {
  const _RisingArrow({super.key, required this.color});

  final Color color;

  @override
  State<_RisingArrow> createState() => _RisingArrowState();
}

class _RisingArrowState extends State<_RisingArrow>
    with SingleTickerProviderStateMixin {
  static const double _box = 30;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _arrowCycle);

  // The stroke takes the first 70% of the cycle; the rest is a pause.
  final _stroke =
      CurveTween(curve: const Interval(0, 0.7, curve: Curves.easeInOutCubic));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arrow =
        Icon(Icons.arrow_upward_rounded, color: widget.color, size: _box);
    if (MediaQuery.disableAnimationsOf(context)) {
      return SizedBox.square(dimension: _box, child: arrow);
    }
    return SizedBox.square(
      dimension: _box,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final t = _stroke.transform(_controller.value);
            return Stack(
              children: [
                Transform.translate(offset: Offset(0, -_box * t), child: arrow),
                Transform.translate(
                    offset: Offset(0, _box * (1 - t)), child: arrow),
              ],
            );
          },
        ),
      ),
    );
  }
}
