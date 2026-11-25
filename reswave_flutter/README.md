# ResWave — Flutter Application

ResWave is an academic research journey and community mobile/web client built in Flutter & Dart.

## Project Architecture
- `lib/core/`: Application theme, constants, route configuration, matching calculator, and validators.
- `lib/models/`: Strongly-typed data models matching the Cloud Firestore collections (User, ResearchInterest, DomainModel, LearningResource, PaperItem, TeamRequest, Project, MoodEntry, Opportunity).
- `lib/services/`: ResWaveApiService with live backend integration and resilient MockDataSource fallback.
- `lib/screens/`:
  - `auth/`: Welcome, Sign In, Sign Up with role-based registration.
  - `navigation/`: Bottom navigation bar with 5 primary module tabs.
  - `home/`: Home dashboard featuring multi-domain interest cards, stat metrics, and well-being pulse.
  - `research_hub/`: Domain Finder questionnaire with real-time 5-factor scoring.
  - `discover/`: Transparent arithmetic researcher matching, opted-in mentors with remaining capacity, and opportunities.
  - `projects/`: Open team requests with must-have skill badges, applicant review, and private project workspaces.
  - `wellbeing/`: Private mood check-in (100% confidential, owner-only) and emergency crisis hotlines directory.
  - `papers/`: Personal paper library with DOI, reading status, and private notes.

## Running the Flutter App
Ensure the Flutter SDK is installed and run:
```bash
flutter pub get
flutter run
```
To run the Flutter tests:
```bash
flutter test
```
