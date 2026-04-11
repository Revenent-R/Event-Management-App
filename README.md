# 📅 Event Manager – Smart College Event Platform

A modern Flutter-based platform designed to centralize and simplify college event management for both students and organizers.

---

## 🧠 Problem Statement

College events are often scattered across:

* WhatsApp groups
* Posters
* Word-of-mouth

This leads to:

* Students missing important events
* Low participation rates
* Organizers struggling with visibility

---

## 💡 Solution

**Event Manager** provides a centralized platform where:

* 🏢 Clubs can create and manage events
* 👤 Students can discover and enroll in events
* 📆 Events are visualized through a smart calendar
* 🔄 Data is synced in real-time using Firebase

---

## 🚀 Features

### 👤 User Features

* Secure registration & login
* Interactive calendar view
* Event enrollment system
* Organization-based filtering
* Detailed event view

### 🏢 Organizer Features

* Organization registration
* Event creation & publishing
* Event deletion & management
* Role-based access control

---

## 🔐 Security First Approach

* Firebase Authentication
* Role-based access (Admin / User)
* Secure token validation
* Firestore-based access control

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase (Auth + Firestore)
* **API:** Custom role management backend
* **UI:** Material Design

---

## 📂 Project Structure

```id="p4g7sn"
Event-Management-App/
├── docs/
├── my_flutter_app/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
└── README.md
```

---

## ⚙️ Setup Instructions

### 1. Clone the repository

```id="0gq2qg"
git clone https://github.com/Revenent-R/Event-Management-App.git
cd Event-Management-App/my_flutter_app
```

### 2. Install dependencies

```id="l7m8m1"
flutter pub get
```

### 3. Run the app

```id="f7m4vx"
flutter run
```

---

## 🔑 Firebase Setup

* Create a Firebase project
* Enable Email/Password Authentication
* Enable Firestore Database
* Add config files:

    * `google-services.json` (Android)
    * `GoogleService-Info.plist` (iOS)

---

## 📌 Current Status

This repository now includes:

* ✅ Functional Flutter application
* ✅ Authentication system (Admin/User)
* ✅ Event creation & management
* ✅ Calendar-based event UI
* ✅ Firestore integration

---

## 🚀 Future Improvements

* 🔔 Push notifications
* 🎟️ Event booking / ticket system
* 📡 Real-time updates (Streams)
* 🖼️ Event image uploads
* 🔍 Advanced search & filters

---

## 🤝 Contributing

Contributions are welcome! Fork the repo and submit a pull request.

---

## 👨‍💻 Author

**Arshad Khan**

---

⭐ If you like this project, consider giving it a star on GitHub!
