# Pulse Money - Production Release Guide

## Overview

Pulse Money is a premium, offline-first expense tracker with a focus on privacy and security. This guide covers the complete production release setup and deployment process.

## Project Information

- **App Name**: Pulse Money
- **Package Name**: com.pulsemoney.finance
- **Target SDK**: 34 (Android 14)
- **Minimum SDK**: 21 (Android 5.0)
- **Version**: 1.0.0

## Pre-Release Checklist

- [ ] All features tested on physical devices (Android 8+)
- [ ] Permission flows verified
- [ ] Offline functionality confirmed
- [ ] SMS parsing working correctly
- [ ] Analytics crashes fixed
- [ ] Transaction CRUD operations tested
- [ ] Export functionality working
- [ ] Budget management stable
- [ ] UI responsive on various screen sizes
- [ ] Privacy Policy reviewed
- [ ] App icons and branding verified

## Signing Setup

### 1. Generate Signing Keystore

```bash
# Navigate to project root
cd /path/to/Pulse\ Money

# Run the production build setup script
bash scripts/production_build.sh

# Select option 1 to generate keystore
```

Or manually:

```bash
# Create keystore directory
mkdir -p android/keystore

# Generate keystore (valid for 10950 days = 30 years)
keytool -genkey -v -keystore android/keystore/release.jks \
    -keyalg RSA -keysize 4096 -validity 10950 \
    -alias pulse-money-key \
    -storepass YOUR_KEYSTORE_PASSWORD \
    -keypass YOUR_KEY_PASSWORD \
    -dname "CN=Your Name, O=Your Org, C=US"
```

**Important**: Keep these credentials secure!

### 2. Create Environment File

Create `.env.production` in project root:

```bash
KEYSTORE_PATH=android/keystore/release.jks
KEYSTORE_PASSWORD=your_keystore_password
KEY_ALIAS=pulse-money-key
KEY_PASSWORD=your_key_password
```

**CRITICAL**: Add to `.gitignore`:
```
.env.production
android/keystore/release.jks
```

## Build Commands

### Debug Build (for testing)

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Release APK (single file for testing)

```bash
source .env.production
flutter clean
flutter pub get
flutter build apk --release --split-per-abi -v
```

Output: `build/app/outputs/flutter-apk/`

### Release App Bundle (for Google Play)

```bash
source .env.production
flutter clean
flutter pub get
flutter build appbundle --release -v
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Optimized Split APKs (recommended for distribution)

```bash
source .env.production
flutter clean
flutter pub get
flutter build apk --release --split-per-abi \
    --target-platform android-arm64,android-arm -v
```

Outputs:
- `app-arm64-v8a-release.apk` (~25-30 MB)
- `app-armeabi-v7a-release.apk` (~22-25 MB)

## Release Build Configuration

### ProGuard/R8 Obfuscation

The `android/app/proguard-rules.pro` file is configured to:
- Obfuscate app code
- Protect native methods
- Preserve Flutter runtime classes
- Keep database/ORM classes
- Remove logging from release builds

### Binary Size Optimization

1. **Resource Shrinking**: `shrinkResources true`
2. **Code Minification**: `minifyEnabled true`
3. **Split APKs**: Separate builds for ARM64 and ARM32
4. **ABI Filtering**: Only essential ABIs included

Expected sizes:
- ARM64: 28-35 MB
- ARM32: 24-28 MB

## Google Play Store Setup

### 1. Create Google Play Developer Account

1. Visit [Google Play Console](https://play.google.com/console)
2. Complete registration ($25 one-time fee)
3. Verify payment method

### 2. Create App Listing

1. Click "Create app"
2. App name: "Pulse Money"
3. Default language: English
4. App category: Finance
5. Accept declaration checkboxes

### 3. Configure App

**App Content**:
- Content rating: Complete questionnaire
- Target audience: Adults with financial management
- Category: Finance/Business

**Pricing & Distribution**:
- Pricing: Free
- Countries/Regions: All
- Manage Google Play ratings: Enabled

### 4. Prepare Store Listing

**Screenshots** (Required):
- 2-8 screenshots per device type
- Recommended: 1080x1920 (9:16 ratio)
- Show: Dashboard, Analytics, Transactions, Privacy info

**Graphic Assets**:
- App icon: 512x512px (from assets/images/app-logo.png)
- Feature graphic: 1024x500px
- Banner: 1280x720px

**Description**:
```
Pulse Money - Premium Offline Finance Tracker

📊 Smart Expense Tracking
- Automatic transaction detection from bank SMS
- Intelligent expense categorization
- Beautiful analytics and insights

🔒 Privacy First
- 100% offline - no cloud sync
- All data stays on your device
- No ads, no tracking, no servers

📈 Advanced Features
- Budget management with alerts
- Transaction history and search
- Export to Excel
- Multi-currency support

