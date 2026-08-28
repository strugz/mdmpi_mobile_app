# Bumps the pubspec build number (+1), then builds the release APK.
# Extra arguments pass through to `flutter build apk`, e.g.:
#   .\build_apk.ps1 --split-per-abi
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

dart run tool/bump_build_number.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Gradle workaround on this machine: JDK unix-domain-socket temp dir must be
# short/writable or the daemon fails to start (see AGENTS.md build notes).
$env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=C:\Users\Public'

flutter build apk @args
exit $LASTEXITCODE
