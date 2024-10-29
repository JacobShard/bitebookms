import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'main_screen.dart';
import 'welcome_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

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

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

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
        _showError(e.message ?? 'Login failed');
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
        middle: const Text('Login'),
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
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Forgot Password? ',
                          style: TextStyle(
                            fontSize: 14, // Reduced from default size
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const ResetPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Reset it here',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF2196F3),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
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
    _passwordController.dispose();
    super.dispose();
  }
}
