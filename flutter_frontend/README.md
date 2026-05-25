# Signature Analyzer - Flutter Frontend

A Flutter application that analyzes signature images to determine if they were written forcefully or naturally. This application provides real-time analysis with detailed metrics and supports deployment across iOS, Android, Web, Linux, macOS, and Windows platforms.

---

## Overview

The Flutter frontend is the user-facing component of the Signature Analyzer system. It provides an intuitive interface for users to upload signature images and receive detailed authenticity analysis from the machine learning backend.

**Dataset Reference**: The underlying ML model was trained on a self-collected dataset published on [Mendeley Data](https://data.mendeley.com/datasets/2nm9cp89df/1).

---

## Features

- **Image Upload**: Capture signatures via camera or select from device gallery
- **Real-time Analysis**: Instant detection of signature characteristics
- **Detailed Results**: 
  - Classification (Forceful or Natural)
  - Confidence percentage
  - Technical metrics
- **Technical Details View**: Advanced analysis including:
  - Alignment entropy
  - Slant variance
  - Pressure distribution
  - Stroke consistency
- **Multi-Platform Support**: 
  - ✅ iOS
  - ✅ Android
  - ✅ Web
  - ✅ Linux
  - ✅ macOS
  - ✅ Windows
- **User-Friendly Interface**: Material 3 design system for modern, responsive UI
- **Robust Error Handling**: Graceful handling of network and processing errors

---

## Prerequisites

- **Flutter SDK**: Version 3.8.0 or higher
  - Install from: https://flutter.dev/docs/get-started/install
- **Dart SDK**: Included with Flutter
- **Development Environment**:
  - **Android**: Android Studio or cmdline-tools
  - **iOS**: Xcode (macOS only)
  - **Web**: Any modern browser
  - **Desktop**: Visual Studio or Build Tools (Windows) or Command Line Tools (macOS/Linux)
- **IDE**: VS Code or Android Studio with Flutter extensions

---

## Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/signature_analyzer.git
cd signature_analyzer/flutter_frontend
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure API Endpoint

The app requires a connection to the FastAPI backend. Configure it as follows:

```bash
# Copy the template configuration
cp lib/config/api_config.template.dart lib/config/api_config.dart
```

Edit `lib/config/api_config.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'http://your-backend-url.com';  // Update with your backend URL
  static const int timeout = 30;
  static const bool enableLogging = false;
}
```

For local development:
```dart
static const String baseUrl = 'http://localhost:8000';
```

### 4. Run the Application

#### Android / iOS
```bash
flutter run
```

#### Web
```bash
flutter run -d chrome
```

#### Desktop (Windows)
```bash
flutter run -d windows
```

#### Desktop (macOS)
```bash
flutter run -d macos
```

#### Desktop (Linux)
```bash
flutter run -d linux
```

---

## Usage

### Basic Workflow

1. **Launch the Application**
   - Open the app on your target device/platform

2. **Upload Signature Image**
   - Tap "Gallery" button to select an existing signature image from your device
   - OR tap "Camera" button to capture a new signature
   - Supported formats: PNG, JPG, JPEG

3. **Analyze Signature**
   - Tap the "Analyze Signature" button
   - Wait for the backend to process the image (typically 2-5 seconds)

4. **View Results**
   - **Main Result**: See "Forceful" or "Natural" classification
   - **Confidence**: View the confidence percentage
   - **Technical Details**: Tap to expand and view:
     - Alignment entropy value
     - Slant variance
     - Additional feature metrics

### Error Handling

The app gracefully handles common scenarios:
- **Network Errors**: Displays user-friendly error messages
- **Invalid Images**: Validates image format before sending
- **API Timeouts**: Configurable timeout with retry option
- **Connection Issues**: Clear guidance for reconnection

---

## Project Structure

```
lib/
├── main.dart                           # Application entry point
├── config/
│   ├── api_config.dart                 # API configuration (auto-generated)
│   └── api_config.template.dart        # Configuration template
├── screens/                            # UI screens
├── services/                           # Backend communication services
├── models/                             # Data models
└── widgets/                            # Reusable UI components
```

---

## API Integration

### Backend Connection

The app communicates with the FastAPI backend via HTTP REST API:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/health` | Check backend availability |
| POST | `/predict` | Submit signature image for analysis |

### Request Format
```
POST /predict
Content-Type: multipart/form-data

Body:
  - image: <binary image file>
```

### Response Format
```json
{
  "classification": "Forceful",
  "confidence": 0.89,
  "features": {
    "alignment_entropy": 2.34,
    "slant_variance": 0.45,
    "pressure_distribution": 0.78
  }
}
```

---

## Dependencies

Key packages used in this project:

```yaml
flutter:
  sdk: flutter

# HTTP & API
http: ^1.1.0

# UI
cupertino_icons: ^1.0.0
google_fonts: ^6.0.0

# Image Handling
image_picker: ^1.0.0
image_cropper: ^5.0.0

# State Management
provider: ^6.0.0

# Data Serialization
json_serializable: ^6.0.0
```

See `pubspec.yaml` for complete dependency list.

---

## Screenshots

Key app screens and flows:

- **Home Screen**: Image upload interface with Gallery and Camera options
- **Analysis Results**: Classification result with confidence score
- **Technical Details**: Expanded view with detailed feature metrics

Screenshots available in `screenshots/` directory.

---

## Platform-Specific Setup

### Android
```bash
flutter config --android-studio-path="/path/to/android-studio"
flutter run
```

### iOS
```bash
# Install pods
cd ios
pod install
cd ..

# Run
flutter run
```

### Web
```bash
flutter run -d chrome --web-port=5000
```

### Windows
Requires Visual Studio Build Tools or Visual Studio Community Edition

### macOS
Requires Xcode Command Line Tools

### Linux
Requires GCC, make, pkg-config, and GTK 3.0 development files

---

## Building for Release

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## Development Tips

- **Enable Debug Logging**: Set `enableLogging = true` in `api_config.dart`
- **Hot Reload**: Press `R` in terminal during development
- **Device Testing**: Connect device and use `flutter devices` to list
- **Performance**: Use Flutter DevTools with `flutter pub global activate devtools` and `devtools`

---

## Troubleshooting

### API Connection Issues
- Verify backend is running and accessible at configured URL
- Check network connectivity
- Ensure `api_config.dart` has correct `baseUrl`

### Image Upload Issues
- Confirm image format is PNG or JPG
- Check image file size (recommended < 5MB)
- Verify camera/gallery permissions are granted

### Platform-Specific Issues
- **Android**: Clear cache with `flutter clean` and rebuild
- **iOS**: Delete `ios/Pods` and `ios/Podfile.lock`, then rebuild
- **Web**: Clear browser cache or use incognito mode

---

## Dataset Reference

The machine learning model used in the backend was trained on a self-collected dataset:

**Dataset Link**: [https://data.mendeley.com/datasets/2nm9cp89df/1](https://data.mendeley.com/datasets/2nm9cp89df/1)

For more information about model training and dataset details, see the main project [README.md](../README.md).

---

## Related Documentation

- **Main Project README**: [../README.md](../README.md)
- **Backend Setup**: [../backend/README.md or main README Backend section](../README.md#backend-setup)
- **Flutter Documentation**: https://flutter.dev
- **FastAPI Documentation**: https://fastapi.tiangolo.com

---

## License

MIT License

---

## Author

**Rituja**

For questions or contributions, please refer to the main project documentation.
- `image_picker` - Image selection
- `http` - API communication
- `flutter/foundation.dart` - Utilities

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Flutter
- Powered by machine learning for signature analysis
- FastAPI backend for processing
