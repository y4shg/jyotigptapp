# JyotiGPT

JyotiGPT is an AI-powered spiritual assistant for exploring Brahma Kumaris teachings, Murli knowledge, and Rajyoga philosophy — available on web and mobile with support for voice, text, and image interactions.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quickstart](#quickstart)
- [Installation](#installation)
- [Building for Release](#building-for-release)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Security & Privacy](#security--privacy)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Quickstart

```bash
git clone https://github.com/y4shg/jyotigptapp && cd jyotigptapp
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d ios   # or: -d android
```

## Features

### Core Features
- **Spiritual Conversations**: Ask questions about the soul, karma, meditation, peace, purpose, and Rajyoga philosophy — JyotiGPT responds with thoughtful, knowledge-grounded answers
- **Murli Knowledge**: Explore daily Murli teachings and Brahma Kumaris spiritual concepts in a conversational, accessible way
- **Real-time Streaming**: Responses stream in real-time for a smooth, natural conversation experience
- **Markdown Rendering**: Full markdown support with syntax highlighting for clear, structured answers
- **Theme Support**: Light, Dark, and System themes

### Input & Interaction
- **Voice Input**: Use speech-to-text for hands-free, meditative interaction
- **Text Messaging**: Type your questions and reflections naturally
- **Image Input**: Share images for multi-modal conversations and visual context
- **AI Image Generation**: Generate beautiful, meaningful images to visualize spiritual concepts and ideas

### Conversation Management
- **Chat Histories**: Create, search, and revisit past conversations
- **Folder Management**: Organize conversations into folders — create, rename, move, and delete
- **Secure Storage**: Credentials and session data stored securely using platform keychains

## Requirements

- Flutter SDK 3.0.0 or higher
- Android 6.0 (API 23) or higher
- iOS 12.0 or higher

## Installation

1. Clone the repository:
```bash
git clone https://github.com/y4shg/jyotigptapp.git
cd jyotigptapp
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code:
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android
```

## Building for Release

### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Configuration

### Android
The app requires the following permissions:
- Internet access
- Microphone (for voice input)
- Camera (for taking photos and image input)
- Storage (for file selection)

### iOS
The app will request permissions for:
- Microphone access (voice input)
- Speech recognition
- Camera access
- Photo library access

## Troubleshooting

- **iOS**: Ensure you have a recent version of Xcode, run `cd ios && pod install`, and set the signing team in Xcode if building on a physical device.
- **Android**: minSdk must be 23+. Ensure the correct Java and Gradle versions are installed. If builds fail, try `flutter clean`.
- **Codegen conflicts**: Run `flutter pub run build_runner build --delete-conflicting-outputs` to resolve.

## Security & Privacy

- Credentials are stored using platform secure storage (Keychain on iOS, Keystore on Android).
- No analytics or telemetry are collected.

## Contributing

JyotiGPT is currently in active development. We welcome your feedback and contributions!

- **Bug Reports**: Found a bug? Please [create an issue](https://github.com/y4shg/jyotigptapp/issues) with details about the problem, steps to reproduce, and your device/platform information.
- **Feature Requests**: Have an idea? Start a [discussion](https://github.com/y4shg/jyotigptapp/discussions) to share your ideas and gather community feedback.
- **Questions & Feedback**: Use [GitHub Discussions](https://github.com/y4shg/jyotigptapp/discussions) to ask questions, share your experience, or discuss the project.

> **Note:** As the project is actively evolving, we're not accepting pull requests at this time. Please use issues and discussions to share ideas, report bugs, and contribute to the project's direction.

## License

This project is licensed under the GPL-3.0 License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- The Brahma Kumaris community for their timeless spiritual teachings
- Flutter team for the excellent cross-platform mobile framework

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/y4shg/jyotigptapp/issues) page.