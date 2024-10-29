import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class StampService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a secure QR code that includes:
  // - User ID
  // - Timestamp
  // - Zone
  // - Signature to prevent tampering
  Future<String> generateSecureQRCode(String zone) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'userId': user.uid,
      'timestamp': timestamp,
      'zone': zone,
    };

    // Create a signature to prevent QR code tampering
    final signature = _generateSignature(data);
    data['signature'] = signature;

    // Convert to JSON and encode for QR code
    return base64Encode(utf8.encode(json.encode(data)));
  }

  // Verify and process a scan from an eatery
  Future<void> processStampScan(String qrData, String eateryId) async {
    // Decode and verify the QR data
    final decodedData = json.decode(utf8.decode(base64Decode(qrData)));

    // Verify signature
    final signature = decodedData['signature'];
    decodedData.remove('signature');
    if (signature != _generateSignature(decodedData)) {
      throw Exception('Invalid QR code signature');
    }

    // Check timestamp to prevent reuse (e.g., within 5 minutes)
    final scanTime = DateTime.now().millisecondsSinceEpoch;
    final qrTime = decodedData['timestamp'] as int;
    if (scanTime - qrTime > 300000) {
      // 5 minutes
      throw Exception('QR code expired');
    }

    // Get user reference
    final userRef = _firestore.collection('users').doc(decodedData['userId']);

    // Update stamps in a transaction to ensure consistency
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final zone = decodedData['zone'];
      final stamps = (userData['stamps'] ?? {});
      final zoneStamps = (stamps[zone] ?? 0) + 1;

      // Update stamps
      stamps[zone] = zoneStamps;

      // Record stamp history
      final stampHistory = {
        'timestamp': scanTime,
        'eateryId': eateryId,
        'zone': zone,
      };

      // Update user document
      transaction.update(userRef, {
        'stamps': stamps,
        'stampHistory': FieldValue.arrayUnion([stampHistory]),
      });

      // Check if user earned a reward (9 stamps)
      if (zoneStamps == 9) {
        // Create reward
        final rewardRef = _firestore.collection('rewards').doc();
        transaction.set(rewardRef, {
          'userId': decodedData['userId'],
          'zone': zone,
          'created': scanTime,
          'used': false,
        });

        // Reset stamps for this zone
        stamps[zone] = 0;
        transaction.update(userRef, {'stamps': stamps});
      }
    });
  }

  // Generate a signature for QR code data
  String _generateSignature(Map<String, dynamic> data) {
    // In production, use a secure key stored in environment variables
    const secretKey = 'your-secret-key';
    final content = json.encode(data) + secretKey;
    return sha256.convert(utf8.encode(content)).toString();
  }

  // Get user's stamps for a zone
  Future<int> getZoneStamps(String zone) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return 0;

    final stamps = doc.data()?['stamps'] ?? {};
    return stamps[zone] ?? 0;
  }

  // Listen to stamp changes in real-time
  Stream<Map<String, int>> listenToStamps() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value({});
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return {};
      final stamps = doc.data()?['stamps'] ?? {};
      return Map<String, int>.from(stamps);
    });
  }
}
