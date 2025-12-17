# Security: API Key Migration

## What Was Done

✅ **Google Maps API key has been moved from AndroidManifest.xml to local.properties**

### Changes Made:
1. **android/local.properties** - Added `MAPS_API_KEY` (file is already gitignored)
2. **android/app/build.gradle** - Configured to read API key from local.properties and inject into manifest
3. **android/app/src/main/AndroidManifest.xml** - Replaced hardcoded API key with `${mapsApiKey}` placeholder
4. **android/local.properties.example** - Created template file for team members

---

## ⚠️ IMPORTANT: Git History Cleanup Required

The Google Maps API key `AIzaSyCT7YYQC4CNoyAdJXvfzqMxxTW-NggMeCY` is still in Git history. 

### Option 1: Invalidate and Replace the API Key (Recommended)
**Best Practice:** Generate a new API key and invalidate the old one.

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Delete or restrict the old API key: `AIzaSyCT7YYQC4CNoyAdJXvfzqMxxTW-NggMeCY`
3. Generate a new API key
4. Update `android/local.properties` with the new key:
   ```
   MAPS_API_KEY=YOUR_NEW_API_KEY_HERE
   ```
5. Add API restrictions in Google Cloud Console (restrict to your Android app package)

### Option 2: Remove from Git History (Advanced)
**Use with caution:** This rewrites Git history and requires force push.

```powershell
# Using git filter-repo (recommended, install first: pip install git-filter-repo)
git filter-repo --replace-text <(echo "AIzaSyCT7YYQC4CNoyAdJXvfzqMxxTW-NggMeCY==>REDACTED_API_KEY")

# OR using BFG Repo-Cleaner
# Download from: https://rtyley.github.io/bfg-repo-cleaner/
java -jar bfg.jar --replace-text replacements.txt

# After either method:
git push origin --force --all
```

⚠️ **Warning:** Force pushing affects all team members. Coordinate with your team before doing this.

---

## For Team Members

If you pull these changes, create your `android/local.properties` file:

1. Copy `android/local.properties.example` to `android/local.properties`
2. Get the API key from your project lead or Google Cloud Console
3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with the actual key

---

## Files Modified
- `android/app/build.gradle` - Added API key injection
- `android/app/src/main/AndroidManifest.xml` - Uses placeholder variable
- `android/local.properties` - Stores API key (gitignored)
- `android/local.properties.example` - Template for team

## Date: 2025-11-27

