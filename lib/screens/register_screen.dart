import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'main_screen.dart';
import 'welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _memorableWordController =
      TextEditingController();
  DateTime? _selectedDate;
  DateTime? _tempSelectedDate;
  bool _isLocationEnabled = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final _emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
  final _passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
  final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('OK'),
                    onPressed: () {
                      setState(() => _selectedDate = _tempSelectedDate);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime:
                      DateTime.now().subtract(const Duration(days: 6570)),
                  maximumDate:
                      DateTime.now().subtract(const Duration(days: 4380)),
                  minimumDate:
                      DateTime.now().subtract(const Duration(days: 36500)),
                  onDateTimeChanged: (DateTime newDate) {
                    _tempSelectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  bool _validateFields() {
    if (_firstNameController.text.isEmpty) {
      _showError('Please enter your first name');
      return false;
    }
    if (_lastNameController.text.isEmpty) {
      _showError('Please enter your last name');
      return false;
    }
    if (_usernameController.text.isEmpty) {
      _showError('Please enter a username');
      return false;
    }
    if (!_usernameRegex.hasMatch(_usernameController.text)) {
      _showError(
          'Username must be 3-20 characters long and can only contain letters, numbers, and underscores');
      return false;
    }
    if (_selectedDate == null) {
      _showError('Please select your date of birth');
      return false;
    }
    if (_memorableWordController.text.isEmpty) {
      _showError('Please enter a memorable word');
      return false;
    }
    if (_memorableWordController.text.length < 6) {
      _showError('Memorable word must be at least 6 characters long');
      return false;
    }
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email');
      return false;
    }
    if (!_emailRegex.hasMatch(_emailController.text.trim())) {
      _showError('Please enter a valid email address');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter a password');
      return false;
    }
    if (!_passwordRegex.hasMatch(_passwordController.text)) {
      _showError(
          'Password must contain at least 8 characters, including uppercase, lowercase, number, and special character');
      return false;
    }
    return true;
  }

  Future<void> _handleRegistration() async {
    if (!_validateFields()) return;

    setState(() => _isLoading = true);

    try {
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _usernameController.text)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        _showError('Username already taken');
        return;
      }

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'username': _usernameController.text,
        'memorableWord': _memorableWordController.text,
        'dateOfBirth': _selectedDate!.toIso8601String(),
        'locationEnabled': _isLocationEnabled,
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError(e.message ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('An unexpected error occurred');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return CupertinoPageScaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        middle: const Text('Register'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WelcomeScreen(),
              ),
            );
          },
        ),
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
                      controller: _firstNameController,
                      placeholder: 'First Name',
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
                      controller: _lastNameController,
                      placeholder: 'Last Name',
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
                    GestureDetector(
                      onTap: _showDatePicker,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : CupertinoColors.systemGrey4,
                          ),
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
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.calendar,
                              color: CupertinoColors.systemGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      controller: _memorableWordController,
                      placeholder: 'Memorable Word (min. 6 characters)',
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
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        CupertinoTextField(
                          controller: _passwordController,
                          placeholder: 'Password',
                          obscureText: !_isPasswordVisible,
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
                        CupertinoButton(
                          padding: const EdgeInsets.only(right: 8),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          child: Icon(
                            _isPasswordVisible
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: const Color(0xFF2196F3),
                        onPressed: _isLoading ? null : _handleRegistration,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text('Register'),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _memorableWordController.dispose();
    super.dispose();
  }
}
