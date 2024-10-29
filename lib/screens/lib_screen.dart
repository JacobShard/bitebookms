import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LibScreen extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const LibScreen({
    Key? key,
    required this.isDark,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        middle: Text(
          'Library',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      child: Center(
        child: Text(
          'Library Screen',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
