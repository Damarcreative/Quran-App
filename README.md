# Quran App

A minimalist, aesthetic, and "cozy" Quran application built with Flutter. Designed for a focused and serene reading experience with a monochrome dark theme.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

![cover](https://repository-images.githubusercontent.com/1148592274/61035ef6-dee9-4163-bb0f-d0b6b7e411ad)


## Features

- **Cozy UI**: Deep dark mode (`#0a0a0a`) with monochrome headers and green accents.
- **Smooth Navigation**: Custom splash screen (native + Flutter) and seamless transitions.
- **Search & Jump**: Quickly find Surahs or jump to specific Ayahs.
- **Multi-Language**: Supports Indonesian and English translations (Sahih International).
- **Offline Capable**: Caches Surah lists and contents for offline reading.
- **Custom Typography**: Uses *Space Grotesk* for UI and *Amiri* for beautiful Arabic calligraphy.
- **Developer Info**: Integrated informational modal.


## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: `setState` (Clean & Simple)
- **Navigation**: Material Router
- **Networking**: `http` package
- **Caching**: `shared_preferences`
- **typography**: `google_fonts`

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Java JDK 17
- Android Studio / VS Code

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/Damarcreative/Quran-App.git
    cd Quran-App
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

## Build for Android

To generate an APK/Bundle:

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Credits

Developed by **Damar Jati** (Damar Creative).

- Website: [damarcreative.my.id](https://damarcreative.my.id)
- API: [Quran API](https://quran.damarcreative.my.id/api)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

&copy; 2026 Damar Jati. All rights reserved.