✨ Premium Experience
- Dark theme optimized UI
- Smooth animations
- Responsive design
- No ads or in-app purchases

Your financial data is yours alone.
```

**Release Notes** (for first release):
```
🎉 Pulse Money 1.0.0 - Launch Release

Welcome to Pulse Money, the premium offline expense tracker!

✨ Features:
- Smart SMS-based transaction detection
- Intelligent categorization
- Beautiful analytics
- Budget management
- 100% offline & private

🔒 Privacy Focused:
- All data stays on your device
- No cloud sync
- No tracking
- No ads

Try Pulse Money risk-free - your financial data never leaves your device!
```

### 5. Content Rating Questionnaire

Answer the Google Play content rating form:
- Financial information: Yes
- Uses personal data: Yes (SMS for local processing)
- Collects telemetry: No
- Third-party ads: No
- Other sensitive info: No

Rating: Likely **12+** or **Everyone**

### 6. Upload Build

1. Go to **Release > Production**
2. Create new release
3. Upload APK or App Bundle
4. Add release notes
5. Review and confirm

### 7. Pre-Launch Report

1. Check automated pre-launch report
2. Fix any critical issues
3. Test on provided devices

### 8. Submit for Review

- Review all listing details
- Ensure compliance with Play Store policies
- Click "Submit release"
- Google reviews within 2-4 hours

## Post-Launch Monitoring

### Monitor Key Metrics

1. **Google Play Console**:
   - Crash rate (target: < 1%)
   - ANR rate (target: < 0.5%)
   - Uninstalls
   - Ratings

2. **Performance**:
   - App load time
   - SMS parsing performance
   - Database query times
   - Memory usage

### Handle Issues

**If critical crash found**:
```bash
# Quickly prepare and release a hotfix
flutter build appbundle --release
# Upload new version to Production track immediately
```

**For non-critical issues**:
- Batch fixes into next release
- Use staged rollout (10% → 50% → 100%)

## Version Management

### Versioning Scheme

`MAJOR.MINOR.PATCH+BUILD`

Examples:
- `1.0.0` - Initial release
- `1.0.1` - Hotfix
- `1.1.0` - Minor features
- `2.0.0` - Major redesign

### Update Version

Edit `pubspec.yaml`:
```yaml
version: 1.0.1  # Increment version
```

Edit `android/app/build.gradle.kts`:
- `versionCode` increments by 1
- `versionName` matches pubspec version

## Security Best Practices

1. **Keystore Security**:
   - Store keystore file securely (not in repo)
   - Use strong password (20+ chars)
   - Keep backup of keystore
   - Same keystore for all releases

2. **API Keys** (if any):
   - Never commit to repo
   - Use environment variables
   - Rotate regularly

3. **Permissions**:
   - Only request necessary permissions
   - Current: READ_SMS, RECEIVE_SMS, POST_NOTIFICATIONS
   - No location, contacts, calendar access

4. **Data Security**:
   - Database encryption enabled
   - No sensitive data in logs
   - Clear cache on logout

## Troubleshooting

### Build Fails with Proguard Error

```bash
# Clear build and try again
flutter clean
rm -rf build/
flutter build apk --release
```

### APK Not Installing

```bash
# Check minimum SDK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# If still fails, ensure device is API 21+
adb shell getprop ro.build.version.sdk
```

### SMS Permission Issues

- Check `android/app/src/main/AndroidManifest.xml`
- Verify `READ_SMS` and `RECEIVE_SMS` permissions
- Test permission request flow on Android 8+

### Large APK Size

1. Run `flutter build apk --analyze-size --release`
2. Remove unused dependencies
3. Use split APKs for distribution
4. Enable ProGuard/R8 more aggressively

## Release Checklist

- [ ] Keystore generated and backed up
- [ ] `.env.production` created
- [ ] `.gitignore` includes keystore and env file
- [ ] All tests passing locally
- [ ] Release APK built successfully
- [ ] APK installed and tested on device
- [ ] Google Play Developer account created
- [ ] App listing completed with screenshots
- [ ] Content rating submitted
- [ ] Release notes written
- [ ] Privacy Policy uploaded
- [ ] First build uploaded for review
- [ ] Review passed
- [ ] Release live on Play Store

## Post-Release

### Ongoing Maintenance

1. Monitor crash reports weekly
2. Respond to user reviews
3. Plan feature updates
4. Security updates as needed

### Future Releases

- Always use same keystore
- Increment version code/name
- Test thoroughly before release
- Use staged rollout for major updates

## Support

For issues or questions:
1. Check crash reports in Play Console
2. Review user feedback
3. Test locally on multiple devices
4. Consider beta testing for major updates

---

**Last Updated**: May 26, 2026
**Pulse Money v1.0.0**

