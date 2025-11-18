# ExamVault - ATPL Exam Prep App 🚀

A comprehensive **Flutter** application designed to help students prepare for their ATPL (Airline Transport Pilot License) examinations. Built entirely with **Firebase** for a serverless, scalable architecture with offline support.

## 🎯 Features

- ✅ **User Authentication** - Secure email/password authentication with Firebase Auth
- ✅ **Practice Sessions** - Topic-based practice with immediate feedback
- ✅ **4-Option Questions** - Standard ATPL format (A, B, C, D) with explanations
- ✅ **Progress Tracking** - Comprehensive statistics by subject and topic
- ✅ **Modern UI** - Clean blue/white/black theme with Material Design 3
- ✅ **Admin Dashboard** - Seed and manage question database
- ✅ **Offline Support** - Firestore offline persistence
- ✅ **Cross-Platform** - iOS, Android, and Web from a single codebase

## 📱 Screenshots & User Flow

### Student Flow:
1. **Sign Up / Login** → Create account or login with email/password
2. **Home Dashboard** → View subjects, progress stats, quick actions
3. **Practice Setup** → Select subjects and topics, choose number of questions
4. **Practice Session** → Answer 4-option questions with immediate feedback
5. **Results & Review** → View score, review answers, see explanations
6. **Progress Tracking** → Detailed statistics by subject and topic

### Admin Flow:
1. **Admin Dashboard** → Seed sample data from JSON file
2. **Manage Data** → View statistics, clear data, reseed as needed

## 🛠️ Tech Stack

* **Flutter 3.13+** – Cross-platform UI framework
* **Riverpod 2.x** – State management with hooks
* **go_router 7.x** – Declarative routing and navigation
* **Firebase Auth** – User authentication
* **Cloud Firestore** – NoSQL database with offline support
* **Material Design 3** – Modern, consistent UI components

## 📁 Project Structure

```
ExamVault/
├─ lib/
│  ├─ models/              # Data models (Question, Subject, Topic, UserProgress)
│  ├─ services/            # Business logic (AuthService, QuestionService, ProgressService)
│  ├─ providers/           # Riverpod providers for state management
│  ├─ screens/             # UI screens
│  │  ├─ auth/            # Login and signup
│  │  ├─ home/            # Main dashboard
│  │  ├─ practice/        # Practice setup and session
│  │  ├─ progress/        # Statistics and progress
│  │  └─ admin/           # Admin dashboard
│  ├─ theme/              # App theme (blue/white/black)
│  ├─ navigation/         # go_router configuration
│  ├─ firebase_options.dart
│  └─ main.dart
├─ assets/
│  └─ sample_questions.json  # 25 sample ATPL questions
├─ pubspec.yaml
└─ README.md
```

## 🚀 Getting Started

### Prerequisites

1. **Install Flutter** (3.13 or higher)
   ```bash
   # Verify installation
   flutter doctor
   ```

2. **Install Firebase CLI** (optional, for deployment)
   ```bash
   npm install -g firebase-tools
   ```

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/kezar0001-cpu/ExamVault.git
   cd ExamVault
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**

   The app is already configured to use Firebase Web with the ExamVault project. The credentials are in `lib/firebase_options.dart`.

   **For Android/iOS:** You'll need to add your own Firebase apps:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select the ExamVault project (or create a new one)
   - Add Android and/or iOS apps
   - Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
   - Run `flutterfire configure` to update `firebase_options.dart`

4. **Run the app**
   ```bash
   # Web
   flutter run -d chrome

   # Android
   flutter run -d android

   # iOS
   flutter run -d ios
   ```

## 📊 Database Setup

### Firestore Collections

The app uses these Firestore collections:
- **`users`** - User profiles (name, email, role)
- **`subjects`** - ATPL subjects (Air Law, Meteorology, etc.)
- **`topics`** - Topics within subjects
- **`questions`** - Question bank with 4 options
- **`sessions`** - Practice session records
- **`sessions/{id}/answers`** - Individual answers within sessions
- **`userProgress`** - User statistics and progress tracking

