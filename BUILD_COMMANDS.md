# Pulse Money - Build Commands Reference

## Quick Commands

### Development/Debug Build
```bash
flutter clean && flutter pub get
flutter run -v
# or
flutter build apk --debug
```

### Release APK (Testing)
```bash
source .env.production
flutter clean && flutter pub get
flutter build apk --release --split-per-abi -v
# Output: build/app/outputs/flutter-apk/
```

### Release App Bundle (Google Play)
```bash
source .env.production
flutter clean && flutter pub get
flutter build appbundle --release -v
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Split APKs (Recommended for Distribution)
```bash
source .env.production
flutter clean && flutter pub get
flutter build apk --release --split-per-abi \
    --target-platform android-arm64,android-arm -v
# Output: 
#   - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
#   - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

### Analyze APK Size
```bash
flutter build apk --release --analyze-size --split-per-abi
```

### Install Release APK on Device
```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# or for 32-bit
adb install -r build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

### Generate Key Hash (for Play Store)
```bash
# View certificate details
keytool -list -v -keystore android/keystore/release.jks \
    -alias pulse-money-key \
    -storepass YOUR_PASSWORD \
    -keypass YOUR_PASSWORD
```

## Environment Setup

### First Time Setup
```bash
# 1. Navigate to project
cd /path/to/Pulse\ Money

# 2. Install dependencies
flutter pub get

# 3. Run production build script
bash scripts/production_build.sh

# 4. Select option 1 or 2 to setup signing
# This creates .env.production

# 5. Verify keystore exists
ls android/keystore/release.jks
```

### One-Time Keystore Generation
```bash
# If you already have .env.production, skip this

keytool -genkey -v -keystore android/keystore/release.jks \
    -keyalg RSA -keysize 4096 -validity 10950 \
    -alias pulse-money-key \
    -storepass your_keystore_password \
    -keypass your_key_password \
    -dname "CN=Your Name, O=Your Org, C=US"

# Then create .env.production with the password
```

## Environment Variables

### .env.production Template
```bash
# Production signing credentials (KEEP SECRET!)
KEYSTORE_PATH=android/keystore/release.jks
KEYSTORE_PASSWORD=your_password_here
KEY_ALIAS=pulse-money-key
KEY_PASSWORD=your_password_here
```

**IMPORTANT**: 
- Add to `.gitignore`
- Never commit to repository
- Keep backup in secure location
- Use strong passwords (20+ characters)

## Troubleshooting Commands

### Clean Build (resolves most issues)
```bash
flutter clean
rm -rf build/
rm -rf pubspec.lock
flutter pub get
flutter build apk --release
```

### Check Device SDK Level
```bash
adb shell getprop ro.build.version.sdk
# Must be 21 or higher
```

### View App Logs
```bash
adb logcat | grep flutter
# or
adb logcat -s flutter
```

### View Crash Logs
```bash
adb logcat -s AndroidRuntime
```

### Uninstall Previous Version
```bash
adb uninstall com.pulsemoney.finance
```

### Install and Run Immediately
```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
adb shell am start -n com.pulsemoney.finance/.MainActivity
```

## Size Optimization

### Check Build Size Breakdown
```bash
flutter build apk --release --analyze-size --split-per-abi
```

### Expected Sizes
- ARM64: 28-35 MB
- ARM32: 24-28 MB
- App Bundle: 20-25 MB

## Performance Profiling

### Run with Performance Monitoring
```bash
flutter run --profile -v
```

### Generate Performance Report
```bash
flutter build apk --profile --split-per-abi
```

## Version Management

### Update Version in pubspec.yaml
```yaml
# Current version
version: 1.0.0

# For next release
version: 1.0.1  # or 1.1.0 for minor feature
```

### Update Version Code in gradle
```kotlin
// In android/app/build.gradle.kts
defaultConfig {
    versionCode = flutter.versionCode  // Auto-incremented
    versionName = flutter.versionName  // Matches pubspec
}
```

## Release Flow Summary

1. **Update version**: `pubspec.yaml` and `build.gradle.kts`
2. **Test locally**: `flutter run --release`
3. **Build**: `source .env.production && flutter build appbundle --release`
4. **Upload**: Google Play Console > Create Release
5. **Review**: 2-4 hours
6. **Publish**: Release to Production track

---

**Last Updated**: May 26, 2026

