# Project Summary: BMI App

## Overview
use context7. This is a Flutter project named "bmi_app1" - a Body Mass Index calculator application that was created as a new Flutter project. It includes Firebase integration and is configured for a complete mobile application.

## Project Configuration
- **Project Name**: bmi_app1
- **Version**: 1.0.0+1
- **SDK**: Dart ^3.8.1, Flutter >=3.27.0
- **Project Type**: Mobile application (Flutter app)

## Dependencies
- Flutter SDK
- cupertino_icons: ^1.0.8
- google_fonts: ^6.1.0
- slide_to_act: ^2.0.1 (A slider widget for actions)
- firebase_core: ^4.0.0 (Firebase integration)

## Firebase Configuration
The project is configured with Firebase services:
- Project ID: bmigo-97acc
- Firestore database with basic security rules (currently set to expire Sept 13, 2025)
- Realtime Database with authentication required
- Storage with read/write disabled by default
- Functions configured with predeploy linting

## Project Structure
- `.dart_tool/`, `.idea/`, `android/`, `assets/`, `dataconnect/`, `dataconnect-generated/` directories
- Assets folder configured for images at `assets/images/`
- Basic Flutter project structure with standard configuration files

## Key Features & Components
- Uses Material Design
- Includes Google Fonts integration
- Has a custom slider component for user interaction (slide_to_act)
- Firebase authentication ready
- iOS and Android platform support

## Development Configuration
- Analysis options using Flutter lints
- Git ignore configured for Flutter projects
- Metadata tracking Flutter project properties
- Plugin dependencies for platform-specific functionality

## Security Notes
- Firestore rules are currently in development mode (will expire Sept 13, 2025)
- Database requires authentication but currently has basic read/write rules
- Storage has read/write disabled by default