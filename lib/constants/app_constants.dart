// Constants file for BMI App
class Constants {
  // Input validation
  static const double minHeightCm = 50.0;
  static const double maxHeightCm = 300.0;
  static const double minWeightKg = 1.0;
  static const double maxWeightKg = 1000.0;
  
  // Conversion factors
  static const double lbsToKg = 0.453592;
  static const double kgToLbs = 1 / lbsToKg;
  static const double cmToM = 0.01;
  static const double cmToInch = 0.393701;
  static const double inchToCm = 1 / cmToInch;
  static const double cmToFeet = 0.0328084;
  static const double feetToCm = 1 / cmToFeet;
  
  // UI constants
  static const double inputFieldHeight = 60.0;
  static const double buttonHeight = 50.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
  
  // Text sizes
  static const double titleFontSize = 28.0;
  static const double subtitleFontSize = 16.0;
  static const double bmiResultFontSize = 48.0;
  static const double categoryFontSize = 18.0;
  
  // Spacing
  static const double standardPadding = 16.0;
  static const double mediumSpacing = 20.0;
  static const double largeSpacing = 30.0;
  static const double extraLargeSpacing = 40.0;
}