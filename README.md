# 🏥 MediSync — Client Application

MediSync is a personal AI medical assistant and clinical ecosystem client built with **Flutter** (Web, Mobile, Desktop).

Designed with a **Clinical Minimalism + Ambient Intelligence** aesthetic:
- **Palette**: Deep Teal (`#176B67`), Warm Off-White (`#F7F8F5`), Soft Sage (`#DCEBE3`), and accessible status indicators.
- **Typography**: Manrope with tabular number figures for biomarker measurements and clinical analytics.
- **Safety**: Non-diagnostic safety protocols with contextual clinical disclaimers.

---

## 🌟 Architecture & Capabilities

### 1. Role-Based Access & Navigation
- **Patient Portal (Default)**: Dedicated personal health records vault, conversational AI health assistant, appointment booking, and hospital pairing.
- **Doctor Portal**: Clinical consultation queue, schedule and availability management (marking off dates/hours), and secure patient chart decryption via QR tokens.
- **Authentication**: Role-specific login with instant toggle ("Are you a doctor?"), demo quick-fill credentials, and offline fallback mode.

### 2. Layer 1 — Personal AI Health Assistant & Vault
- **Central Records Vault**: Centralized storage for medical reports (CBC, Lipid, Metabolic panels) with longitudinal health trend line charts and biomarker status chips (Normal, High, Low, Borderline).
- **Conversational AI Assistant**: RAG-augmented medical assistant with clinical citations, suggested inquiry prompts, and disclaimer banners.

### 3. Layer 2 — Doctor-Patient Ecosystem
- **Appointment Scheduling**: Search verified specialists (Cardiology, Endocrinology, Internal Medicine), view doctor availability, and book appointments.
- **Cryptographic Record Sharing**: Generate temporary, secure QR access tokens (JWT) to share specific health records with attending physicians.
- **Doctor Consultation Management**: Review patient queue, inspect shared charts, record consultation notes, and author digital prescriptions.
- **Doctor Schedule Management**: Configure weekly working days, consultation hours, and designate specific unavailable/off dates.

### 4. Layer 3 — Hospital Administration Client
- Dedicated client connection to hospital administration systems for admissions, records synchronization, and telemetry.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.14.0 or higher)
- Chrome / Web browser or Android/Linux desktop target

### Installation & Run

```bash
# Clone the repository
git clone https://github.com/MediSync-ProjeKt/MediSync-Client.git
cd MediSync-Client

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Or build for production web
flutter build web --release
```

---

## 🧪 Testing & Verification

```bash
# Static analysis
flutter analyze

# Unit & Widget tests
flutter test
```
