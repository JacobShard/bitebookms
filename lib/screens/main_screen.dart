import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'activity_feed_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Controllers
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _feedScrollController = ScrollController();
  GoogleMapController? _mapController;

  // State variables
  Map<String, int> _socialCounts = {
    'friends': 0,
    'followers': 0,
    'following': 0,
  };

  final List<Map<String, dynamic>> _userPosts = [];
  String? _pinnedPostId;

  String _selectedCategory = 'Stamp Card';
  String _selectedZone = 'Merseyside';
  String _selectedFoodieSection = 'Stamp Cards';
  final Set<Marker> _markers = {};
  bool _isSearchVisible = false;
  bool _isFilterVisible = false;
  final List<String> _selectedFilters = [];
  final List<String> _foodieSections = ['Stamp Cards', 'Map', 'Discounts'];
  final List<String> _categories = [
    'Coffee Shops',
    'Bistros',
    'Restaurants',
    'Takeaways'
  ];
  int _notificationCount = 2;

  // Add these new variables
  bool _isOffline = false;
  bool _isLoading = true;

  final Map<String, int> _zoneStamps = {
    'Merseyside': 2,
    'Manchester': 1,
    'Midlands': 3,
    'London': 0,
    'Scotland': 4,
    'Wales': 2,
    'Cornwall': 1,
  };

  final Map<String, LatLng> _zoneLocations = {
    'Merseyside': const LatLng(53.4084, -2.9916),
    'Manchester': const LatLng(53.4808, -2.2426),
    'Midlands': const LatLng(52.4862, -1.8904),
    'London': const LatLng(51.5074, -0.1278),
    'Scotland': const LatLng(55.9533, -3.1883),
    'Wales': const LatLng(52.1307, -3.7837),
    'Cornwall': const LatLng(50.2660, -5.0527),
  };

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _postController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    _feedScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    try {
      _isOffline = !(await _checkConnectivity());
      if (!_isOffline) {
        await _initializeMarkers();
        await _loadSocialCounts();
        await _loadUserPosts();
      }
    } catch (e) {
      print('Error initializing app: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeMarkers() async {
    _markers.clear();
    final currentLocation = _zoneLocations[_selectedZone];
    if (currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentZone'),
          position: currentLocation,
          infoWindow: InfoWindow(
            title: _selectedZone,
            snippet: 'Participating restaurants in this area',
          ),
        ),
      );
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _retryLoading() async {
    setState(() => _isLoading = true);
    try {
      _isOffline = !(await _checkConnectivity());
      if (!_isOffline) {
        await _initializeApp();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildNetworkImage(String imageUrl, {double? height, BoxFit? fit}) {
    return Image.network(
      imageUrl,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          color: Colors.grey[300],
          child: const Icon(
            CupertinoIcons.photo,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Future<void> _loadSocialCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        setState(() {
          _socialCounts = {
            'friends': userData['friendsCount'] ?? 0,
            'followers': userData['followersCount'] ?? 0,
            'following': userData['followingCount'] ?? 0,
          };
        });
      }
    }
  }

  Future<void> _loadUserPosts() async {
    // Implement your user posts loading logic here
  }

  Future<void> _handleImageSelection(bool isDark, ThemeData theme) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await showCupertinoModalPopup<XFile?>(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: Text(
            'Add Photo',
            style: TextStyle(
              color: isDark ? Colors.white70 : null,
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context,
                    await picker.pickImage(source: ImageSource.camera));
              },
              child: Text(
                'Take Photo',
                style: TextStyle(
                  color: isDark ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context,
                    await picker.pickImage(source: ImageSource.gallery));
              },
              child: Text(
                'Choose from Library',
                style: TextStyle(
                  color: isDark ? theme.colorScheme.primary : null,
                ),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.red[300] : null,
              ),
            ),
          ),
        ),
      );

      if (image != null) {
        await _uploadImage(image, isDark, theme);
      }
    } catch (e) {
      _showErrorDialog('Failed to upload image: $e', isDark, theme);
    }
  }

  Future<void> _uploadImage(XFile image, bool isDark, ThemeData theme) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_posts')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final file = File(image.path);
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'content': _postController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    }
  }

  void _showFullImage(String imageUrl, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        color: isDark ? Colors.black : CupertinoColors.black,
        child: Stack(
          children: [
            Center(
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: CupertinoButton(
                child: Icon(
                  CupertinoIcons.xmark,
                  color: isDark ? Colors.white70 : CupertinoColors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    if (kIsWeb) {
      final mediaQuery = MediaQuery.of(context);
      return mediaQuery.size.width < 600
          ? _buildIOSLayout(isDark, theme)
          : _buildDefaultLayout(isDark, theme);
    }
    return Platform.isIOS
        ? _buildIOSLayout(isDark, theme)
        : _buildDefaultLayout(isDark, theme);
  }

  Widget _buildDefaultLayout(bool isDark, ThemeData theme) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.grey[850]!,
                      Colors.grey[900]!,
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF5F9FF),
                    ],
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.grey[850]!,
                          Colors.grey[900]!,
                        ]
                      : [
                          const Color(0xFFE3F2FD),
                          const Color(0xFFBBDEFB),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark ? Colors.black26 : Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: SvgPicture.asset(
                'assets/logo.svg',
                height: 30,
                color: isDark ? Colors.white70 : null,
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF64B5F6),
                        const Color(0xFF2196F3),
                      ]
                    : [
                        const Color(0xFF2196F3),
                        const Color(0xFF64B5F6),
                      ],
              ).createShader(bounds),
              child: Text(
                'BiteBook',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _buildIOSHomeTab(isDark, theme),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C2C)
              : theme.bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black12,
              blurRadius: 8,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: isDark
              ? const Color(0xFF2C2C2C)
              : theme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: isDark
              ? Colors.grey[400]
              : theme.bottomNavigationBarTheme.unselectedItemColor,
          type: BottomNavigationBarType.fixed,
          currentIndex: _foodieSections.indexOf(_selectedFoodieSection),
          onTap: (index) {
            setState(() {
              _selectedFoodieSection = _foodieSections[index];
            });
          },
          items: [
            _buildBottomNavItem(
              Icons.credit_card_outlined,
              'Stamp Cards',
              _notificationCount,
              isDark,
              theme,
            ),
            _buildBottomNavItem(
              Icons.map_outlined,
              'Map',
              0,
              isDark,
              theme,
            ),
            _buildBottomNavItem(
              Icons.local_offer_outlined,
              'Discounts',
              0,
              isDark,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    IconData icon,
    String label,
    int notificationCount,
    bool isDark,
    ThemeData theme,
  ) {
    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Icon(
            icon,
            color: isDark ? Colors.white70 : null,
          ),
          if (notificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  notificationCount.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }

  Widget _buildIOSLayout(bool isDark, ThemeData theme) {
    return CupertinoTabScaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      tabBar: CupertinoTabBar(
        backgroundColor:
            isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.grey[800]!.withOpacity(0.2)
                : CupertinoColors.systemGrey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        activeColor: theme.colorScheme.primary,
        inactiveColor: isDark
            ? Colors.grey[400]!
            : CupertinoColors.systemGrey.resolveFrom(context),
        items: [
          _buildTabBarItem(CupertinoIcons.home, 'Home', isDark, theme),
          _buildTabBarItem(CupertinoIcons.qrcode, 'Scan', isDark, theme),
          _buildTabBarItem(
              CupertinoIcons.star_fill, 'Foodie Passport', isDark, theme),
          _buildNotificationTabBarItem(isDark, theme),
          _buildTabBarItem(CupertinoIcons.person, 'Profile', isDark, theme),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0:
                return _buildIOSHomeTab(isDark, theme);
              case 1:
                return _buildIOSPayTab(isDark, theme);
              case 2:
                return _buildIOSFoodiePassportTab(isDark, theme);
              case 3:
                return const ActivityFeedScreen();
              case 4:
                return _buildIOSProfileTab(isDark, theme);
              default:
                return _buildIOSHomeTab(isDark, theme);
            }
          },
        );
      },
    );
  }

  BottomNavigationBarItem _buildTabBarItem(
    IconData icon,
    String label,
    bool isDark,
    ThemeData theme,
  ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.grey[850]!.withOpacity(0.1),
                    Colors.grey[900]!.withOpacity(0.2),
                  ]
                : [
                    const Color(0xFFE3F2FD).withOpacity(0.1),
                    const Color(0xFFBBDEFB).withOpacity(0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black26
                  : CupertinoColors.systemGrey.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: isDark ? Colors.white70 : null,
        ),
      ),
      label: label,
    );
  }

  BottomNavigationBarItem _buildNotificationTabBarItem(
      bool isDark, ThemeData theme) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[850]!.withOpacity(0.1),
                        Colors.grey[900]!.withOpacity(0.2),
                      ]
                    : [
                        const Color(0xFFE3F2FD).withOpacity(0.1),
                        const Color(0xFFBBDEFB).withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black26
                      : CupertinoColors.systemGrey.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.list_bullet,
              size: 24,
              color: isDark ? Colors.white70 : null,
            ),
          ),
          if (_notificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _notificationCount.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      label: 'Activity',
    );
  }

  Widget _buildIOSHomeTab(bool isDark, ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;

    // Add these loading and offline checks at the start
    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_isOffline) {
      return CupertinoPageScaffold(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.wifi_slash,
                size: 48,
                color: isDark ? Colors.white70 : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No Internet Connection',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                child: const Text('Retry'),
                onPressed: _retryLoading,
              ),
            ],
          ),
        ),
      );
    }

    // Your existing user check
    if (user == null) {
      return CupertinoPageScaffold(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
        child: Center(
          child: CupertinoButton(
            child: Text(
              'Please Login',
              style: TextStyle(
                color: isDark ? Colors.white70 : theme.colorScheme.primary,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ),
      );
    }

    // Rest of your existing _buildIOSHomeTab code...
    return CupertinoPageScaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
          // Your existing navigation bar code...
          ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSearchVisible)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black,
                    ),
                    backgroundColor:
                        isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  ),
                ),
              if (_isFilterVisible)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black),
                            ),
                          ),
                          onPressed: () => _handleCategorySelection(category),
                        ),
                      );
                    },
                  ),
                ),
              _buildWelcomeCard(isDark, theme),
              const SizedBox(height: 20),
              _buildStampProgress(isDark, theme),
              const SizedBox(height: 20),
              _buildRewardsList(isDark, theme),
              const SizedBox(height: 20),
              if (_userPosts.isNotEmpty) ...[
                Text(
                  'Your Posts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userPosts.length,
                  itemBuilder: (context, index) {
                    final post = _userPosts[index];
                    final isPinned = post['id'] == _pinnedPostId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.grey.withOpacity(0.1),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPinned)
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.pin_fill,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinned Post',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          Text(
                            post['content'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black,
                            ),
                          ),
                          if (post['imageUrl'] != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showFullImage(
                                post['imageUrl'] as String,
                                isDark,
                              ),
                              child: _buildNetworkImage(
                                // Changed to use _buildNetworkImage
                                post['imageUrl'] as String,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ]
              : [
                  CupertinoColors.white,
                  const Color(0xFFF5F9FF),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : CupertinoColors.systemGrey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: isDark
                ? Colors.grey[900]!.withOpacity(0.7)
                : CupertinoColors.white.withOpacity(0.7),
            offset: const Offset(0, -1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to BiteBook!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF64B5F6),
                          const Color(0xFF2196F3),
                        ]
                      : [
                          const Color(0xFF2196F3),
                          const Color(0xFF64B5F6),
                        ],
                ).createShader(
                  const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[850]!,
                        Colors.grey[900]!,
                      ]
                    : [
                        const Color(0xFFE3F2FD),
                        const Color(0xFFBBDEFB),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black26
                      : CupertinoColors.systemGrey.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              'Discover great restaurants and earn rewards!',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : const Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSPayTab(bool isDark, ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    final qrData = user?.uid ?? '';

    return CupertinoPageScaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.grey[800]!.withOpacity(0.2)
                : CupertinoColors.systemGrey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        middle: Text(
          'Scan',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.grey[850]!.withOpacity(0.1),
                          Colors.grey[900]!.withOpacity(0.2),
                        ]
                      : [
                          const Color(0xFF2196F3).withOpacity(0.1),
                          const Color(0xFF64B5F6).withOpacity(0.2),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Scan to earn stamps',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF1976D2),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black26
                        : CupertinoColors.systemGrey.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor:
                    isDark ? const Color(0xFF2C2C2C) : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSFoodiePassportTab(bool isDark, ThemeData theme) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        middle: Text(
          'Foodie Passport',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Zone Selector at the top
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black26
                        : Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Zone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showZonePicker(isDark, theme),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedZone,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF1976D2),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_down,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF1976D2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black,
                        ),
                        backgroundColor: Colors.transparent,
                        placeholder: 'Search a location...',
                        placeholderStyle: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black26
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: _toggleFilters,
                      child: Icon(
                        CupertinoIcons.slider_horizontal_3,
                        color: isDark ? Colors.white70 : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Content based on selected section
                  Expanded(
                    child: _buildContent(isDark, theme),
                  ),

                  // Navigation Tabs at the bottom
                  Container(
                    height: 50,
                    margin: const EdgeInsets.all(16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _foodieSections.length,
                      itemBuilder: (context, index) {
                        final section = _foodieSections[index];
                        final isSelected = _selectedFoodieSection == section;
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 8,
                            right: index == _foodieSections.length - 1 ? 0 : 8,
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.white),
                            child: Text(
                              section,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedFoodieSection = section;
                              });
                            },
                          ),
                        );
                      },
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

  Widget _buildContent(bool isDark, ThemeData theme) {
    switch (_selectedFoodieSection) {
      case 'Stamp Cards':
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildStampProgress(isDark, theme),
              const SizedBox(height: 20),
              _buildRewardsList(isDark, theme),
            ],
          ),
        );
      case 'Map':
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _zoneLocations[_selectedZone] ??
                    const LatLng(53.4084, -2.9916),
                zoom: 12,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        );
      case 'Discounts':
        return SingleChildScrollView(
          child: _buildDiscountsList(isDark, theme),
        );
      default:
        return Container();
    }
  }

  Widget _buildIOSProfileTab(bool isDark, ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? 'User';

    return CupertinoPageScaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.grey[800]!.withOpacity(0.2)
                : CupertinoColors.systemGrey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        middle: Text(
          username,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.settings,
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(isDark, theme),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildStatColumn(_socialCounts['friends'].toString(),
                      'Friends', isDark, theme),
                  buildStatColumn(_socialCounts['followers'].toString(),
                      'Followers', isDark, theme),
                  buildStatColumn(_socialCounts['following'].toString(),
                      'Following', isDark, theme),
                ],
              ),
              const SizedBox(height: 20),
              _buildActionButtons(isDark, theme),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF1976D2),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showPostDialog(isDark, theme),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _userPosts.isEmpty
                                    ? 'SHARE YOUR FOOD WITH THE WORLD.\nUPLOAD YOUR FIRST POST.'
                                    : 'Share your food thoughts',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF1976D2),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black26
                                        : Colors.grey.withOpacity(0.2),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: CupertinoButton(
                                padding: const EdgeInsets.all(8),
                                onPressed: () =>
                                    _handleImageSelection(isDark, theme),
                                child: Icon(
                                  CupertinoIcons.camera_fill,
                                  color: isDark ? Colors.black : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_userPosts.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _userPosts.length,
                        itemBuilder: (context, index) {
                          return _buildPostItem(
                              _userPosts[index], isDark, theme);
                        },
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showZonePicker(bool isDark, ThemeData theme) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 200,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: _zoneLocations.keys.toList().indexOf(_selectedZone),
            ),
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                _selectedZone = _zoneLocations.keys.toList()[selectedItem];
              });
            },
            children: _zoneLocations.keys
                .map(
                  (zone) => Center(
                    child: Text(
                      zone,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message, bool isDark, ThemeData theme) {
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            'Error',
            style: TextStyle(
              color: isDark ? Colors.white70 : null,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white70 : null,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'OK',
                style: TextStyle(
                  color: isDark ? theme.colorScheme.primary : null,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDiscountsList(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ]
              : [
                  CupertinoColors.white,
                  const Color(0xFFF5F9FF),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : CupertinoColors.systemGrey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Available Discounts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 16),
          _buildDiscountItem(
            'Happy Hour',
            '20% off between 3-5pm',
            const Color(0xFF4CAF50),
            CupertinoIcons.clock,
            isDark,
            theme,
          ),
          _buildDiscountItem(
            'Student Discount',
            '15% off with valid ID',
            const Color(0xFFE91E63),
            CupertinoIcons.book,
            isDark,
            theme,
          ),
          _buildDiscountItem(
            'First Visit',
            '10% off your first order',
            const Color(0xFFFFD700),
            CupertinoIcons.gift,
            isDark,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountItem(
    String title,
    String description,
    Color color,
    IconData icon,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!.withOpacity(0.1),
                  Colors.grey[900]!.withOpacity(0.2),
                ]
              : [
                  color.withOpacity(0.1),
                  color.withOpacity(0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : color.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[800]!,
                        Colors.grey[900]!,
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : color.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editPost(Map<String, dynamic> post, bool isDark, ThemeData theme) {
    final TextEditingController editController =
        TextEditingController(text: post['content'] as String);

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          'Edit Post',
          style: TextStyle(
            color: isDark ? Colors.white70 : null,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: CupertinoTextField(
            controller: editController,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            maxLines: 3,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : null,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.red[300] : null,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text(
              'Save',
              style: TextStyle(
                color: isDark ? theme.colorScheme.primary : null,
              ),
            ),
            onPressed: () async {
              if (editController.text.isNotEmpty) {
                final updatedPost = Map<String, dynamic>.from(post);
                updatedPost['content'] = editController.text;

                setState(() {
                  final index = _userPosts.indexOf(post);
                  _userPosts[index] = updatedPost;
                });

                try {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(post['id'] as String)
                      .update({'content': editController.text});
                } catch (e) {
                  // Handle offline state
                }

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _deletePost(Map<String, dynamic> post, bool isDark, ThemeData theme) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          'Delete Post',
          style: TextStyle(
            color: isDark ? Colors.white70 : null,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(
            color: isDark ? Colors.white70 : null,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : null,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              setState(() {
                _userPosts.remove(post);
                if (_pinnedPostId == post['id']) {
                  _pinnedPostId = null;
                }
              });

              try {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(post['id'] as String)
                    .delete();
              } catch (e) {
                // Handle offline state
              }

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(
      Map<String, dynamic> post, bool isDark, ThemeData theme) {
    final isPinned = post['id'] == _pinnedPostId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isPinned)
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.pin_fill,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pinned Post',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  CupertinoIcons.ellipsis,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
                onPressed: () => _showPostOptions(post, isDark, theme),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post['content'] as String,
            style: TextStyle(
              fontSize: 14, // Changed from 16 to match "Share your food thoughts" size
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          if (post['imageUrl'] != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullImage(post['imageUrl'] as String, isDark),
              child: _buildNetworkImage(
                post['imageUrl'] as String,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPostOptions(
      Map<String, dynamic> post, bool isDark, ThemeData theme) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editPost(post, isDark, theme);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.pencil,
                  color: isDark ? Colors.white70 : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pinnedPostId = _pinnedPostId == post['id'] ? null : post['id'];
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _pinnedPostId == post['id']
                      ? CupertinoIcons.pin_slash
                      : CupertinoIcons.pin,
                  color: isDark ? Colors.white70 : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _pinnedPostId == post['id'] ? 'Unpin Post' : 'Pin Post',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deletePost(post, isDark, theme);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.delete),
                const SizedBox(width: 8),
                const Text('Delete'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? Colors.white70 : null,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _handlePost(bool isDark, ThemeData theme) async {
    if (_postController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final post = {
          'id':
              DateTime.now().millisecondsSinceEpoch.toString(), // Add unique ID
          'userId': user.uid,
          'content': _postController.text,
          'timestamp': DateTime.now(),
        };

        setState(() {
          _userPosts.insert(0, post);
        });

        _postController.clear();
        Navigator.pop(context);

        try {
          final docRef =
              await FirebaseFirestore.instance.collection('posts').add(post);

          // Update the post with the Firestore document ID
          setState(() {
            _userPosts[0]['id'] = docRef.id;
          });
        } catch (e) {
          if (mounted) {
            _showErrorDialog(
              'Your post has been saved locally. It will be uploaded when you\'re back online.',
              isDark,
              theme,
            );
          }
        }
      }
    }
  }

  // Add the new methods here
  void _handleCategorySelection(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _toggleFilters() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  Widget _buildStampProgress(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ]
              : [
                  const Color(0xFFE3F2FD),
                  const Color(0xFFBBDEFB),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : CupertinoColors.systemGrey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (index) => Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: index < (_zoneStamps[_selectedZone] ?? 0)
                        ? [
                            const Color(0xFFFFD700),
                            const Color(0xFFFFE57F),
                          ]
                        : isDark
                            ? [
                                Colors.grey[800]!.withOpacity(0.1),
                                Colors.grey[900]!.withOpacity(0.2),
                              ]
                            : [
                                CupertinoColors.systemGrey.withOpacity(0.1),
                                CupertinoColors.systemGrey.withOpacity(0.2),
                              ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: index < (_zoneStamps[_selectedZone] ?? 0)
                          ? const Color(0xFFFFD700).withOpacity(0.2)
                          : isDark
                              ? Colors.black26
                              : CupertinoColors.systemGrey.withOpacity(0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.star_fill,
                  color: index < (_zoneStamps[_selectedZone] ?? 0)
                      ? CupertinoColors.white
                      : isDark
                          ? Colors.grey[700]
                          : CupertinoColors.systemGrey.withOpacity(0.3),
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[850]!.withOpacity(0.1),
                        Colors.grey[900]!.withOpacity(0.2),
                      ]
                    : [
                        const Color(0xFF2196F3).withOpacity(0.1),
                        const Color(0xFF64B5F6).withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_zoneStamps[_selectedZone]}/5 Stamps Collected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsList(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!,
                  Colors.grey[900]!,
                ]
              : [
                  CupertinoColors.white,
                  const Color(0xFFF5F9FF),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : CupertinoColors.systemGrey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[850]!.withOpacity(0.1),
                        Colors.grey[900]!.withOpacity(0.2),
                      ]
                    : [
                        const Color(0xFF2196F3).withOpacity(0.1),
                        const Color(0xFF64B5F6).withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Available Rewards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF1976D2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRewardItem(
            '10% Off Next Visit',
            '5 stamps',
            const Color(0xFF4CAF50),
            CupertinoIcons.tag,
            isDark,
            theme,
          ),
          _buildRewardItem(
            'Free Dessert',
            '10 stamps',
            const Color(0xFFE91E63),
            CupertinoIcons.gift,
            isDark,
            theme,
          ),
          _buildRewardItem(
            'Free Main Course',
            '20 stamps',
            const Color(0xFFFFD700),
            CupertinoIcons.star,
            isDark,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : CupertinoColors.systemGrey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Posts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF1976D2),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showPostDialog(isDark, theme),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black26
                        : CupertinoColors.systemGrey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _userPosts.isEmpty
                          ? 'SHARE YOUR FOOD WITH THE WORLD.\nUPLOAD YOUR FIRST POST.'
                          : 'Share your food thoughts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black26
                              : CupertinoColors.systemGrey.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: () => _handleImageSelection(isDark, theme),
                      child: Icon(
                        CupertinoIcons.camera_fill,
                        color: isDark ? Colors.black : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, ThemeData theme) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.grey[850]!,
                      Colors.grey[900]!,
                    ]
                  : [
                      const Color(0xFFE3F2FD),
                      const Color(0xFFBBDEFB),
                    ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : CupertinoColors.systemGrey.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(
            CupertinoIcons.person_alt_circle,
            size: 120,
            color: isDark ? Colors.white70 : const Color(0xFF1976D2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : CupertinoColors.systemGrey.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _handleImageSelection(isDark, theme),
            child: Icon(
              CupertinoIcons.camera_fill,
              color: isDark ? Colors.black : Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'Edit Profile',
            CupertinoIcons.pencil,
            isDark: isDark,
            theme: theme,
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _buildActionButton(
            'Share Profile',
            CupertinoIcons.share,
            isDark: isDark,
            theme: theme,
            onPressed: () {
              // Implement share functionality
            },
          ),
          _buildActionButton(
            'Add Friend',
            CupertinoIcons.person_add,
            isDark: isDark,
            theme: theme,
            onPressed: () {
              // Implement add friend functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(
    String title,
    String requirement,
    Color color,
    IconData icon,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[850]!.withOpacity(0.1),
                  Colors.grey[900]!.withOpacity(0.2),
                ]
              : [
                  color.withOpacity(0.1),
                  color.withOpacity(0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : color.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[800]!,
                        Colors.grey[900]!,
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : color.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  requirement,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey[850]!.withOpacity(0.1),
                        Colors.grey[900]!.withOpacity(0.2),
                      ]
                    : [
                        color.withOpacity(0.1),
                        color.withOpacity(0.2),
                      ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.chevron_right,
              color: isDark ? Colors.white70 : color,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDialog(bool isDark, ThemeData theme) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : CupertinoColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : null,
                    ),
                  ),
                  onPressed: () {
                    _postController.clear();
                    Navigator.pop(context);
                  },
                ),
                CupertinoButton(
                  child: Text(
                    'Post',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  onPressed: () => _handlePost(isDark, theme),
                ),
              ],
            ),
            Expanded(
              child: CupertinoTextField(
                controller: _postController,
                placeholder: 'What\'s on your mind?',
                placeholderStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : CupertinoColors.systemGrey,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: null,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? Colors.grey[800]!
                        : CupertinoColors.systemGrey4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? const Color(0xFF1E1E1E) : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => _handleImageSelection(isDark, theme),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.camera_fill,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
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

  Widget buildStatColumn(
      String count, String label, bool isDark, ThemeData theme) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? theme.colorScheme.primary : const Color(0xFF1976D2),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? Colors.grey[400]
                : CupertinoColors.systemGrey.darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon, {
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.grey[850]!,
                    Colors.grey[900]!,
                  ]
                : [
                    const Color(0xFFE3F2FD),
                    const Color(0xFFBBDEFB),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black26
                  : CupertinoColors.systemGrey.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.white70 : const Color(0xFF1976D2),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
