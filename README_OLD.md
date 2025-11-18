# ExamVault - ATPL Exam Prep App 🚀

A comprehensive **Flutter** application designed to help students prepare for their ATPL (Airline Transport Pilot License) examinations. Built entirely with **Firebase** for a serverless, scalable architecture with offline support.

## 🎯 Features

- ✅ **User Authentication** - Secure email/password authentication with Firebase Auth
- ✅ **Practice Sessions** - Topic-based practice with immediate feedback
- ✅ **4-Option Questions** - Standard ATPL format (A, B, C, D)
- ✅ **Progress Tracking** - Comprehensive statistics by subject and topic
- ✅ **Modern UI** - Clean blue/white/black theme with Material Design 3
- ✅ **Admin Dashboard** - Seed and manage question database
- ✅ **Offline Support** - Firestore offline persistence
- ✅ **Cross-Platform** - iOS, Android, and Web from a single codebase

## 📁 Project Structure

```
ExamVault/
├─ lib/
│  ├─ models/              # Data models (Question, Subject, Topic, UserProgress, etc.)
│  ├─ services/            # Business logic (AuthService, QuestionService, ProgressService, etc.)
│  ├─ providers/           # Riverpod providers for state management
│  ├─ screens/             # UI screens
│  │  ├─ auth/            # Login and signup screens
│  │  ├─ home/            # Main dashboard
│  │  ├─ practice/        # Practice setup and session screens
│  │  ├─ progress/        # Statistics and progress tracking
│  │  ├─ admin/           # Admin dashboard with data seeding
│  │  └─ splash/          # Splash screen
│  ├─ theme/              # App theme configuration (blue/white/black)
│  ├─ navigation/         # go_router configuration
│  ├─ utils/              # Utility functions
│  ├─ firebase_options.dart  # Firebase configuration
│  └─ main.dart           # App entry point
├─ assets/                # Assets (images, JSON data)
│  └─ sample_questions.json  # Sample ATPL questions
├─ test/                  # Unit and widget tests
├─ pubspec.yaml           # Flutter dependencies
├─ firestore.rules        # Firestore security rules
└─ README.md              # This file
```

## Key Technologies

* **Flutter** – A single codebase targeting iOS, Android and web【677465909578408†L460-L465】.  This project uses the latest Flutter stable release.
* **Riverpod 2.x** – Scoped providers and `riverpod_hooks` for state management.
* **go_router** – Declarative navigation with deep linking support.
* **Firebase Auth** – Handles user sign‑up, login and role management.
* **Cloud Firestore** – Stores users, questions, subjects, topics, sessions and answers.  Firestore provides offline persistence automatically【161931351499624†L1450-L1464】.
* **Firebase Storage** – Stores question images and other media.  Images are cached on device via `cached_network_image` so students don’t re‑download assets between sessions.
* **Hive** – Lightweight local key–value storage for small bits of data (user settings, bookmarks, offline session buffers).

## Getting Started

