import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/app_build_info.dart';

/// A small muted "Version 1.1.112 (245)" line, for places where someone may
/// need to read the version out loud — e.g. the login screen, when they
/// cannot get further.
///
/// The build is normally read during the splash ([BAppBuildInfo.warmUp]), so
/// the line is simply there on the first frame. If it is not ready yet, the
/// line keeps its height and fades in, so the form above never jumps. If the
/// version cannot be read at all, the line stays blank.
class BAppVersionText extends StatelessWidget {
  const BAppVersionText({super.key, this.textAlign = TextAlign.center});

  final TextAlign textAlign;

  /// Strong ease-out: the text is visible almost at once, then settles.
  static const Curve _curve = Cubic(0.23, 1, 0.32, 1);
  static const Duration _fade = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      // Digits keep their width, so 1.1.111 and 1.1.112 line up the same.
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return FutureBuilder<AppBuildInfo>(
      future: BAppBuildInfo.current(),
      initialData: BAppBuildInfo.cached,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final known = info != null && info.hasVersion;
        return AnimatedOpacity(
          opacity: known ? 1 : 0,
          duration:
              MediaQuery.disableAnimationsOf(context) ? Duration.zero : _fade,
          curve: _curve,
          // A blank line holds the space until the version arrives.
          child: Text(
            known ? 'Version ${info.label}' : ' ',
            key: known ? const ValueKey('app-version-text') : null,
            textAlign: textAlign,
            style: style,
          ),
        );
      },
    );
  }
}
