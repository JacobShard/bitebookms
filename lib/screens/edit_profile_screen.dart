import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  DateTime? _selectedDate;
  bool _isPhoneVerified = false;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        setState(() {
          _fullNameController.text = userData['fullName'] ?? '';
          _usernameController.text = userData['username'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _emailController.text = user.email ?? '';
          _selectedDate = userData['dateOfBirth']?.toDate();
          _isPhoneVerified = userData['isPhoneVerified'] ?? false;
          _isEmailVerified = user.emailVerified;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: CupertinoDatePicker(
              initialDateTime: _selectedDate ?? DateTime.now(),
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),
          ),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _verifyPhone() async {
    // Show verification in progress
    showCupertinoDialog(
      context: context,
      builder: (context) => const CupertinoActivityIndicator(),
    );

    try {
      // Here you would typically implement phone verification
      // For example, using Firebase Phone Authentication
      // This is a placeholder for the actual implementation
      await Future.delayed(const Duration(seconds: 2)); // Simulated delay

      setState(() {
        _isPhoneVerified = true;
      });

      if (mounted) {
        Navigator.pop(context); // Dismiss the loading indicator
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Phone number verified successfully!'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss the loading indicator
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to verify phone: $e'),
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

  Future<void> _verifyEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Verification Email Sent'),
              content: const Text(
                  'Please check your email to verify your email address.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to send verification email: $e'),
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
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fullName': _fullNameController.text,
          'username': _usernameController.text,
          'phone': _phoneController.text,
          'dateOfBirth': _selectedDate,
          'isPhoneVerified': _isPhoneVerified,
        });

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to save profile: $e'),
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
  }

  Widget _buildVerificationButton(
      String title, bool isVerified, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isVerified ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isVerified
                  ? [
                      const Color(0xFF4CAF50).withOpacity(0.1),
                      const Color(0xFF4CAF50).withOpacity(0.2),
                    ]
                  : [
                      const Color(0xFF2196F3).withOpacity(0.1),
                      const Color(0xFF64B5F6).withOpacity(0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isVerified
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF1976D2),
                ),
              ),
              Icon(
                isVerified
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.arrow_right_circle_fill,
                color: isVerified
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF1976D2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: const Text('Edit Profile'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveProfile,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoTextField(
                controller: _fullNameController,
                placeholder: 'Full Name',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _usernameController,
                placeholder: 'Username',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Date of Birth'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.black,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.calendar,
                        color: Color(0xFF1976D2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _phoneController,
                placeholder: 'Phone Number',
                keyboardType: TextInputType.phone,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              _buildVerificationButton(
                'Verify Phone Number',
                _isPhoneVerified,
                _verifyPhone,
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                enabled: false,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              _buildVerificationButton(
                'Verify Email',
                _isEmailVerified,
                _verifyEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
