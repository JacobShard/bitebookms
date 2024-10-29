import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

class ProfileSignupScreen extends StatefulWidget {
  const ProfileSignupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSignupScreen> createState() => _ProfileSignupScreenState();
}

class _ProfileSignupScreenState extends State<ProfileSignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleProfileSetup() async {
    if (_usernameController.text.isEmpty) {
      _showError('Please enter a username');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _usernameController.text,
          'bio': _bioController.text,
          'profileCompleted': true,
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('Failed to update profile');
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text('Complete Profile'),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _usernameController,
                      placeholder: 'Username',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: _bioController,
                      placeholder: 'Bio (optional)',
                      padding: const EdgeInsets.all(12),
                      maxLines: 3,
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: const Color(0xFF2196F3),
                        onPressed: _isLoading ? null : _handleProfileSetup,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text('Complete Setup'),
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
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
