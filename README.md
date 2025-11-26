# Bible App Tribble

A feature-rich Flutter application designed for Bible study and presentation, specifically optimized for Windows desktop.

## Features

- **Bible Reading**: Complete KJV Bible text with easy navigation by Book, Chapter, and Verse.
- **Search**: Fast search functionality to find specific verses (e.g., "John 3:16").
- **Voice Commands**: Integrated speech-to-text for hands-free searching.
- **Presentation Mode**: 
  - Dual-window support for projecting verses to a secondary display (projector/TV).
  - "Go Live" feature to instantly display selected verses.
  - Real-time updates during presentation.
- **GHS Support**: Includes Gospel Hymns and Songs with similar presentation capabilities.
- **Keyboard Shortcuts**:
  - `F5` or `R`: Go Live (Present current verse)
  - `Arrow Right`: Next Verse
  - `Arrow Left`: Previous Verse
  - `Esc`: Clear selection

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or later)
- Visual Studio 2022 (with C++ desktop development workload) for Windows build

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bible_app_tribble
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run -d windows
   ```

## Project Structure

- `lib/screens`: Main UI screens (Home, GHS, Presentation).
- `lib/providers`: State management using Provider.
- `lib/services`: Core services (Speech, Window Management).
- `lib/widgets`: Reusable UI components.
- `assets`: JSON data for Bible (KJV) and Hymns (GHS).

## Dependencies

- `provider`: State management
- `window_manager` & `desktop_multi_window`: Multi-window support
- `speech_to_text`: Voice recognition
- `flutter_colorpicker`: UI customization
- `animate_do`: UI animations

## License

[Add License Here]
