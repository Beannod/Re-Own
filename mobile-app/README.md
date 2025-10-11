# React Native Property Manager App

A React Native mobile application for the Re-Own Property Management System, providing mobile access to property management features for both owners and renters.

## Features

### For Property Owners
- 📊 Dashboard with property overview and statistics
- 🏠 Manage multiple properties
- 👥 Tenant management and lease assignments
- 💰 Payment tracking and history
- 📋 Property maintenance requests

### For Renters
- 🏡 View current lease and property details
- 💳 Payment history and rent management
- 🔧 Submit maintenance requests
- 📄 Access lease documents
- 📞 Contact property owner

## Tech Stack

- **Framework**: React Native with TypeScript
- **UI Library**: React Native Paper (Material Design)
- **Navigation**: React Navigation v6
- **State Management**: React Context API
- **HTTP Client**: Axios
- **Storage**: AsyncStorage
- **Backend**: FastAPI (Python) - separate project

## Prerequisites

Before running this project, ensure you have:

1. **Node.js** (v16 or higher)
2. **npm** or **yarn**
3. **React Native CLI**
4. **Android Studio** (for Android development)
5. **Java Development Kit (JDK)**

### Android Development Setup

1. Install Android Studio
2. Set up Android SDK
3. Configure environment variables:
   ```bash
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mobile-app
   ```

2. **Install dependencies**
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Install iOS dependencies** (macOS only)
   ```bash
   cd ios && pod install && cd ..
   ```

## Configuration

### Backend Connection

Update the API base URL in `src/services/ApiService.ts`:

```typescript
const API_BASE_URL = 'http://YOUR_BACKEND_IP:8000'; // Replace with your backend URL
```

**Note**: For Android emulator, use `http://10.0.2.2:8000` if running backend on localhost.

## Running the App

### Development Mode

1. **Start Metro bundler**
   ```bash
   npm start
   # or
   yarn start
   ```

2. **Run on Android**
   ```bash
   npm run android
   # or
   yarn android
   ```

3. **Run on iOS** (macOS only)
   ```bash
   npm run ios
   # or
   yarn ios
   ```

### Building for Production

#### Android
```bash
cd android
./gradlew assembleRelease
```

The APK will be generated at `android/app/build/outputs/apk/release/app-release.apk`

## Project Structure

```
src/
├── components/          # Reusable UI components
├── navigation/          # Navigation configuration
├── screens/            # Screen components
│   ├── LoginScreen.tsx
│   ├── DashboardScreen.tsx
│   ├── PropertiesScreen.tsx
│   ├── PaymentsScreen.tsx
│   └── ProfileScreen.tsx
├── services/           # API services
│   └── ApiService.ts
├── types/              # TypeScript type definitions
│   └── index.ts
└── utils/              # Utility functions and contexts
    └── AuthContext.tsx
```

## API Integration

The app connects to a FastAPI backend with the following endpoints:

- `POST /auth/login` - User authentication
- `GET /auth/me` - Get current user
- `GET /properties` - Get properties (owner) or current property (renter)
- `GET /leases/current` - Get current lease (renter)
- `GET /payments` - Get payment history
- `POST /leases/assign` - Assign property to tenant (owner)

## Development Guidelines

### Code Style
- Use TypeScript for all components
- Follow React Native best practices
- Use React Native Paper components for consistent UI
- Implement proper error handling

### State Management
- Use React Context for global state (auth, user data)
- Use local state for component-specific data
- Implement proper loading states

### Security
- Store sensitive data in AsyncStorage
- Implement proper token management
- Handle API errors gracefully

## Troubleshooting

### Common Issues

1. **Metro bundler issues**
   ```bash
   npx react-native start --reset-cache
   ```

2. **Android build failures**
   ```bash
   cd android && ./gradlew clean && cd ..
   ```

3. **Missing dependencies**
   ```bash
   rm -rf node_modules && npm install
   ```

4. **iOS build issues** (macOS)
   ```bash
   cd ios && pod install && cd ..
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of the Re-Own Property Management System.

---

**Note**: This mobile app requires the Re-Own backend API to be running. Make sure to start the FastAPI backend server before testing the mobile app.