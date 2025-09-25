# BMI Calculator App

A comprehensive Body Mass Index calculator application built with Flutter and Firebase. The app allows users to calculate their BMI using various units of measurement and provides visual feedback on their BMI category.

## Features

- **BMI Calculation**: Calculate BMI based on height and weight inputs
- **Multiple Units**: Support for height in cm, m, or feet and weight in kg or lbs
- **Visual Feedback**: Color-coded BMI categories (Underweight, Normal, Overweight, Obese)
- **Responsive UI**: Clean, modern interface using Material Design principles
- **Firebase Integration**: Ready for data storage and user authentication
- **Input Validation**: Range checks to ensure realistic height and weight values
- **Reset Functionality**: Easy reset of calculation results

## App Structure

The app follows a clean architecture with organized components:

- `lib/main.dart`: Main application entry point with UI implementation
- `lib/config/app_config.dart`: Application configuration and BMI categories
- `lib/constants/app_constants.dart`: Constant values for UI and validation
- `lib/utils/bmi_util.dart`: BMI calculation utilities and helper functions
- `lib/services/firebase_service.dart`: Firebase integration services
- `lib/models/bmi_result.dart`: Data model for BMI results

## Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.8.1 or higher)
- Android Studio or VS Code with Flutter plugin

### Installation

1. Clone the repository:
```bash
git clone https://github.com/harraznasrullah/bmi-calculator-app.git
```

2. Navigate to the project directory:
```bash
cd bmi-calculator-app
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the application:
```bash
flutter run
```

### Firebase Setup (Optional)

To enable full Firebase functionality:

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Add an Android, iOS, or Web app to your Firebase project
3. Download the configuration file (`google-services.json` for Android or `GoogleService-Info.plist` for iOS)
4. Place the configuration file in the appropriate directory:
   - Android: `android/app/`
   - iOS: `ios/Runner/`
   - Web: Update the web configuration in `web/index.html`

## Usage

1. Launch the app
2. Enter your height (in cm, m, or ft) and weight (in kg or lbs)
3. Select the appropriate units from the dropdown menus
4. Tap "Calculate BMI" to see your results
5. The app will display your BMI value and category with appropriate color coding

## Dependencies

- Flutter SDK
- cupertino_icons: ^1.0.8
- google_fonts: ^6.1.0
- slide_to_act: ^2.0.1
- firebase_core: ^3.15.2
- cloud_firestore: ^5.6.12

## Firebase Configuration

The app is configured with the following Firebase services:
- Firestore Database (with security rules)
- Authentication
- Storage
- Functions

## Project Architecture

The app uses a modular architecture:
- **Configuration**: App settings and BMI categories
- **Constants**: UI and validation parameters
- **Utilities**: Helper functions for calculations
- **Services**: Firebase integration services
- **Models**: Data models for results

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/) for the amazing framework
- [Firebase](https://firebase.google.com/) for backend services
- [Google Fonts](https://fonts.google.com/) for typography options
