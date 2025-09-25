# BMI Calculator App - Test Cases

## Test Suite Overview
This document outlines the test cases for the BMI Calculator application that calculates BMI based on weight (kg) and height (cm) inputs.

## Functional Test Cases

### 1. BMI Calculation Test Cases

#### Test Case 1.1: Normal BMI calculation
- **Input**: Weight = 70kg, Height = 175cm
- **Expected Result**: BMI = 22.9, Category = "Normal", Risk Indicator = "Green = healthy"
- **Steps**:
  1. Enter 70 in weight field
  2. Enter 175 in height field
  3. Tap "Calculate BMI"
  4. Verify result displays 22.9 and "Normal" category

#### Test Case 1.2: Underweight category
- **Input**: Weight = 50kg, Height = 170cm
- **Expected Result**: BMI = 17.3, Category = "Underweight", Risk Indicator = "Yellow = caution"
- **Steps**:
  1. Enter 50 in weight field
  2. Enter 170 in height field
  3. Tap "Calculate BMI"
  4. Verify result displays 17.3 and "Underweight" category

#### Test Case 1.3: Overweight category
- **Input**: Weight = 90kg, Height = 175cm
- **Expected Result**: BMI = 29.4, Category = "Overweight", Risk Indicator = "Yellow = caution"
- **Steps**:
  1. Enter 90 in weight field
  2. Enter 175 in height field
  3. Tap "Calculate BMI"
  4. Verify result displays 29.4 and "Overweight" category

#### Test Case 1.4: Obese category
- **Input**: Weight = 100kg, Height = 170cm
- **Expected Result**: BMI = 34.6, Category = "Obese", Risk Indicator = "Red = high risk"
- **Steps**:
  1. Enter 100 in weight field
  2. Enter 170 in height field
  3. Tap "Calculate BMI"
  4. Verify result displays 34.6 and "Obese" category

### 2. Input Validation Test Cases

#### Test Case 2.1: Negative weight validation
- **Input**: Weight = -70kg, Height = 175cm
- **Expected Result**: Error message "Please enter valid height and weight values."
- **Steps**:
  1. Enter -70 in weight field
  2. Enter 175 in height field
  3. Tap "Calculate BMI"
  4. Verify error dialog appears

#### Test Case 2.2: Zero values validation
- **Input**: Weight = 0kg, Height = 175cm
- **Expected Result**: Error message "Please enter valid height and weight values."
- **Steps**:
  1. Enter 0 in weight field
  2. Enter 175 in height field
  3. Tap "Calculate BMI"
  4. Verify error dialog appears

#### Test Case 2.3: Non-numeric input validation
- **Input**: Weight = "abc", Height = 175cm
- **Expected Result**: Error message "Please enter valid height and weight values."
- **Steps**:
  1. Enter "abc" in weight field
  2. Enter 175 in height field
  3. Tap "Calculate BMI"
  4. Verify error dialog appears

#### Test Case 2.4: Decimal values
- **Input**: Weight = 70.5kg, Height = 175.5cm
- **Expected Result**: Proper BMI calculation with decimal values
- **Steps**:
  1. Enter 70.5 in weight field
  2. Enter 175.5 in height field
  3. Tap "Calculate BMI"
  4. Verify proper calculation result

### 3. UI Test Cases

#### Test Case 3.1: App initialization
- **Expected Result**: App loads with title "BMI Calculator", weight and height input fields, and Calculate BMI button
- **Steps**:
  1. Launch the app
  2. Verify UI elements are present

#### Test Case 3.2: Input field labels
- **Expected Result**: Weight field shows "Weight (kg)" label, Height field shows "Height (cm)" label
- **Steps**:
  1. Launch the app
  2. Verify labels are correct

#### Test Case 3.3: Calculate button functionality
- **Expected Result**: Button triggers BMI calculation when valid inputs are provided
- **Steps**:
  1. Enter valid weight and height values
  2. Tap "Calculate BMI" button
  3. Verify calculation occurs

#### Test Case 3.4: Risk indicator display
- **Expected Result**: Color-coded risk indicator appears after calculation
- **Steps**:
  1. Perform BMI calculation
  2. Verify risk indicator text appears with appropriate color coding

### 4. Reset Functionality Test Cases

#### Test Case 4.1: Reset button functionality
- **Expected Result**: BMI result and input fields are cleared
- **Steps**:
  1. Enter values and calculate BMI
  2. Tap "Reset" button
  3. Verify all results and input fields are cleared

#### Test Case 4.2: Reset after multiple calculations
- **Expected Result**: All results are cleared and can calculate new values
- **Steps**:
  1. Perform multiple calculations
  2. Tap "Reset" button
  3. Enter new values and calculate
  4. Verify new calculation works

### 5. Data Storage Test Cases

#### Test Case 5.1: BMI result storage to Firestore
- **Expected Result**: Calculated BMI results are stored in Firestore
- **Steps**:
  1. Perform BMI calculation
  2. Verify successful storage message
  3. Check Firestore database for stored result

#### Test Case 5.2: Storage error handling
- **Expected Result**: App handles storage errors gracefully
- **Steps**:
  1. Simulate network issues or Firestore unavailability
  2. Perform BMI calculation
  3. Verify appropriate error message or fallback behavior

## Boundary Value Test Cases

### Test Case 6.1: Minimum valid values
- **Input**: Weight = 1kg, Height = 50cm
- **Expected Result**: Valid BMI calculation

### Test Case 6.2: Maximum valid values
- **Input**: Weight = 1000kg, Height = 300cm
- **Expected Result**: Valid BMI calculation

## Edge Cases

#### Test Case 7.1: Very small height
- **Input**: Weight = 70kg, Height = 50cm (unrealistic but valid input)
- **Expected Result**: Proper calculation without crash

#### Test Case 7.2: Very large weight
- **Input**: Weight = 1000kg, Height = 180cm (unrealistic but valid input)
- **Expected Result**: Proper calculation without crash

## Performance Test Cases

#### Test Case 8.1: Calculation speed
- **Expected Result**: BMI calculation completes in under 1 second
- **Steps**:
  1. Enter values
  2. Measure time from tap to result display

#### Test Case 8.2: App startup time
- **Expected Result**: App loads and displays UI in under 5 seconds
- **Steps**:
  1. Launch the app
  2. Measure time to initial UI display

## Expected BMI Categories

- **Underweight**: BMI < 18.5 (Risk Indicator: Yellow = caution)
- **Normal**: 18.5 ≤ BMI < 25 (Risk Indicator: Green = healthy)  
- **Overweight**: 25 ≤ BMI < 30 (Risk Indicator: Yellow = caution)
- **Obese**: BMI ≥ 30 (Risk Indicator: Red = high risk)

## Formula Used
BMI = weight(kg) / [height(m)]²
Where height in meters = height(cm) / 100