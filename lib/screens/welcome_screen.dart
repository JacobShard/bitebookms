import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo and Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.book_fill,
                        size: 60,
                        color: isDark ? Colors.white70 : const Color(0xFF2196F3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to BiteBook',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your Digital Food Passport',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Features List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _buildFeatureItem(
                    icon: CupertinoIcons.star_fill,
                    text: 'Collect stamps from your favorite restaurants',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: CupertinoIcons.gift_fill,
                    text: 'Earn rewards and special offers',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    icon: CupertinoIcons.map_fill,
                    text: 'Discover new places to eat',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: const Color(0xFF2196F3),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2196F3),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}
