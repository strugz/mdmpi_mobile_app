---
description: Build the release APK with the required JDK/Gradle environment workarounds and report the output path
argument-hint: [--debug]
allowed-tools: Bash(flutter build apk:*), Bash(flutter --version:*), Bash(flutter config:*), Bash(grep:*)
---

Build the Android APK. Mode: release unless `$ARGUMENTS` contains `--debug`.

Run in PowerShell:

```powershell
$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=C:\Users\Public"
flutter build apk --release
```

Notes:
- The project is pinned to Temurin JDK 21 via `flutter config --jdk-dir`; if Gradle complains about Java 25, check `flutter config` output and stop rather than changing the JDK.
- If `adb` misbehaves, ASUS GlideX may hold port 5037: `adb kill-server` then start the SDK adb.
- Do not run `flutter build windows` here; it is blocked by pre-existing FileTracker/MAX_PATH issues.

Report:
- version from `pubspec.yaml`,
- the APK path (`build/app/outputs/flutter-apk/app-release.apk`) and size,
- any Gradle warnings that are new.

Do not copy the APK anywhere and do not commit. Sharing goes to the MDMPIAPP Google Drive folder and `\\192.168.4.118\Forms\MDMPIAPP`; the user does that step.
