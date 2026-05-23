# 🎯 TemanNetra

[![Flutter Version](https://img.shields.io/badge/Flutter-3.44.0-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.12.0-blue.svg)](https://dart.dev)
[![Firebase Supported](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-orange.svg)](https://firebase.google.com)
[![SDG Focus](https://img.shields.io/badge/SDG-10%20%26%208-green.svg)](https://sdgs.un.org/goals)

**TemanNetra** is a production-grade, highly accessible mobile application developed as a collaborative Final Project for the **Mobile Programming (Pemrograman Perangkat Bergerak / PPB - E)** course. 

The application serves as an inclusive digital bridge connecting visually impaired individuals (*tunanetra/low vision*) with automated AI vision tools and a network of volunteer helpers.

---

## 🏛️ Project Identity & SDG Alignment
* **Integration Topic**: Inclusive Human-Computer UI/UX Interface for the Visually Impaired.
* **SDG Target**: 
  * **SDG 10 (Reduced Inequalities)**: Empowering individuals with physical disabilities to interact independently in daily life.
  * **SDG 8 (Decent Work & Economic Growth)**: Opening voluntary crowdsourced coordination systems to promote social integration.
* **Target Audience**: Low Vision & Totally Blind Individuals (associated with Komunitas Mata Hati Surabaya) and Volunteers.

---

## 👥 Development Team & CRUD Matrix
The application is structured around a rigorous **Feature-First / Domain-Driven Design (DDD)** pattern, separating individual CRUD fungsionalitas linked securely to Cloud Firestore and Firebase Storage:

### 👤 Member 1: Naswan Nashir (NRP 5025231219)
**Module**: Tunanetra Visual Request & AI Assistant (Client Modul)
* **Create**: CAPTURE a photo/audio request via custom camera, then execute local automated text/label recognition using the **Gemini Vision API** OR upload it as a "Help Ticket" in Cloud Firestore.
* **Read**: RENDER and voice out history log of personal requests through a clean *Text-To-Speech* engine.
* **Update**: MODIFY details of active tickets or re-trigger automated AI evaluations.
* **Delete**: DISCARD completed/private tickets from Cloud Firestore and Firebase Storage for user privacy.

### 👤 Member 2: Sultan Alif (NRP 5025231246)
**Module**: Volunteer Coordination Dashboard & Communication (Volunteer Modul)
* **Create**: RECORD and upload a voice message (*voice note*) response, linking the audio file to Firebase Storage.
* **Read**: SEARCH, filter, and stream active, unresolved tickets submitted by nearby visually impaired users real-time.
* **Update**: CLAIM and update ticket status (*Pending* ➡️ *In Progress* ➡️ *Completed*).
* **Delete**: CANCEL active claims before completion if a volunteer encounters unexpected issues.

---

## ♿ Accessibility Compliance (WCAG 2.2 Standards)
To satisfy rigorous accessibility guidelines, TemanNetra implements the following core standards:
1. **Semantic Accessibility Wrapper**: Every single interaction layer is wrapped inside Flutter's `Semantics` widget to deliver clear contextual prompts to screen readers (**Google TalkBack** and **iOS VoiceOver**).
2. **High-Contrast Theme System**: Supports black-background modes with strong bright gold accentuation (`#FFFFD700`) resulting in a contrast ratio minimum of 7:1 for low-vision accessibility.
3. **Padded Tap Targets**: Interactive components maintain a minimum padding size of **64x64 dp** to avoid target miss-clicks.
4. **Haptic & Sound Indicators**: Pushes taktil feedback (short vibrations) and system sounds upon successful asynchronous actions (e.g., ticket claims, AI processing).

---

## 🔌 Architecture & Core Tech Stack
* **State Management**: `flutter_riverpod` & `riverpod_annotation` (with automated code generation via `build_runner`).
* **Cloud Services**: Firebase Authentication (Multirole Sign-In), Cloud Firestore (Real-time syncing), Firebase Storage (Media hosting), and Firebase Cloud Messaging (FCM for push notifications).
* **Automated AI Service**: **Gemini Developer API (Vision & Text API)** for instant OCR and image scene descriptions.

---

## 🛠️ Local Development Setup

Because this is a public repository containing strict environment isolation, raw configuration files are excluded via `.gitignore`. Follow these setup steps to run the application locally:

### 1. Clone the Repository
```bash
git clone https://github.com/re1c/TemanNetra.git
cd TemanNetra
```

### 2. Configure Firebase Credentials
Ask your team lead for the credentials and place them in:
* **Android**: `/android/app/google-services.json`
* **iOS**: `/ios/Runner/GoogleService-Info.plist`

### 3. Setup Gemini API Key
Create a `.env` file in the root directory and add your Gemini Developer API Key:
```properties
GEMINI_API_KEY=your_gemini_api_key_here
```

### 4. Fetch Dependencies & Run Code Generator
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 5. Run the Application
```bash
flutter run
```
