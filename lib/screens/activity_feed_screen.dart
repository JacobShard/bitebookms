import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text('Activity Feed'),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 10, // Replace with actual activity count
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.bell_fill,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Title',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Activity description goes here',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
