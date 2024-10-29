import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _memorableWordController = TextEditingController();
  final _dobController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReset() async {
    if (_emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _memorableWordController.text.isEmpty ||
        _selectedDate == null ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    try {
      // Verify user details against Firestore
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text)
          .where('username', isEqualTo: _usernameController.text)
          .where('memorableWord', isEqualTo: _memorableWordController.text)
          .where('dateOfBirth', isEqualTo: _selectedDate!.toIso8601String())
          .get();

      if (userQuery.docs.isEmpty) {
        _showError('Invalid user details');
        return;
      }

      // Reset password
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text(
                'Password reset email sent. Please check your email to complete the process.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Failed to reset password: $e');
    }
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: DateTime.now().subtract(const Duration(days: 6570)),
            maximumDate: DateTime.now().subtract(const Duration(days: 4380)),
            minimumDate: DateTime.now().subtract(const Duration(days: 36500)),
            onDateTimeChanged: (DateTime newDate) {
              setState(() => _selectedDate = newDate);
              _dobController.text =
                  '${newDate.day}/${newDate.month}/${newDate.year}';
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        middle: const Text('Reset Password'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _emailController,
                      placeholder: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[800]!
                              : CupertinoColors.systemGrey4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: _usernameController,
                      placeholder: 'Username',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[800]!
                              : CupertinoColors.systemGrey4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: _memorableWordController,
                      placeholder: 'Memorable Word',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[800]!
                              : CupertinoColors.systemGrey4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showDatePicker,
                      child: CupertinoTextField(
                        controller: _dobController,
                        placeholder: 'Date of Birth',
                        enabled: false,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: _newPasswordController,
                      placeholder: 'New Password',
                      obscureText: true,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[800]!
                              : CupertinoColors.systemGrey4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: _confirmPasswordController,
                      placeholder: 'Confirm New Password',
                      obscureText: true,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[800]!
                              : CupertinoColors.systemGrey4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: const Color(0xFF2196F3),
                        onPressed: _handleReset,
                        child: const Text('Change Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _memorableWordController.dispose();
    _dobController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
