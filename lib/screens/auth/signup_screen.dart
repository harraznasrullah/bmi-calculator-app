import 'dart:async';
import 'package:bmi_calc/screens/auth/login_screen.dart';
import 'package:bmi_calc/services/supabase_service.dart';
import 'package:bmi_calc/utils/bmi_history_manager.dart';
import 'package:bmi_calc/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if there's existing local history
      final existingHistory = await BMIHistoryManager.getBMIHistory();
      bool shouldKeepHistory = true; // Default to keeping history
      
      if (existingHistory.isNotEmpty) {
        // Ask user if they want to keep their history using a synchronous approach
        shouldKeepHistory = await _showHistoryRetentionDialog();
      }

      // Call the actual Supabase sign up method
      await SupabaseService.instance.signUp(
        _emailController.text,
        _passwordController.text,
      );
      
      if (mounted) {
        // Show a dialog about email confirmation
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Check your email'),
              content: const Text(
                'A confirmation email has been sent. Please check your email and click the confirmation link to activate your account.'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                    // Process history transfer after closing the dialog
                    _processHistoryTransfer(shouldKeepHistory, existingHistory);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        
        // Update user profile with username in the background (optional)
        Future.delayed(const Duration(milliseconds: 500)).then((_) async {
          try {
            await SupabaseService.instance.updateProfile(
              username: _usernameController.text,
            );
          } catch (e) {
            // Profile update failure should not affect the signup success
            print('Profile update failed after signup: $e');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Signup failed';
        // Check if the error contains a message property
        if (e is Map && e.containsKey('message')) {
          errorMessage = 'Signup failed: ${e['message']}';
        } else if (e.toString().contains('Auth')) {
          // If it's an auth-related error, it might be a Supabase AuthException
          // We'll just display the string representation
          errorMessage = 'Signup failed: ${e.toString()}';
        } else {
          errorMessage = 'Signup failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to process history transfer after signup
  void _processHistoryTransfer(bool shouldKeepHistory, List<Map<String, dynamic>> existingHistory) {
    if (shouldKeepHistory && existingHistory.isNotEmpty) {
      // If user wants to keep history, save each record to Supabase
      for (final record in existingHistory) {
        try {
          SupabaseService.instance.saveBMIResult(
            bmiValue: record['bmi'].toDouble(),
            category: record['category'],
            height: record['height'].toDouble(),
            weight: record['weight'].toDouble(),
            heightUnit: 'cm',
            weightUnit: 'kg',
          );
        } catch (e) {
          print('Failed to migrate history record: $e');
        }
      }
    } else {
      // If user doesn't want to keep history, clear local storage
      BMIHistoryManager.clearHistory();
    }
  }

  Future<bool> _showHistoryRetentionDialog() async {
    Completer<bool> completer = Completer<bool>();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keep Your History?'),
          content: const Text(
            'You have existing BMI calculation history. Would you like to transfer it to your new account?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                completer.complete(false); // Don't keep history
              },
              child: const Text('No, start fresh'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                completer.complete(true); // Keep history
              },
              child: const Text('Yes, transfer history'),
            ),
          ],
        );
      },
    );
    
    return completer.future;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up', style: GoogleFonts.lato()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Sign Up'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}