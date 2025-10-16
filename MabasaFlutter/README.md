# Mabasa Flutter Frontend

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0+)
- Android Studio
- Firebase project configured

### Installation
```bash
cd app/src/MabasaFlutter
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --debug
# or
flutter build apk --release
```

## 📱 Features Implemented

✅ **Authentication Flow**
- Login with role selection (Employee/Employer)
- Registration with form validation
- Firebase Auth integration

✅ **Job Swipe Interface**
- Tinder-like card swiping
- Job details display
- Like/Dislike functionality

✅ **Navigation**
- GoRouter for navigation
- Bottom navigation bar
- Stack navigation

✅ **State Management**
- Riverpod for state management
- Firebase providers

## 🔧 Migration Notes

### Firebase Configuration
- `firebaseConfig.js` → `firebase_options.dart`
- Same Firebase project, different platform configs
- Android app ID needs to be added to Firebase console

### Android Integration
- Flutter app uses same package name: `com.zinosoftware.mabasa`
- Firebase services integrated via Gradle
- Kotlin backend remains unchanged

### File Structure Mapping
```
React Native          →  Flutter
components/          →  shared/widgets/
screens/             →  features/*/presentation/screens/
store/               →  core/providers/
navigation/          →  core/router/
constants/           →  shared/constants/
```

## 🏗️ Architecture

- **State Management**: Riverpod
- **Navigation**: GoRouter 2.0
- **UI**: Material Design 3
- **Backend**: Firebase (same as React Native)
- **Platform**: Flutter (Android APK)

## 📦 Dependencies

- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `flutter_card_swiper` - Job swipe UI