### Seeding Sample Data

The app includes 25 sample ATPL questions covering:
- Air Law
- Aircraft General Knowledge
- Meteorology
- Flight Performance and Planning
- Human Performance and Limitations

**To seed the database:**

1. **Create an admin user:**
   - Sign up normally in the app
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Navigate to Firestore Database → `users` collection
   - Find your user document (by email)
   - Edit the document and set `role: "admin"`

2. **Access Admin Dashboard:**
   - Logout and login again (role changes require re-authentication)
   - Click the "Admin Dashboard" button on the home screen

3. **Seed Data:**
   - Click "Seed All Data" to load subjects, topics, and questions
   - Or seed them individually: Subjects → Topics → Questions

4. **Start Practicing:**
   - Logout of admin account
   - Login as a student (or create new student account)
   - Select subjects/topics and start practicing!

## 🎮 Usage Guide

### For Students

1. **Create Account**: Sign up with email and password
2. **Browse Subjects**: View available ATPL subjects on home screen
3. **Start Practice**:
   - Tap "Start Practice"
   - Select one or more subjects
   - Check specific topics within those subjects
   - Choose number of questions (10, 20, 30, or 50)
   - Click "Start Practice"
4. **Answer Questions**:
   - Read the question
   - Select one of 4 options (A, B, C, D)
   - Submit your answer
   - View immediate feedback (correct/incorrect)
   - Read the explanation
   - Click "Next Question"
5. **Review Results**:
   - See your overall score
   - Review all answers
   - View explanations for all questions
6. **Track Progress**:
   - Tap "View Progress"
   - See overall statistics
   - Expand subjects to view topic-level progress

### For Admins

1. **Access Dashboard**: Login with admin account
2. **Seed Data**: Use "Seed All Data" or individual seed buttons
3. **View Statistics**: See counts of subjects, topics, and questions
4. **Clear Data**: Use with caution - permanently deletes all data

## 🎨 UI Theme

The app uses a professional blue/white/black color scheme:

- **Primary Blue**: `#1976D2` - Main actions, headers
- **Dark Blue**: `#0D47A1` - Gradients, emphasis
- **Light Blue**: `#42A5F5` - Accents, highlights
- **White**: `#FFFFFF` - Cards, backgrounds
- **Black**: `#212121` - Text, dark elements
- **Gray**: `#757575` - Secondary text
- **Success Green**: `#4CAF50` - Correct answers
- **Error Red**: `#F44336` - Incorrect answers

## 🔒 Security Rules

Update your Firestore Security Rules to match the app's permissions. Basic rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Everyone can read subjects, topics, questions
    match /subjects/{subjectId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /topics/{topicId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /questions/{questionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Users can read/write their own sessions
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null;
    }

    // Users can read/write their own progress
    match /userProgress/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

## 🏗️ Building for Production

### Web
```bash
flutter build web --release
# Output: build/web/
```

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Or for app bundle (recommended for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Then open Xcode and archive
```

## 📝 Sample Questions

The app includes 25 realistic ATPL questions in `/assets/sample_questions.json`:

- **Air Law**: ICAO Annexes, Rules of the Air, Licensing (5 questions)
- **Aircraft General Knowledge**: Powerplant, Airframe Systems (4 questions)
- **Meteorology**: Atmospheric Physics, Weather Phenomena (6 questions)
- **Flight Performance**: Mass & Balance, Aircraft Performance (5 questions)
- **Human Performance**: Aviation Physiology (5 questions)

All questions follow the standard 4-option format (A, B, C, D) with one correct answer and a detailed explanation.

## 🧪 Testing

Run tests:
```bash
# Unit tests
flutter test

# Integration tests (if added)
flutter test integration_test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is for educational purposes.

## 🙏 Acknowledgments

- Sample ATPL questions based on EASA and FAA guidelines
- Built with Flutter and Firebase
- Material Design 3 components

## 📧 Support

For issues, questions, or contributions, please open an issue on GitHub.

---

**Happy Learning! 🎓✈️**
