ETHIO🛍 Full Combined Package

Contents:
- flutter/: Flutter app core (lib, pubspec)
- functions/: Firebase Cloud Functions (index.js)
- firebase/firestore.rules: Firestore security rules
- .github/workflows/android-release.yml: CI for building & uploading AAB (fastlane)
- android/fastlane/: fastlane config
- admin/: Admin panel scaffold (React + Vite)
- playstore/: Play Store copy text files
- flutter/assets/lottie/ethio_splash.json: placeholder Lottie JSON

How to use:
1. Unzip this package.
2. For Flutter:
   - Copy flutter/ folder into your project (or open it).
   - Put your google-services.json into flutter/android/app/
   - Run `flutter pub get` inside flutter/
   - Run on device/emulator

3. For Cloud Functions:
   - cd functions && npm install
   - Deploy with `firebase deploy --only functions` (requires firebase-tools and auth)

4. For Admin panel:
   - cd admin && npm install && npm run dev
   - Update firebase client config in admin/src

5. CI:
   - Add required GitHub secrets (PLAY_STORE_JSON, KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD)
   - Push main branch to trigger workflow

Note: This is a starter combined package. You'll need to replace placeholder config and refine rules and UI before production.
