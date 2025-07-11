# Flutter News App

A modern news application built with Flutter that provides users with the latest news articles and video content.

## Features

- 📰 **News Articles**: Browse and read the latest news articles
- 🎥 **Video News**: Watch video news content
- 🔍 **Search**: Search for specific news topics
- 👤 **User Authentication**: Login system for users
- 🛡️ **Admin Panel**: Admin interface for content management
- 📱 **Cross Platform**: Works on Android, iOS, and Web

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase (Firestore, Authentication)
- **Video Service**: YouTube API
- **Database**: Supabase (PostgreSQL)

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Firebase account
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flutter-news-app.git
   cd flutter-news-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project
   - Add your Android and iOS apps
   - Download and place `google-services.json` in `android/app/`
   - Download and place `GoogleService-Info.plist` in `ios/Runner/`

4. **Configure Supabase**
   - Create a new Supabase project
   - Update the Supabase URL and API key in your environment variables

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # API services
├── utils/           # Utility functions
└── widgets/         # Reusable widgets
```

## Features in Detail

### News Management
- Add, edit, and delete news articles
- Support for both text and video content
- Rich text editor for article content

### User Interface
- Modern and responsive design
- Dark/Light theme support
- Smooth animations and transitions

### Admin Features
- Content moderation
- User management
- Analytics dashboard

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Supabase for database solutions
- YouTube API for video content