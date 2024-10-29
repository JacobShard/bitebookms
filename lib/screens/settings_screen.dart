import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to sign out. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        middle: Text(
          'Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSection(
              isDark,
              'Account Settings',
              [
                _buildSettingItem(
                  isDark,
                  'Edit Profile',
                  CupertinoIcons.person,
                  onTap: () {
                    // Navigate to edit profile
                  },
                ),
                _buildSettingItem(
                  isDark,
                  'Change Password',
                  CupertinoIcons.lock,
                  onTap: () {
                    // Navigate to change password
                  },
                ),
                _buildSettingItem(
                  isDark,
                  'Privacy Settings',
                  CupertinoIcons.shield,
                  onTap: () {
                    // Navigate to privacy settings
                  },
                ),
              ],
            ),
            _buildSection(
              isDark,
              'App Settings',
              [
                _buildSettingItem(
                  isDark,
                  'Dark Mode',
                  isDark ? CupertinoIcons.moon_fill : CupertinoIcons.moon,
                  trailing: CupertinoSwitch(
                    value: isDark,
                    onChanged: (value) => themeProvider.toggleTheme(),
                    activeColor: const Color(0xFF2196F3),
                  ),
                ),
                _buildSettingItem(
                  isDark,
                  'Notifications',
                  CupertinoIcons.bell,
                  onTap: () {
                    // Navigate to notifications settings
                  },
                ),
                _buildSettingItem(
                  isDark,
                  'Location Services',
                  CupertinoIcons.location,
                  onTap: () {
                    // Navigate to location settings
                  },
                ),
              ],
            ),
            _buildSection(
              isDark,
              'Support',
              [
                _buildSettingItem(
                  isDark,
                  'Help Center',
                  CupertinoIcons.question_circle,
                  onTap: () {
                    // Navigate to help center
                  },
                ),
                _buildSettingItem(
                  isDark,
                  'Contact Us',
                  CupertinoIcons.mail,
                  onTap: () {
                    // Navigate to contact page
                  },
                ),
                _buildSettingItem(
                  isDark,
                  'About',
                  CupertinoIcons.info_circle,
                  onTap: () {
                    // Navigate to about page
                  },
                ),
              ],
            ),
            _buildSection(
              isDark,
              'Account',
              [
                _buildSettingItem(
                  isDark,
                  'Sign Out',
                  CupertinoIcons.square_arrow_right,
                  textColor: CupertinoColors.destructiveRed,
                  onTap: () => _handleSignOut(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(bool isDark, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
              bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    bool isDark,
    String title,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: textColor ?? (isDark ? Colors.white70 : Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(
                CupertinoIcons.right_chevron,
                size: 16,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}
