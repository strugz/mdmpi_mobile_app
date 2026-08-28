import 'dart:io';

/// Increments the build number (the `+n` suffix of `version: x.y.z+n`) in
/// pubspec.yaml. Android maps `n` to versionCode and `x.y.z` to versionName.
///
/// Usage: dart run tool/bump_build_number.dart
/// (normally invoked by build_apk.ps1 rather than by hand)
void main() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    stderr.writeln('pubspec.yaml not found — run from the project root.');
    exitCode = 1;
    return;
  }

  final content = file.readAsStringSync();
  // [ \t]* (not \s*) so the match never swallows the trailing newline or a
  // blank line after the version entry.
  final match =
      RegExp(r'^version:[ \t]*(\d+\.\d+\.\d+)\+(\d+)[ \t]*$', multiLine: true)
          .firstMatch(content);
  if (match == null) {
    stderr.writeln('pubspec.yaml has no "version: x.y.z+n" line to bump.');
    exitCode = 1;
    return;
  }

  final name = match.group(1)!;
  final current = int.parse(match.group(2)!);
  final next = current + 1;
  file.writeAsStringSync(
    content.replaceRange(match.start, match.end, 'version: $name+$next'),
  );
  stdout.writeln('pubspec version: $name+$current -> $name+$next');
}
