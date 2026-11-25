# ResWave — Academic Research Journey & Community Application
**Version 2.0 | Complete Technical Implementation**

ResWave empowers researchers, active students, PhD scholars, and professors to explore cross-disciplinary research domains, match with peers and mentors through transparent arithmetic algorithms, collaborate in private team workspaces, manage academic papers, and access peer well-being support.

---

## 📁 Repository Structure
```
reswave/
├── firebase/
│   ├── firestore.rules           # Security rules for all 24 Firestore collections
│   ├── storage.rules             # File & avatar storage authorization rules
│   ├── firebase.json             # Firebase configuration & emulator ports
│   └── firestore.indexes.json    # Composite indexes for queries
├── reswave_backend/
│   ├── app/                      # Full production FastAPI Cloud Run package
│   │   ├── main.py               # REST API endpoints & dependency injection
│   │   ├── models/schemas.py     # Pydantic data models & request/response schemas
│   │   ├── services/
│   │   │   ├── domain_finder.py  # 5-factor deterministic questionnaire scoring
│   │   │   ├── matching_engine.py# Arithmetic researcher & teammate matching
│   │   │   └── seed_data.py      # Seed taxonomy, learning guides & opportunities
│   │   └── core/memory_db.py     # Core data engine with referential integrity
│   ├── server.py                 # Standalone zero-dependency Python server & web host
│   ├── requirements.txt          # Production dependencies
│   └── Dockerfile                # Container build for Cloud Run deployment
├── reswave_flutter/
│   ├── lib/
│   │   ├── main.dart             # Flutter app entry point
│   │   ├── core/                 # Themes, colors, routes, matching calculators
│   │   ├── models/               # Strongly-typed Dart data models
│   │   ├── services/             # API client with resilient mock fallback
│   │   └── screens/              # Auth, Onboarding, Discover, Teams, Hub, Wellbeing
│   └── pubspec.yaml              # Flutter dependencies & metadata
├── reswave_web/
│   ├── index.html                # Responsive web app & testing interface
│   ├── app.js                    # Complete REST client & interactive workflows
│   └── styles.css                # Academic UI design system
├── test_runner.py                # Automated Section 19 acceptance test suite
├── SPEC_COMPLIANCE.md            # Point-by-point specification verification matrix
└── package_zip.py                # Build script generating reswave_full_code.zip
```

---

## 🚀 Quick Start: Run the Interactive Web & API Server
You can launch the complete ResWave application and interactive client immediately using the built-in Python runner without installing external third-party dependencies:

1. Open PowerShell or Terminal and navigate to the project root:
   ```bash
   cd C:\Users\MKG\.gemini\antigravity\scratch\reswave
   ```
2. Start the ResWave standalone server:
   ```bash
   python reswave_backend/server.py 8000
   ```
3. Open your browser to **`http://localhost:8000`** to interact with all screens:
   - **Research Domain Finder**: Answer the 7 questions and preview the 5-factor scoring engine in real time.
   - **Multi-Domain Focus**: Save and manage multiple research interests across HCI, AI, and Psychology.
   - **Researcher & Mentor Matching**: Explore explainable matching breakdown with opted-in mentors.
   - **Team Collaboration Workspace**: Form teams, review applicants, and test transactional capacity deduction.
   - **Personal Paper Library**: Add papers with DOI and record private confidential notes.
   - **Well-Being Hub**: Check in privately (100% confidential, owner-only) and view emergency support hotlines.

---

## 🧪 Run Acceptance Tests
The repository includes automated verification for all 14 criteria in Section 19 of the specification:
```bash
python test_runner.py
```
*Output: All 14 tests run and pass in milliseconds.*

---

## 📱 Running the Flutter Mobile App
To run the native mobile client:
```bash
cd reswave_flutter
flutter pub get
flutter run
```

---

## ☁️ Deployment Guides

### 1. Cloud Firestore & Storage Rules
To deploy Firebase security rules:
```bash
cd firebase
firebase deploy --only firestore:rules,storage
```

### 2. FastAPI Backend to Google Cloud Run
Build and deploy the containerized service:
```bash
cd reswave_backend
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/reswave-api
gcloud run deploy reswave-api \
  --image gcr.io/YOUR_PROJECT_ID/reswave-api \
  --platform managed \
  --allow-unauthenticated \
  --region us-central1
```

---

## 🔒 Security & Privacy Guarantees
- **Private Mood Records**: Stored separately in `moodEntries` and restricted strictly to the user (`owner-only`). Private mood entries are never queried during matching or included in platform analytics.
- **Paper Library Private Notes**: Only accessible by the individual researcher.
- **Admin Isolation**: Admin accounts cannot be self-assigned during signup and are provisioned strictly via server-side custom claims.
- **Project Membership**: Tasks, files, and discussion threads are locked to accepted project members only.
