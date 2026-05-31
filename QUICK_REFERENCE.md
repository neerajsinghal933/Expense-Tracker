# 🚀 PULSE MONEY - QUICK REFERENCE CARD

## App Information
- **Name**: Pulse Money ✅
- **Package**: com.pulsemoney.finance ✅
- **Version**: 1.0.0 ✅
- **Min SDK**: 21 (Android 5.0) ✅
- **Target SDK**: 34 (Android 14) ✅

---

## Critical Commands

### Test Locally
```bash
cd "/Users/neerajsinghal/Desktop/Projects/Expense Tracker"
flutter clean && flutter pub get
flutter run
```

### Setup Signing
```bash
bash scripts/production_build.sh
# Follow prompts - creates .env.production
```

### Build Release
```bash
source .env.production
flutter build appbundle --release -v
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build Split APKs
```bash
source .env.production
flutter build apk --release --split-per-abi -v
# Outputs: app-arm64-v8a-release.apk, app-armeabi-v7a-release.apk
```

---

## Key Files

### Documentation
- 📖 **START_HERE.md** ← Read this first!
- 📖 **PRODUCTION_RELEASE_GUIDE.md**
- 📖 **BUILD_COMMANDS.md**
- 📖 **README.md**

### Important Code
- 🔐 Permission onboarding: `lib/features/onboarding/permission_onboarding_dialog.dart`
- 🛡️ Privacy screens: `lib/features/profile/privacy_policy_screen.dart`
- 🎨 Theme: `lib/core/theme/app_theme.dart`

### Build Config
- 📦 Signing: `android/app/build.gradle.kts`
- 📋 Manifest: `android/app/src/main/AndroidManifest.xml`
- 🛡️ ProGuard: `android/app/proguard-rules.pro`

---

## What's New

✅ Smart permission onboarding (not forced on launch)  
✅ Privacy Policy & Data Usage screens  
✅ Enhanced Material 3 theme  
✅ Professional branding (Pulse Money)  
✅ Release build configuration  
✅ ProGuard/R8 obfuscation  
✅ Split APK builds  
✅ Comprehensive documentation  

---

## Permissions

**3 Optional Permissions:**
- READ_SMS (for transaction detection)
- RECEIVE_SMS (for background handling)
- POST_NOTIFICATIONS (for alerts)

**NOT Forced:** User sees beautiful explanation dialog after profile setup

---

## Timeline

| Step | Time | Action |
|------|------|--------|
| 1 | 5-10 min | Local testing |
| 2 | 5-10 min | Setup signing |
| 3 | 2-3 min | Build release |
| 4 | 5 min | Create Play Store account |
| 5 | 15-20 min | Prepare store listing |
| 6 | 1 click | Submit for review |
| 7 | 2-4 hrs | Google review |
| **Total** | **~1-2 hrs** | **Ready to launch!** |

---

## Security Notes

⚠️ Keep keystore safe (backup locations)  
⚠️ Use SAME keystore for all releases  
⚠️ Don't commit .env.production (already .gitignored)  
⚠️ Backup encryption credentials  

---

## Status

✅ **PRODUCTION READY**
- All features implemented
- No breaking changes
- Ready for Play Store
- Comprehensive docs included

---

## Next Steps

1. Read **START_HERE.md**
2. Run local tests
3. Setup signing
4. Build & submit
5. Done! 🎉

---

**Pulse Money v1.0.0 - Ready for Launch** 🚀

