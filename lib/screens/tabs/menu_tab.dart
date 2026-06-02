import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MenuTab extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MenuTab({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Try Prompt User';
    final email = user?.email ?? 'premium.user@tryprompts.com';
    final photoUrl = user?.photoURL;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section (Centered, without background)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'T',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[800]?.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.amber[800]!.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'PRO MEMBER',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Settings Section Title
            Text(
              'App Customization',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Customization Options Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Dark Mode Switch
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dark_mode,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isDark ? 'Dark theme enabled' : 'Light theme enabled',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: isDark,
                      activeTrackColor: primaryColor,
                      onChanged: (bool value) {
                        onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  
                  // Notifications Switch
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Daily Reminders',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Notify me of daily prompt updates',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: true,
                      activeTrackColor: primaryColor,
                      onChanged: (bool value) {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // More Options Title
            Text(
              'Account & Support',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Support Settings List
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    context,
                    icon: Icons.sync,
                    iconColor: Colors.green,
                    title: 'Sync Account Data',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingRow(
                    context,
                    icon: Icons.shield,
                    iconColor: Colors.purple,
                    title: 'Privacy & Permissions',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingRow(
                    context,
                    icon: Icons.help_outline,
                    iconColor: Colors.orange,
                    title: 'Help Center & Feedback',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingRow(
                    context,
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    title: 'Logout / Sign Out',
                    onTap: () async {
                      await GoogleSignIn().signOut();
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Version Indicator
            Center(
              child: Text(
                'Try Prompt v1.0.0 (Beta)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
