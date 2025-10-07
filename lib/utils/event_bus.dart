import 'dart:async';

class EventBus {
  static EventBus? _instance;
  static EventBus get instance => _instance ??= EventBus._();
  EventBus._();

  final StreamController<String> _streamController = StreamController<String>.broadcast();
  
  Stream<String> get stream => _streamController.stream;
  
  void emit(String event) {
    _streamController.add(event);
  }
  
  void dispose() {
    _streamController.close();
  }
}

class Events {
  static const String bmiCalculated = 'bmi_calculated';
  static const String userLoggedIn = 'user_logged_in';
  static const String userSignedOut = 'user_signed_out';
}