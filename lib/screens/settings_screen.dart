import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmi_calc/screens/auth/login_screen.dart';
import 'package:bmi_calc/screens/auth/signup_screen.dart';
import 'package:bmi_calc/screens/auth/change_password_screen.dart';
import 'package:bmi_calc/services/supabase_service.dart';

// Settings Screen Widget
// This screen provides access to application settings and user preferences

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SupabaseClient _client;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'Settings',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Get current auth status
          final isAuthenticated = _client.auth.currentUser != null;
          final user = _client.auth.currentUser;
          
          // If auth state is loading, show progress indicator
          if (snapshot.connectionState == ConnectionState.waiting ||
              (snapshot.hasData && snapshot.data == null)) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return _buildSettingsContent(context, isAuthenticated);
        },
      ),
    );
  }

  // Remove the _checkAuthStatus method since we're now using StreamBuilder

  Widget _buildSettingsContent(BuildContext context, bool isAuthenticated) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(
                  isAuthenticated ? Icons.person : Icons.person_outline,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAuthenticated 
                          ? (_client.auth.currentUser?.email ?? 'User Profile') 
                          : 'Guest Profile',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isAuthenticated 
                          ? 'Manage your account and preferences' 
                          : 'Sign in to sync your data across devices',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Settings Options
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Settings',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    leading: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                    title: Text('Notifications', style: GoogleFonts.lato()),
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {},
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                    title: Text('Language', style: GoogleFonts.lato()),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
                    title: Text('Dark Mode', style: GoogleFonts.lato()),
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {},
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Account Management
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Management',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (isAuthenticated) ...[
                    ListTile(
                      leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                      title: Text('Change Password', style: GoogleFonts.lato()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
                      title: Text('Logout', style: GoogleFonts.lato()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        try {
                          await SupabaseService.instance.signOut();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Successfully logged out'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ] else ...[
                    ListTile(
                      leading: Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
                      title: Text('Login', style: GoogleFonts.lato()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary),
                      title: Text('Sign Up', style: GoogleFonts.lato()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}