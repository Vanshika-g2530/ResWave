# ResWave
### Discover. Connect. Collaborate. Grow.

**An Academic Research Journey and Collaboration Platform**

ResWave is a research-focused digital ecosystem designed to bring students, researchers, PhD scholars and faculty members together. It aims to make academic research more accessible by connecting research discovery, mentorship, intelligent researcher matching, team collaboration, academic opportunities and peer well-being in one platform.

Whether someone is exploring their first research interest, searching for a mentor, building an interdisciplinary research team or managing an academic project, ResWave aims to support every stage of their research journey.

> Research should not be a journey people have to navigate alone.

---

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Our Approach](#our-approach)
- [Key Features](#key-features)
- [Researcher Matching Engine](#researcher-matching-engine)
- [Technology Stack](#technology-stack)
- [System Architecture](#system-architecture)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Running the Application](#running-the-application)
- [Testing](#testing)
- [Security and Privacy](#security-and-privacy)
- [Deployment](#deployment)
- [Future Scope](#future-scope)
- [Contributing](#contributing)
- [Project Creator and Credits](#project-creator-and-credits)

---

## Overview

The academic research ecosystem is spread across multiple platforms. Finding research guidance, discovering collaborators, organising academic resources and managing research projects can require users to navigate several disconnected tools.

ResWave explores a unified approach by bringing these activities into one research-focused environment.

### Target Audience

- Undergraduate students exploring research for the first time.
- Postgraduate students working on academic projects.
- PhD scholars seeking collaborators and research communities.
- Professors and faculty members interested in academic networking and mentorship.
- Researchers working across multiple disciplines.

### Our Vision

To build an inclusive research community where curiosity leads to discovery, discovery leads to collaboration, and collaboration leads to meaningful academic outcomes.

---

## Problem Statement

Starting and pursuing academic research can involve several challenges:

- Research Discovery: Beginners often struggle to identify suitable research domains and understand where to start.
- Limited Mentorship: Finding appropriate academic guidance can be difficult.
- Researcher Compatibility: Finding collaborators with complementary skills, interests and research goals is challenging.
- Fragmented Collaboration: Research discussions, team formation and project management often happen across disconnected platforms.
- Academic Information Overload: Discovering useful papers, learning resources and opportunities takes time.
- Research Well-being: Academic pressure, isolation and research-related stress can affect the overall research experience.

### Our Approach

ResWave aims to connect these activities through a continuous research journey.

| Stage | Purpose |
|---|---|
| Discover | Explore research domains, interests and learning resources. |
| Connect | Find researchers, mentors and people with complementary interests. |
| Collaborate | Form research teams and manage academic projects. |
| Explore Opportunities | Discover conferences, workshops and academic opportunities. |
| Stay Supported | Access peer communities and well-being resources. |

---

## Key Features

### 1. Researcher Profiles

Create a personalised academic identity that represents research interests, skills and experience.

- Multiple research interests and domains.
- Research skills and methodologies.
- Academic background and experience.
- Research goals and collaboration preferences.
- Availability and profile visibility settings.
- Editable research profile.

### 2. Research Domain Finder

A guided discovery experience for students who want to explore research but are unsure where to begin.

- Interest-based questionnaire.
- Research preference assessment.
- Multi-factor domain scoring.
- Ranked research-domain recommendations.
- Explanations for suggested domains.

### 3. Smart Researcher Matching

Discover researchers based on research compatibility rather than just general profile similarity.

The recommendation engine considers:

- Research interest compatibility.
- Research goals.
- Skills and expertise.
- Research methodologies.
- Experience compatibility.
- Availability.

Recommendations are designed to include compatibility scores and explanations of the contributing factors.

### 4. Mentor Discovery

Find potential academic mentors based on research expertise and mentoring preferences.

- Mentor profiles.
- Areas of research expertise.
- Mentoring preferences.
- Mentor-mentee requests.
- Request acceptance and rejection workflows.
- Compatibility-based recommendations.

### 5. Find Teammates

Build interdisciplinary research teams by finding people with complementary skills.

- Create research project requests.
- Define required roles and skills.
- Specify team size and capacity.
- Receive applications.
- Review and accept applicants.
- Form project teams.

### 6. Research Collaboration Workspace

Manage research activities within a shared project environment.

- Project creation and management.
- Team membership.
- Task creation and assignment.
- Task status tracking.
- Project milestones.
- File sharing.
- Team discussions.
- Progress updates.

### 7. Research Learning Hub

A learning environment for students and researchers who want to strengthen their research knowledge.

Learning areas include:

- Research methodology.
- Literature reviews.
- Academic writing.
- Research ethics.
- Data collection and analysis.
- Citation and referencing.

Users can access learning resources, bookmark content and track progress.

### 8. Personal Research Paper Library

Organise academic literature in one place.

- Add research papers manually.
- Store titles and authors.
- Save DOI and external links.
- Categorise papers by research domain.
- Maintain personal notes.
- Track reading status.

### 9. Academic Opportunities

Explore academic activities and opportunities relevant to research interests.

- Conferences.
- Workshops.
- Webinars.
- Research competitions.
- Academic events.
- Research internships.
- Calls for papers.

Listings can include event dates, submission deadlines, location, organisers and official registration links.

### 10. Academic Networking

Build meaningful academic connections.

- Research-focused feed.
- Academic posts.
- User connections.
- Research groups.
- Direct messaging.
- Notifications.

### 11. Researcher Well-being

ResWave recognises that research progress and personal well-being are connected.

**Mood Check-ins**

- Record personal mood.
- Add optional private notes.
- View mood history.

**Peer Support Community**

- Discuss research-related challenges.
- Share personal experiences.
- Connect with fellow researchers.
- Participate in moderated discussions.

**Well-being Resources**

- Breathing exercises.
- Grounding activities.
- Journaling prompts.
- Break reminders.

ResWave provides peer-support and well-being features. It is not a clinical diagnosis or therapy platform.

---

## Researcher Matching Engine

One of ResWave's central technical components is its multi-factor recommendation engine.

Instead of relying on random recommendations, the system is designed to compare structured researcher profiles and calculate compatibility scores.

### Matching Parameters

The initial illustrative weighting configuration is:

| Parameter | Weight |
|---|---:|
| Research Interest Compatibility | 30% |
| Research Goal Compatibility | 20% |
| Skills Compatibility | 15% |
| Methodology Compatibility | 15% |
| Experience Compatibility | 10% |
| Availability Compatibility | 10% |
| **Total** | **100%** |

### Mathematical Model

The compatibility score is calculated using a weighted scoring approach:

\[
S = \sum_{i=1}^{n} w_i \times m_i
\]

Where:

- \(S\) = Final compatibility score.
- \(w_i\) = Weight of a matching criterion.
- \(m_i\) = Compatibility score for that criterion.
- \(n\) = Total number of matching criteria.

### Example Calculation

| Criterion | Match Score |
|---|---:|
| Research Interests | 90 |
| Research Goals | 80 |
| Skills | 85 |
| Methodologies | 70 |
| Experience | 90 |
| Availability | 100 |

**Illustrative final compatibility score: 85.25/100**

The purpose of explainable scoring is to help users understand why a researcher has been recommended.

### Other Recommendation Components

| Component | Recommendation Approach |
|---|---|
| Researcher Matching | Multi-factor compatibility scoring |
| Domain Finder | Questionnaire-based domain scoring |
| Mentor Matching | Expertise, mentoring preferences and availability |
| Teammate Matching | Required skills, project goals and eligibility |
| Group Recommendations | Research-interest compatibility |
| Opportunity Recommendations | Research-domain relevance |

**Technical Note:** The initial recommendation approach is deterministic and explainable. Advanced semantic matching, embeddings and trained ML models are potential future enhancements and should not be confused with the current weighted scoring approach.

---

## Technology Stack

| Layer | Technologies |
|---|---|
| Mobile Frontend | Flutter, Dart |
| Backend | Python, FastAPI |
| API Architecture | REST APIs |
| Data Validation | Pydantic |
| Database | Firebase Cloud Firestore |
| Authentication | Firebase Authentication |
| File Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging |
| Containerisation | Docker |
| Cloud Deployment | Google Cloud Run |
| Version Control | Git, GitHub |

---

## System Architecture

ResWave follows a modular architecture that separates the mobile interface, backend business logic and cloud services.

### High-Level Architecture

```text
                   RESWAVE USERS
                         |
                         |
                FLUTTER APPLICATION
                         |
                         |
                     REST API
                         |
                         |
                  FASTAPI BACKEND
                         |
             +-----------+-----------+
             |           |           |
             |           |           |
          Matching    Domain      Business
           Engine     Finder       Logic
             |           |           |
             +-----------+-----------+
                         |
                         |
                     FIREBASE
                         |
          +--------------+--------------+
          |              |              |
      Firestore      Authentication   Storage
          |
          |
    Cloud Messaging
          |
          |
      NOTIFICATIONS
```

### Architecture Principles

- Modular and maintainable code organisation.
- Separation of UI and business logic.
- Structured API communication.
- Server-side validation.
- Role-based permissions.
- Explainable recommendation calculations.
- Privacy-conscious data handling.

---

## Repository Structure

```text
reswave/
|
|-- firebase/
|   |-- firestore.rules
|   |-- storage.rules
|   |-- firebase.json
|   |-- firestore.indexes.json
|
|-- reswave_backend/
|   |-- app/
|   |   |-- main.py
|   |   |-- models/
|   |   |   |-- schemas.py
|   |   |-- services/
|   |   |   |-- domain_finder.py
|   |   |   |-- matching_engine.py
|   |   |   |-- seed_data.py
|   |   |-- core/
|   |       |-- memory_db.py
|   |
|   |-- server.py
|   |-- requirements.txt
|   |-- Dockerfile
|
|-- reswave_flutter/
|   |-- lib/
|   |   |-- main.dart
|   |   |-- core/
|   |   |-- models/
|   |   |-- services/
|   |   |-- screens/
|   |   |-- widgets/
|   |
|   |-- test/
|   |-- pubspec.yaml
|
|-- reswave_web/
|   |-- index.html
|   |-- app.js
|   |-- styles.css
|
|-- test_runner.py
|-- package_zip.py
|-- README.md
|-- .gitignore
```

The directory tree represents the intended project organisation. Update it if the actual repository differs.

---

## Getting Started

### Prerequisites

Install the following tools:

- Python 3.10 or later.
- Flutter SDK.
- Dart SDK.
- Git.
- Android Studio or VS Code.
- A Firebase project for Firebase-dependent functionality.

Verify the installations:

```bash
python --version
flutter --version
dart --version
git --version
```

### 1. Clone the Repository

```bash
git clone YOUR_REPOSITORY_URL
cd reswave
```

### 2. Backend Setup

Navigate to the backend:

```bash
cd reswave_backend
```

Create a virtual environment:

```bash
python -m venv .venv
```

Activate on Windows:

```powershell
.venv\Scripts\Activate.ps1
```

Activate on macOS/Linux:

```bash
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

### 3. Firebase Configuration

Configure your own Firebase development environment.

Depending on the functionality being used, this may include:

- Firebase Authentication.
- Cloud Firestore.
- Firebase Storage.
- Firebase Cloud Messaging.
- Appropriate Firebase application configuration.

**Security:** Never upload service-account credentials, private keys or secret environment files to the public repository.

### 4. Flutter Setup

Navigate to the Flutter application:

```bash
cd reswave_flutter
```

Install dependencies:

```bash
flutter pub get
```

Check your development environment:

```bash
flutter doctor
```

---

## Running the Application

### Option 1: Standalone Web and API Server

From the repository root:

```bash
python reswave_backend/server.py 8000
```

Open the application:

```text
http://localhost:8000
```

The standalone server provides an interactive environment for exploring the workflows implemented in that server.

### Option 2: FastAPI Backend

From the backend directory:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Interactive API documentation:

```text
http://localhost:8000/docs
```

### Option 3: Flutter Mobile Application

From the Flutter directory:

```bash
flutter run
```

Build an Android release APK:

```bash
flutter build apk --release
```

The generated APK is normally located at:

```text
build/app/outputs/flutter-apk/
```

---

## Testing

ResWave includes a Python test runner for automated workflow checks.

Run:

```bash
python test_runner.py
```

Flutter tests:

```bash
cd reswave_flutter
flutter test
```

### Important Testing Areas

- Authentication and account workflows.
- Profile creation and updates.
- Multiple research-interest handling.
- Domain recommendation calculations.
- Researcher compatibility scoring.
- Mentor matching.
- Project applications.
- Team capacity handling.
- Access permissions.
- Private mood records.
- File access restrictions.

Test results should be verified in the actual development environment before being reported as passing.

---

## Security and Privacy

Privacy and access control are important design considerations in ResWave.

### Authentication and Permissions

- Firebase-based authentication.
- Protected application workflows.
- Role-based access controls.

### Administrative Access

- Administrative privileges should be assigned through trusted server-side processes.
- Users should not be able to grant themselves administrator permissions through normal signup.

### Private Mood Records

- Personal mood records should remain accessible only to their owners.
- Mood information should not be used for researcher matching.

### Research Paper Notes

- Personal research notes should remain private to their owners.

### Project Collaboration

- Project tasks, files and discussions should be accessible only to authorised project members.

### Credential Protection

- Never commit API secrets, service-account credentials or private keys.
- Use environment variables for sensitive backend configuration.
- Review Firebase security rules before deployment.
- Restrict API keys according to the services and applications that use them.

---

## Deployment

### Firebase Security Rules

From the Firebase directory:

```bash
firebase deploy --only firestore:rules,storage
```

### Docker Deployment

From the backend directory:

```bash
docker build -t reswave-api .
```

Run locally:

```bash
docker run -p 8000:8000 reswave-api
```

### Google Cloud Run

Build and submit:

```bash
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/reswave-api
```

Deploy:

```bash
gcloud run deploy reswave-api \
  --image gcr.io/YOUR_PROJECT_ID/reswave-api \
  --platform managed \
  --region us-central1
```

Before deployment, configure the required environment variables, service permissions and Firebase access. Review authentication and access restrictions before making services publicly accessible.

---

## Future Scope

ResWave is designed to evolve with additional research-focused capabilities.

Potential future enhancements include:

- Advanced semantic researcher matching.
- ML-based recommendation models.
- Integration with academic paper discovery APIs.
- Automated academic conference discovery.
- Research publication verification.
- Advanced collaboration analytics.
- Calendar and research scheduling integration.
- Improved mentorship workflows.
- Research progress analytics.
- Multilingual accessibility.

---

## Contributing

Contributions, ideas and feedback are welcome.

To contribute:

**1. Fork the repository.**

**2. Create a feature branch.**

```bash
git checkout -b feature/your-feature-name
```

**3. Make your changes and test them.**

**4. Commit your work.**

```bash
git commit -m "Add: describe your changes"
```

**5. Push your branch.**

```bash
git push origin feature/your-feature-name
```

**6. Open a Pull Request** with a clear explanation of your contribution.

Please do not commit API keys, private credentials or personal data.

---

## Project Creator and Credits

### Created and Developed by Vanshika Goyal

**Project Concept | Product Development | UI/UX Design | Software Development**

ResWave is an academic project conceptualised and developed with the goal of making the research journey more accessible, collaborative and supportive.

From exploring the product vision and designing its user experience to developing its application architecture and core functionalities, this project represents an effort to bring research discovery, academic networking and collaboration into one connected ecosystem.

### Special Acknowledgements

- Faculty mentors and academic guides for their guidance and feedback.
- Everyone who shared suggestions and feedback during the development journey.
- The open-source developer community and creators of the technologies used in this project.

**Built with curiosity, dedication and a vision for a more connected research community.**

---

## ResWave

**Discover. Connect. Collaborate. Grow.**

Making research more accessible, connected and collaborative, one connection at a time.
