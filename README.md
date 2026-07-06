# CodeAlpha_FlashcardQuizApp (Flashcard Quiz App)

**Flashcard Quiz App** is a premium, production-quality offline study application built in Flutter using Material 3 design systems. It provides students with a modern and interactive learning interface, enabling them to create dynamic categories, manage flashcards, view graphical study progress logs, search through card questions, star favorites, and review study decks with fluid page transitions and card-flip animations.

---

## 📱 Features

- **Material 3 Design Guidelines**: Smooth gradients, rounded corners, soft shadow elements, and custom micro-interactions that feel premium and tactile.
- **Dynamic Category Decks**: Includes default interactive decks for **Programming**, **Mathematics**, **Science**, **History**, and **English**, with full support for custom user-created categories.
- **Card-Flip Study Interface**: Displays cards one at a time. The card initially shows the question, and reveals the answer with a smooth 3D flip animation when the user taps the **Show Answer** button.
- **Study Toolbar & Swipe Gestures**: Features standard quiz controls (`Previous`, `Next`, `Shuffle`, `Favorite`) and support for swipe gestures (`Swipe left -> Next`, `Swipe right -> Previous`).
- **Full CRUD Support**: Complete forms to create, view, update, and delete cards with input validations.
- **Wildcard Search Engine**: Reactive search matching card questions, answers, and categories, complete with recent search history caching.
- **Statistics & Study Logs**: A detailed graphical dashboard displaying the daily study counter progress, total flashcard distributions, starred card counts, and category deck ratios using custom animated progress bars and bar charts.
- **Dark Mode & Data Resets**: Toggle between light and dark themes seamlessly. Reset the SQLite database to clear all logs and restore the default category study decks with confirmation prompts.

---

## 🛠 Database Schema

The application uses **SQLite** (`sqflite` package) for local data persistence. The main database table is `Flashcards`:

| Field Name | Data Type | Description |
| :--- | :--- | :--- |
| **id** | `INTEGER PRIMARY KEY AUTOINCREMENT` | Unique identifier for each card. |
| **question** | `TEXT NOT NULL` | The question or term displayed on the front side. |
| **answer** | `TEXT NOT NULL` | The answer or definition displayed on the back side. |
| **category** | `TEXT NOT NULL` | Category/deck name (e.g. Programming, Science). |
| **difficulty** | `TEXT NOT NULL` | The level of difficulty (Easy, Medium, Hard). |
| **favorite** | `INTEGER NOT NULL DEFAULT 0` | Favorite status (0 = false, 1 = true). |
| **createdAt** | `TEXT NOT NULL` | Timestamp of when the card was created (ISO 8601). |
| **updatedAt** | `TEXT NOT NULL` | Timestamp of the last card modification (ISO 8601). |

A secondary table `study_logs` is maintained to track the **Daily Study Counter**:
- **id**: `INTEGER PRIMARY KEY AUTOINCREMENT`
- **date**: `TEXT UNIQUE NOT NULL` (Format: `YYYY-MM-DD`)
- **cards_count**: `INTEGER NOT NULL DEFAULT 0`

---

## 📂 Project Folder Directory Structure

The codebase is organized following **Clean Architecture** patterns:

```text
lib/
├── main.dart                 # App initialization, Providers & Theme setup
├── constants/
│   ├── app_colors.dart       # Theme colors, gradients, and dark/light shades
│   ├── app_constants.dart    # SQLite DB names, Versions, and SharedPref keys
│   └── app_text_styles.dart  # Custom typography styles (Outfit and Inter)
├── database/
│   └── database_helper.dart  # SQLite database initialization, upgrades, and seeds
├── models/
│   ├── flashcard_model.dart  # Data transfer object (DTO) mapping conversions
│   └── user_model.dart       # User credentials data class
├── providers/
│   ├── auth_provider.dart    # Profile state management provider
│   ├── theme_provider.dart   # Light and Dark theme state manager
│   └── flashcard_provider.dart # CRUD actions, search filters, sorting, and daily logs
├── repositories/
│   ├── flashcard_repository.dart       # Abstract repository interface
│   └── flashcard_repository_impl.dart  # SQLite worker implementation
├── services/
│   └── storage_service.dart  # Shared preferences controller (theme, positions)
├── screens/
│   ├── splash_screen.dart    # Scaled and faded onboarding logo transition
│   ├── home_screen.dart      # Category decks, sorting panels, and daily goals
│   ├── study_screen.dart     # Flip card quiz with swipe gestures & tools
│   ├── add_edit_card_screen.dart # CRUD card builder form (validators, chips)
│   ├── search_screen.dart    # Wildcard filter with search history tags
│   └── statistics_screen.dart # Graphical bar charts and animated progress bars
│   └── settings_screen.dart  # Dark mode toggles, DB resets, and info modals
├── widgets/
│   ├── custom_button.dart    # Tap-scalable semantic button widget
│   ├── custom_card.dart      # Interactive scale-on-touch container widget
│   └── custom_dialog.dart    # Standardized confirmation & input alert dialogues
├── animations/
│   └── custom_page_route.dart # Custom page transition animation route
└── utils/
    └── app_router.dart       # Navigation routes and custom page transition bindings
```

---

## 🚀 Installation & Run Guide

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
*   Dart SDK
*   An Android Emulator, iOS Simulator, or Desktop Environment setup

### Steps
1.  Clone the repository:
    ```bash
    git clone https://github.com/CodeAlpha/CodeAlpha_FlashcardQuizApp.git
    cd CodeAlpha_FlashcardQuizApp
    ```

2.  Fetch dependency packages:
    ```bash
    flutter pub get
    ```

3.  Build and run the project:
    ```bash
    flutter run
    ```

---

## 📦 Core Dependencies

This application leverages the following dependency packages:
*   [`provider`](https://pub.dev/packages/provider): Central state management.
*   [`sqflite`](https://pub.dev/packages/sqflite): Persistent SQLite local database.
*   [`shared_preferences`](https://pub.dev/packages/shared_preferences): Local cache of settings (dark mode, positions).
*   [`google_fonts`](https://pub.dev/packages/google_fonts): Outfit (headings) and Inter (body) typography.
*   [`flutter_animate`](https://pub.dev/packages/flutter_animate): Cascade styling fade/scale/slide animations.
*   [`fl_chart`](https://pub.dev/packages/fl_chart): Study log activity graph charts.
*   [`flip_card`](https://pub.dev/packages/flip_card): 3D card-flip animations.

---

## 🔮 Future Improvements
*   **Cloud Backup**: Sync study decks across multiple devices via Firebase or Supabase.
*   **Import / Export Decks**: Support importing flashcards from `.json` or `.csv` files.
*   **Text-to-Speech (TTS)**: Let the application read card questions/answers aloud.
*   **OCR Image Scan**: Scan study card questions from pictures of textbooks.

---

## 📜 License
This project is licensed under the MIT License - see the `LICENSE` file for details.
