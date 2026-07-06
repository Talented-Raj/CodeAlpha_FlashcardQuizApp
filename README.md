# CodeAlpha_FlashcardQuizApp (Memora)

Memora is a production-grade, offline-first spaced-repetition flashcard application built in Flutter following Clean Architecture, SOLID principles, and Material 3 design systems. It incorporates the Leitner Spaced-Repetition System to optimize cognitive memory retention.

---

## 📱 Features

*   **Leitner Spaced-Repetition System**: Automatically schedules review intervals based on user feedback. Correct answers ("Know") promote cards to higher boxes (longer recall intervals), while incorrect answers ("Forgot") reset cards to Box 1 for immediate review tomorrow.
*   **Study Dashboard**: Visual statistics panel showing studied cards count today, box distributions, and deck counts.
*   **Animated Charts & Performance Analytics**: Renders daily reviews over weekly and monthly periods using custom `fl_chart` animations.
*   **Dedicated Search**: Real-time live wildcard query matching front question terms, definitions, and category titles. Stores recent search history locally.
*   **CRUD Flashcards Form**: Screen to add/edit flashcards with input validation bounds, deck autocompletes, favorite star triggers, and Leitner box override selectors.
*   **Smooth Gesture Navigation**: Supports swiping cards inside a `PageView` with flip animations.
*   **Theme Customization**: Responsive dark and light theme switching.

---

## 🛠 Leitner System Interval Matrix

Cards are grouped into five Leitner boxes. When reviewed, the scheduling intervals change as follows:

| Box Level | Status | Review Interval |
| :--- | :--- | :--- |
| **Box 1** | New / Hardest | Every 1 Day |
| **Box 2** | Beginner | Every 3 Days |
| **Box 3** | Intermediate | Every 7 Days |
| **Box 4** | Advanced | Every 14 Days |
| **Box 5** | Mastered | Every 30 Days |

---

## 📂 Project Folder Directory Tree

The codebase is organized following **Clean Architecture** patterns under the `lib/` root:

```text
lib/
├── main.dart                 # App initialization, SharedPreferences bindings & providers
├── constants/
│   ├── app_colors.dart       # Light and dark color palettes, gradients
│   └── app_constants.dart    # SQLite DB configs, SharedPreferences keys
├── core/
│   ├── app_exceptions.dart   # Standard DB and domain exception wrappers
│   └── app_router.dart       # Material page route switcher mappings
├── models/
│   └── flashcard_model.dart  # Data transfer objects & mapping conversion formats
├── database/
│   └── database_helper.dart  # Singleton SQLite connection & migrations management
├── repositories/
│   ├── flashcard_repository.dart       # Abstract repository interface definition
│   └── flashcard_repository_impl.dart  # Database repository worker implementations
├── services/
│   └── storage_service.dart  # SharedPreferences theme and position wrappers
├── providers/
│   ├── auth_provider.dart    # Simulated onboarding state management
│   ├── theme_provider.dart   # Light/Dark mode state management
│   └── flashcard_provider.dart # CRUD operations, search results, and Leitner scheduling
├── screens/
│   ├── splash_screen.dart    # App entrance animated delay
│   ├── home_screen.dart      # Main dashboard stats, deck lists, and cards lists
│   ├── study_screen.dart     # Spaced repetition study swipe page and flip viewer
│   ├── add_edit_card_screen.dart # Detailed card creator/modifier form fields
│   ├── search_screen.dart    # Dedicated search panel with histories
│   └── statistics_screen.dart # Visual FL Charts dashboards and logs
└── widgets/
    ├── custom_button.dart    # Click-scalable semantic button widget
    ├── custom_card.dart      # Animated shadow border container widget
    └── custom_dialog.dart    # Standard dialog inputs and deletes triggers
```

---

## 🚀 Installation & Setup Guide

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
*   Dart SDK
*   Android Studio / Xcode (for emulator target runtimes)

### Steps

1.  Clone the repository:
    ```bash
    git clone https://github.com/your-username/CodeAlpha_FlashcardQuizApp.git
    cd CodeAlpha_FlashcardQuizApp
    ```

2.  Fetch dependency packages:
    ```bash
    flutter pub get
    ```

3.  Verify SQLite database setup and run the application:
    ```bash
    flutter run
    ```

---

## 📦 Key Dependencies

Memora leverages the following packages:
*   [`provider`](https://pub.dev/packages/provider): Direct state management.
*   [`sqflite`](https://pub.dev/packages/sqflite): Offline-first local database storage.
*   [`shared_preferences`](https://pub.dev/packages/shared_preferences): Persistent configurations (theme modes, last studied card indices).
*   [`google_fonts`](https://pub.dev/packages/google_fonts): Outfit (headers) and Inter (body) typography.
*   [`flutter_animate`](https://pub.dev/packages/flutter_animate): Cascading dashboard animations.
*   [`fl_chart`](https://pub.dev/packages/fl_chart): Pie, Bar, and Line charts rendering review activity logs.
*   [`flip_card`](https://pub.dev/packages/flip_card): Smooth flip card animations.

---

## 🎨 Visual Layout & Screenshots Placeholders

*Add visual captures here:*
*   **Home Dashboard**: `[Insert Home Screen screenshot here]`
*   **Study Sessions**: `[Insert Study Swipe & Flip screenshot here]`
*   **Statistics Panel**: `[Insert FL Charts stats dashboard screenshot here]`

---

## 🔮 Future Improvements

*   **Cloud Synchronization**: Implement Firebase or Supabase sync to share cards across devices.
*   **Import / Export Decks**: Support importing flashcards via `.csv` or `.json` formats.
*   **OCR Term Scanning**: Add text scanning from images to quickly generate decks from textbook pages.
*   **Audio Pronunciation**: Text-to-speech integration to read card questions/answers aloud.

---

## 🤝 Contribution Guidelines

We welcome contributions! Please follow these guidelines:
1.  Fork the project repository.
2.  Create a feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your modifications following clean code structures.
4.  Push changes and open a Pull Request.