1. **Install Dependencies**
   * Install Flutter (`>=3.13`).  See [Flutter installation](https://flutter.dev/docs/get-started/install).
   * Install the Firebase CLI (`npm install -g firebase-tools`) and the FlutterFire CLI (`dart pub global activate flutterfire_cli`).
   * Enable Flutter web: `flutter config --enable-web`.

2. **Configure Firebase**
   * Create a Firebase project in the Firebase console.
   * Add iOS, Android and web apps to the project and download the configuration files.
   * Run `flutterfire configure` in the `flutter_atpl_app` directory to generate `lib/firebase_options.dart`.  This file contains your Firebase project settings and is required for initialization.

3. **Install Packages & Run**
   * From the project root, run `flutter pub get` to install dependencies.
   * Run `flutter run` to launch the app on iOS, Android or web.

4. **Firestore Rules & Indexes**
   * The `firestore.rules` file contains a skeleton of security rules.  Edit and deploy with the Firebase CLI (`firebase deploy --only firestore:rules`) once you have finalised your schema.

## Schema Overview

The Firestore data model is designed around a handful of core collections.  Each document’s ID is either auto‑generated or set to match a related identifier (e.g. `uid` for user documents).

### `users` (collection)

Represents each authenticated user.  Stored under `/users/{uid}`.

| Field            | Type    | Description                                           |
|------------------|---------|-------------------------------------------------------|
| `email`          | string  | Email address of the user                             |
| `name`           | string  | Display name                                          |
| `role`           | string  | `student` or `admin`                                  |
| `subscription`   | string? | Subscription tier (e.g. `free`, `premium`)            |
| `country`        | string? | Country code (optional)                               |
| `preferredSyllabus` | string? | e.g. `EASA`, `FAA` (optional)                       |
| `createdAt`      | timestamp | Creation time                                         |

### `subjects` (collection)

High‑level categories such as Private Pilot, Instrument Rating, Commercial Pilot, Drone, etc.  Document IDs may be slugs or auto‑generated.

| Field        | Type      | Description                 |
|--------------|-----------|-----------------------------|
| `name`       | string    | Subject name                |
| `description`| string?   | Description or syllabus info |
| `createdAt`  | timestamp | Creation time               |

### `topics` (collection)

Belongs to a subject.  Document ID auto‑generated or slug.

| Field        | Type      | Description                                |
|--------------|-----------|--------------------------------------------|
| `subjectId`  | reference | Reference to a document in `subjects`       |
| `name`       | string    | Topic name                                 |
| `description`| string?   | Optional description                       |
| `createdAt`  | timestamp | Creation time                              |

### `questions` (collection)

Stores the question bank.  Each question document can include text, rich content, images, answer options and metadata.

| Field         | Type             | Description                                          |
|---------------|------------------|------------------------------------------------------|
| `subjectId`   | reference        | Parent subject                                       |
| `topicId`     | reference        | Parent topic                                         |
| `text`        | string           | Question stem (may contain Markdown/LaTeX)           |
| `imageUrls`   | list<string>?    | Zero or more image URLs stored in Firebase Storage   |
| `options`     | list<object>     | List of options; each option has `text` and `isCorrect` flags |
| `explanation` | string           | Detailed explanation and reasoning                   |
| `difficulty`  | number?          | Difficulty level (1–5, for example)                  |
| `reference`   | string?          | Learning objective or official code (FAA reference)   |
| `flags`       | map<string,bool> | Flags such as `new`, `updated`, `retired`, `figure`, `calculation` |
| `createdBy`   | reference        | Admin user who created/edited the question            |
| `createdAt`   | timestamp        | Creation time                                         |
| `updatedAt`   | timestamp        | Last update time                                      |

### `sessions` (collection)

Represents study sessions (practice or exam).  Stored under `/sessions/{sessionId}`.

| Field           | Type          | Description                                           |
|-----------------|---------------|-------------------------------------------------------|
| `userId`        | reference     | Reference to `users/{uid}`                           |
| `mode`          | string        | `practice` or `exam`                                 |
| `subjectIds`    | list<reference> | Chosen subject IDs                                   |
| `topicIds`      | list<reference> | Chosen topic IDs                                     |
| `questionIds`   | list<reference> | List of question IDs presented in this session       |
| `startTime`     | timestamp     | Session start time                                   |
| `endTime`       | timestamp?    | Session end time (null until completed)              |
| `isCompleted`   | bool          | Whether the session is finished                      |
| `score`         | number?       | Score at end (percentage correct)                    |

#### Subcollection `answers` (under each session)

Stores individual user answers for each question within the session.

| Field         | Type       | Description                                         |
|---------------|------------|-----------------------------------------------------|
| `questionId`  | reference  | Reference to the question document                  |
| `selectedIndex`| number    | Index of the option selected by the user            |
| `isCorrect`   | bool       | Whether the selected option was correct             |
| `timeTaken`   | number?    | Time in seconds spent on the question               |

### Optional `questionStats` (collection)

Aggregated stats per question.  Only admins can read/write.  This can be used later for adaptive difficulty.

| Field            | Type      | Description                            |
|------------------|-----------|----------------------------------------|
| `views`          | number    | How many times the question was seen    |
| `correctCount`   | number    | Number of correct answers               |
| `incorrectCount` | number    | Number of incorrect answers             |
| `totalTimeSpent` | number    | Sum of time spent answering the question |

### Security Rules Sketch

The following is a high‑level overview of access control.  See `firestore.rules` for a starting point.

* **Users (`/users/{uid}`)**
  * A user can read and update their own document: `request.auth != null && request.auth.uid == uid`.
  * Admins can read any user document.

* **Subjects/Topics/Questions (`/subjects`, `/topics`, `/questions`)**
  * Any authenticated user can read documents.
  * Only admins can write (create/update/delete).

* **Sessions (`/sessions/{sessionId}`)**
  * A user can create, read and update sessions where `data.userId == request.auth.uid`.
  * Admins can read all sessions for reporting/analysis.

* **Session Answers (`/sessions/{sessionId}/answers/{answerId}`)**
  * A user can create and read answers if they own the parent session.
  * Admins can read all answers.

* **Question Stats (`/questionStats/{questionId}`)**
  * Only admins can read or write.

Deploy these rules using the Firebase CLI once customised.

---

With the schema established, you can now move on to the Flutter implementation.  The next steps will create the project structure, set up Firebase initialization, authentication flows, and prepare screens for students and admins.