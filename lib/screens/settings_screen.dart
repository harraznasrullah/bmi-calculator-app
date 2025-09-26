import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Settings Screen Widget
// This screen provides access to application settings and user preferences

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      body: Padding(
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
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Profile',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Manage your account and preferences',
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
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                      title: Text('Language', style: GoogleFonts.lato()),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                    Divider(),
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
                    ListTile(
                      leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                      title: Text('Change Password', style: GoogleFonts.lato()),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
                      title: Text('Logout', style: GoogleFonts.lato()),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}