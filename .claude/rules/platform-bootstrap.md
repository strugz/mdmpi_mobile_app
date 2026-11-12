---
paths:
  - "lib/main.dart"
  - "lib/base/utils/platform_init.dart"
  - "lib/splash_screen.dart"
  - "android/**"
  - "windows/**"
---

# Platform bootstrap & native targets

- `main.dart` + `platform_init.dart` own early startup: `.env` load, sqflite FFI on desktop,
  conditional Firebase init, eager `Get.put` of `PermissionService`, `NotificationService`,
  and `AuthenticationRepository` (Firebase only).
- Permissions split: Android requests `storage`, `location`, `camera`, `sms`; desktop/web only
  `location` and `camera`. Keep new permission flows aligned.
- App folder: `/storage/emulated/0/MDMPIAPP` on Android, the app documents dir on desktop.
- Anything Firebase-dependent must be behind `Firebase.apps.isNotEmpty`.
- Gradle: 9.5.0 with AGP 9.3.1 and Kotlin 2.4.20, which needs Flutter 3.50.0. Keep
  `android.builtInKotlin=false` and `android.newDsl=false` in `android/gradle.properties`:
  several plugins (`another_telephony` among them) still apply the Kotlin plugin themselves.
  Two more AGP 9 workarounds stay until those plugins catch up:
  `kotlin.jvm.target.validation.mode=warning` (another_telephony's JVM 1.8 Kotlin target) and
  the `aarMetadata.minCompileSdk = 34` hook in `android/build.gradle` (plugins still on compileSdk 34).
  `android/app/build.gradle` sets `androidResources.ignoreAssetsPattern` without `.*`: AGP 9 otherwise
  drops `.env` from the APK and the app fails at `dotenv.load`. After a toolchain change, check
  `unzip -l app-release.apk | grep flutter_assets/.env`.
  The project is pinned to Temurin JDK 21 via `flutter config --jdk-dir`. Set
  `$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=C:\Users\Public"` before any Gradle command.
- Windows build: set `$env:TRACKFILEACCESS = "false"` to avoid MAX_PATH/FileTracker failures.
- `adb` port 5037 may be hijacked by ASUS GlideX: `adb kill-server`, then start the SDK adb.
- Never edit `firebase_options.dart` by hand; regenerate with the FlutterFire CLI.
