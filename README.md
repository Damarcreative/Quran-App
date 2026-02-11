# My Quran

A minimalist, aesthetic, and focused Quran application built with Flutter for Android and iOS. Designed to deliver a serene and distraction-free reading experience with a carefully crafted dark theme and thoughtful typography.

This project is developed with enthusiasm, sincerity, and deep care. Going beyond mere commercial objectives, this initiative serves as a testament to our dedication to the needs of the Islamic Ummah and the global Muslim community, with the hope of providing tangible benefits for all.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)

![cover](https://repository-images.githubusercontent.com/1148592274/61035ef6-dee9-4163-bb0f-d0b6b7e411ad)


## Features

### Quran Reading
- Full 114 Surahs with Arabic text and translations
- Support for multiple translation editions (Indonesian and English / Sahih International)
- Jump to specific Ayah within a Surah
- Search Surahs by name or number
- Offline caching for Surah lists and contents

### Audio and Murotal
- Built-in audio player for Quran recitation (Murotal)
- Background audio playback support on both Android and iOS
- Full-screen player view with playback controls
- Persistent mini player for seamless navigation while listening
- Murotal download manager for offline listening

### Prayer Times
- Accurate daily prayer time schedules
- Imsakiyah (Ramadan fasting schedule) display

### User Interface
- Deep dark mode (#0A0A0A) with green accent color scheme
- Light mode support with automatic or manual switching
- Custom typography using Space Grotesk for UI elements and Amiri for Arabic calligraphy
- Custom splash screen with smooth transitions
- Clean and intuitive navigation

### Storage and Settings
- Download manager for Surah content (offline access)
- Storage management screen to monitor and clear cached data
- Configurable settings for theme, translation edition, and more

### Additional
- About screen with developer information
- External link support via URL launcher


## Tech Stack

| Category         | Technology                        |
| ---------------- | --------------------------------- |
| Framework        | Flutter (Dart)                    |
| State Management | setState                          |
| Networking       | http, dio                         |
| Audio            | just_audio, just_audio_background |
| Local Storage    | shared_preferences, path_provider |
| Typography       | google_fonts                      |
| Notifications    | flutter_local_notifications       |
| Permissions      | permission_handler                |
| Navigation       | scrollable_positioned_list        |
| Utilities        | intl, url_launcher                |
| Icons            | cupertino_icons                   |


## Project Structure

```
lib/
  main.dart                        -- Application entry point
  models/
    ayah.dart                      -- Ayah data model
    surah.dart                     -- Surah data model
    prayer_times.dart              -- Prayer times data model
  screens/
    splash_screen.dart             -- Splash screen
    main_screen.dart               -- Main navigation screen
    surah_list_screen.dart         -- Surah list with search
    surah_detail_screen.dart       -- Surah reading view
    murotal_screen.dart            -- Murotal audio browser
    murotal_download_screen.dart   -- Murotal download manager
    download_screen.dart           -- Surah content download manager
    prayer_times_screen.dart       -- Prayer time schedules
    imsakiyah_screen.dart          -- Ramadan imsakiyah schedule
    settings_screen.dart           -- App settings
    storage_management_screen.dart -- Storage and cache management
    about_screen.dart              -- About and developer info
  services/
    api_service.dart               -- API communication layer
    audio_service.dart             -- Audio playback management
    download_service.dart          -- Surah content download logic
    murotal_download_service.dart  -- Murotal audio download logic
    settings_service.dart          -- User preferences management
  widgets/
    full_player_view.dart          -- Full-screen audio player
    mini_player.dart               -- Persistent mini audio player
```


## Supported Platforms

| Platform | Status     |
| -------- | ---------- |
| Android  | Supported  |
| iOS      | Not Tested |


## Getting Started

### Prerequisites

- Flutter SDK (latest stable channel)
- Java JDK 17 or later
- Android Studio or Visual Studio Code
- Xcode (for iOS development, macOS only)

### Installation

1. Clone the repository

   ```bash
   git clone https://github.com/Damarcreative/Quran-App.git
   cd Quran-App
   ```

2. Install dependencies

   ```bash
   flutter pub get
   ```

3. Run the application

   ```bash
   flutter run
   ```


## Building for Production

### Android

Generate a release APK or App Bundle:

```bash
# APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS

Generate a release build (requires macOS with Xcode):

```bash
flutter build ios --release
```


## API

This application uses the Quran API provided by Damar Creative for fetching Surah data, translations, and audio recitations.

- Quran Web: [https://quran.damarcreative.my.id](https://quran.damarcreative.my.id)


## Credits

Developed by **Damar Jati** (Damar Creative).

- Website: [damarcreative.my.id](https://damarcreative.my.id)
- GitHub: [github.com/Damarcreative](https://github.com/Damarcreative)


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

Copyright (c) 2026 Damar Jati. All rights reserved.
