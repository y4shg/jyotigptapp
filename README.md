# JyotiGPT

JyotiGPT is an AI-powered spiritual assistant for exploring the teachings and wisdom of the Brahma Kumaris. It offers a calm, thoughtful space to ask questions, reflect on spiritual ideas, and deepen your understanding of Rajyoga, Murli knowledge, and the deeper nature of the self.

Whether you are new to spirituality or already familiar with Brahma Kumaris teachings, JyotiGPT meets you where you are — offering clear, meaningful responses rooted in timeless wisdom.

---

## What You Can Explore

- **The self and the soul** — questions about identity, consciousness, and inner peace
- **Karma and relationships** — understanding cause, effect, and connection
- **Rajyoga meditation** — guidance on practice, stillness, and inner transformation
- **Murli knowledge** — explore the teachings shared through daily Murlis
- **Values and purpose** — peace, purity, love, happiness, and the meaning of life

---

## Features

- **Spiritual conversations** — ask anything, reflect deeply, and receive thoughtful answers grounded in Brahma Kumaris philosophy
- **Voice input** — speak your questions naturally, hands-free
- **Image input** — share images for richer, multi-modal conversations
- **AI image generation** — bring spiritual concepts to life through beautiful, generated visuals
- **Real-time responses** — answers stream fluidly as they are composed
- **Conversation history** — revisit and organise past reflections into folders
- **Light, Dark, and System themes** — a serene experience in any environment

---

## Getting Started

### Requirements

- Flutter SDK 3.0.0 or higher
- Android 6.0 (API 23) or higher
- iOS 12.0 or higher

### Quickstart

```bash
git clone https://github.com/y4shg/jyotigptapp && cd jyotigptapp
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d ios   # or: -d android
```

### Installation

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
flutter run -d ios      # iOS
flutter run -d android  # Android
```

### Building for Release

**Android**
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

---

## Permissions

**Android** — Internet, Microphone, Camera, Storage

**iOS** — Microphone, Speech Recognition, Camera, Photo Library

---

## Troubleshooting

- **iOS**: Ensure a recent version of Xcode is installed, run `cd ios && pod install`, and set your signing team for physical device builds.
- **Android**: minSdk must be 23+. If builds fail, try `flutter clean`.
- **Codegen conflicts**: Run `flutter pub run build_runner build --delete-conflicting-outputs` to resolve.

---

## Privacy

Credentials are stored securely using platform keychains (Keychain on iOS, Keystore on Android). No analytics or telemetry are collected.

---

## Contributing

JyotiGPT is in active development. Contributions are welcome in spirit.

- **Bug reports** — [open an issue](https://github.com/y4shg/jyotigptapp/issues) with steps to reproduce and device details
- **Feature ideas** — share them in [GitHub Discussions](https://github.com/y4shg/jyotigptapp/discussions)
- **Questions** — reach out via [Discussions](https://github.com/y4shg/jyotigptapp/discussions)

> Pull requests are not being accepted at this time as the project is still evolving. Your ideas and feedback are always valued.

---

## License

GPL-3.0 — see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

With gratitude to the Brahma Kumaris community for their timeless teachings, and to the Flutter team for making beautiful cross-platform experiences possible.