import 'dart:async';
import 'package:bmi_calc/screens/auth/signup_screen.dart';
import 'package:bmi_calc/services/supabase_service.dart';
import 'package:bmi_calc/services/sync_service.dart';
import 'package:bmi_calc/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the actual Supabase sign in method
      await SupabaseService.instance.signIn(
        _emailController.text,
        _passwordController.text,
      );

      // Emit login event to notify other screens to refresh data
      EventBus.instance.emit(Events.userLoggedIn);

      // Trigger automatic sync for any pending records
      try {
        await SyncService.syncPendingRecords();
      } catch (e) {
        // Sync failed, but login was successful
        print('Auto-sync failed: $e');
      }

      if (mounted) {
        // Check if there's local BMI data to transfer
        final hasLocalData = await SyncService.hasLocalBMIData();
        if (hasLocalData) {
          final localDataCount = await SyncService.getLocalBMIDataCount();
          _showBMIDataTransferDialog(localDataCount);
        } else {
          // No local data, just show success and navigate
          _completeLogin();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed';
        String fullError = e.toString();
        
        // Check if the error contains specific messages
        if (fullError.contains('email_not_confirmed')) {
          // Show a dialog for email confirmation
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Email Not Confirmed'),
                content: const Text(
                  'Your email address has not been confirmed yet. Please check your email and click the confirmation link.'
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Check if the error contains a message property
          if (e is Map && e.containsKey('message')) {
            errorMessage = 'Login failed: ${e['message']}';
          } else if (fullError.contains('Auth')) {
            // If it's an auth-related error, extract the specific message
            errorMessage = 'Login failed: ${fullError.substring(fullError.indexOf('message:') + 8, fullError.contains(',') ? fullError.indexOf(',') : fullError.length).trim()}';
          } else {
            errorMessage = 'Login failed: ${fullError}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: GoogleFonts.lato()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text("Don't have an account? Sign up"),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // For now, just go back to previous screen
                  Navigator.of(context).pop();
                },
                child: const Text("Continue as guest"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBMIDataTransferDialog(int localDataCount) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.sync, color: Colors.blue[600], size: 24),
              const SizedBox(width: 8),
              Text('Transfer BMI Data?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We found $localDataCount BMI record${localDataCount > 1 ? 's' : ''} from your previous use of the app.',
                style: GoogleFonts.lato(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Would you like to transfer these records to your account? This will:',
                style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...[
                '✓ Add your BMI history to this account',
                '✓ Make your data available on all devices',
                '✓ Keep your data safe in the cloud'
              ].map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  item,
                  style: GoogleFonts.lato(fontSize: 13, color: Colors.grey[700]),
                ),
              )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Local data will be removed after successful transfer',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeLogin(); // Continue without transferring
              },
              child: Text(
                'Skip Transfer',
                style: GoogleFonts.lato(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close the dialog first
                Navigator.of(context).pop();

                // Perform transfer in background without blocking UI
                unawaited(_performDataTransfer(localDataCount));

                // Complete login immediately
                _completeLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Transfer Data',
                style: GoogleFonts.lato(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _completeLogin() {
    if (mounted) {
      // Navigate back to previous screen with success
      Navigator.of(context).pop();
      // Optionally show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Background data transfer method that doesn't block UI
  Future<void> _performDataTransfer(int localDataCount) async {
    try {
      final success = await SyncService.transferLocalBMIDataToAccount();
      // Transfer completed - you could emit an event here if needed
      print('Background transfer completed: $success, transferred $localDataCount records');
    } catch (e) {
      // Transfer failed - log error but don't hang the app
      print('Background transfer failed: $e');
    }
  }
}