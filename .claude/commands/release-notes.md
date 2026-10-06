---
description: Draft the short chat release announcement for a version (download link only, no change list)
argument-hint: [version]
---

Draft the release announcement for `$ARGUMENTS` (default: the version in `pubspec.yaml`,
`grep '^version:' pubspec.yaml`, without the `+build` suffix).

Launch the `release-scribe` agent and relay its output verbatim in chat. Do not write a file.

The announcement is exactly this, with `<version>` filled in (e.g. `1.1.112`):

```
📱 MDMPI App <version> is now released! @all,

✅ Nothing to set up — just update to the latest build.

Download: https://github.com/strugz/mdmpi_mobile_app/releases/tag/v<version> (download app-release.apk under Assets)
📶 Please download it on the office Wi-Fi so it doesn't use your mobile data.
```

No change cards, feature list, patch notes, or commit summary. Users only need to know a
new build is out and where to get it.
