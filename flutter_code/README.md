# 📱 Event Manager – Flutter Application

This directory contains the Flutter mobile application for the **Event Manager** platform.

---

## 🧰 Tech Stack

* Flutter (Dart)
* Firebase Authentication
* Cloud Firestore
* HTTP API (Role management)

---

## 🚀 Getting Started

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run the app

```bash
flutter run
```

---

## 🔑 Firebase Configuration

Before running the app:

1. Create a Firebase project

2. Enable:

    * Email/Password Authentication
    * Cloud Firestore

3. Add configuration files:

    * `android/app/google-services.json`
    * `ios/Runner/GoogleService-Info.plist`

---

## 📂 Folder Structure

```bash
lib/
 ├── main.dart              # App entry point
 ├── authCheck.dart         # Auth state handling
 ├── homepage.dart          # Main calendar UI
 ├── event_creation.dart    # Event creation
 ├── admin_login.dart
 ├── user_login.dart
 ├── admin_registration.dart
 ├── user_registration.dart
 └── size_config.dart
```

---

## 🔐 Authentication Flow

* Firebase Authentication is used for login/signup

* Custom backend assigns roles:

    * Admin (Organizers)
    * User (Students)

* Role is verified using Firebase ID tokens

---

## 📡 Backend Integration

The app communicates with a backend API for:

* Role assignment
* Token refresh

---

## ⚠️ Notes

* Ensure Firebase is properly configured before running
* Internet connection is required
* Do not commit Firebase config files in public repos

---

## 🧪 Development Status

* Core features implemented
* UI and logic stable
* Ready for feature expansion

---

## 👨‍💻 Developer

Arshad Khan
