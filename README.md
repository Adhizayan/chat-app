# Chat App - Flutter Real-time Chat Application

A comprehensive Flutter chat application with Firebase backend featuring secure authentication, contact-based user discovery, real-time messaging, and push notifications.

## 🚀 Features

### Core Features
- **Secure Authentication**: Email/password registration and login with Firebase Auth
- **Contact-Based Discovery**: Sync phone contacts to find friends automatically
- **Real-time Messaging**: Instant message delivery with Firestore streams
- **Push Notifications**: Firebase Cloud Messaging for background alerts
- **Offline Support**: Message caching and offline functionality
- **Message Status**: Read receipts and delivery indicators
- **Typing Indicators**: Real-time typing status updates

### UI/UX Features
- **Material Design 3**: Modern, responsive design with light/dark themes
- **Contact Sync**: Find users based on phone contacts
- **Search Functionality**: Search chats, contacts, and messages
- **Profile Management**: Update profile picture, name, and phone number
- **Online Status**: See when contacts are online or last seen
- **Unread Badges**: Visual indicators for unread messages

## 🛠 Setup Instructions

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Firebase project with Authentication, Firestore, Cloud Messaging, and Storage enabled

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password), Firestore, Cloud Messaging, and Storage
3. Run `flutterfire configure` to generate Firebase configuration
4. Replace placeholder values in `lib/firebase_options.dart`

### Installation
1. Install dependencies: `flutter pub get`
2. Add `google-services.json` to `android/app/` (Android)
3. Add `GoogleService-Info.plist` to `ios/Runner/` (iOS)
4. Run: `flutter run`

## 📊 Project Structure

```
lib/
├── models/           # Data models (User, Message, ChatRoom)
├── services/         # Business logic (Auth, Chat, Contact, Notification, Offline)
├── providers/        # State management (Auth, Chat)
├── screens/          # UI screens (Auth, Home, Chat, Contacts, Profile)
├── widgets/          # Reusable components
├── utils/            # Utility functions
└── main.dart         # App entry point
```

## 🔥 Firebase Collections

- **users**: User profiles and contact lists
- **chatRooms**: Chat room metadata and participant info
- **messages**: Individual chat messages with status tracking

## 🛡️ Security

- Firebase Auth for secure authentication
- Firestore security rules for data protection
- Input validation and sanitization
- Secure contact syncing with permission handling

## 📱 Permissions

- **Contacts**: Find friends from your contact list
- **Camera**: Take photos for profile and messages
- **Storage**: Access photos and files for sharing
- **Internet**: Real-time messaging and sync
- **Notifications**: Background message alerts

## 🚦 Usage

1. **Register**: Create account with email and password
2. **Sync Contacts**: Allow contact access to find friends
3. **Start Chatting**: Select contacts to begin conversations
4. **Real-time**: Messages appear instantly with status indicators
5. **Notifications**: Get alerts for new messages when app is closed

## 📈 Performance

- Optimized Firestore queries with proper indexing
- Message pagination for large conversations
- Image caching for faster loading
- Offline message storage and sync
- Efficient state management with Provider

## 🔮 Future Enhancements

- [ ] Group chat functionality
- [ ] Voice/video calling
- [ ] Message reactions and emoji support
- [ ] End-to-end encryption
- [ ] Stories/status updates
- [ ] Dark mode improvements
- [ ] Message scheduling

## 📄 License

MIT License - see LICENSE file for details.

Built with ❤️ using Flutter and Firebase
