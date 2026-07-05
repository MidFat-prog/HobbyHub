import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hobby_resources.dart';
import 'location_selector_screen.dart';
import 'dart:math' as math;

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with SingleTickerProviderStateMixin {
  bool _isMapView = true;
  String? _filterHobby;
  String? currentUserCity;
  String? currentUserArea;
  List<String> userInterests = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted && userDoc.exists) {
        setState(() {
          currentUserCity = userDoc.data()?['city'];
          currentUserArea = userDoc.data()?['area'];
          userInterests = List<String>.from(userDoc.data()?['interests'] ?? []);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserCity == null || currentUserArea == null) {
      return _buildSetupLocationScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            Expanded(
              child: _isMapView ? _buildMapView() : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFc5aae6), Color(0xFFabc2e6)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📍 Nearby Friends',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$currentUserArea, $currentUserCity',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationSelectorScreen(isFromProfile: true),
                    ),
                  );
                  if (result == true) {
                    _loadUserData();
                  }
                },
                icon: const Icon(Icons.edit_location, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildViewToggle(
                  icon: Icons.radar,
                  label: 'Map View',
                  isSelected: _isMapView,
                  onTap: () => setState(() => _isMapView = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildViewToggle(
                  icon: Icons.list,
                  label: 'List View',
                  isSelected: !_isMapView,
                  onTap: () => setState(() => _isMapView = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF9b7fd4) : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFF9b7fd4) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          ...userInterests.map((hobby) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(hobby, hobby),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? hobby) {
    final isSelected = _filterHobby == hobby;
    final hobbyData = hobby != null
        ? allHobbies.firstWhere((h) => h.name == hobby, orElse: () => allHobbies[0])
        : null;

    return GestureDetector(
      onTap: () => setState(() => _filterHobby = hobby),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (hobbyData != null
              ? Color(int.parse(hobbyData.color))
              : Color(0xFF9b7fd4))
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            if (hobbyData != null) ...[
              Text(hobbyData.emoji, style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('city', isEqualTo: currentUserCity)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        var users = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'username': data['username'] ?? 'User',
            'area': data['area'],
            'interests': List<String>.from(data['interests'] ?? []),
            'profileImageUrl': data['profileImageUrl'],
          };
        }).toList();

        // Filter by hobby if selected
        if (_filterHobby != null) {
          users = users.where((user) {
            final interests = user['interests'] as List<String>;
            return interests.contains(_filterHobby);
          }).toList();
        }

        // Filter by common interests
        users = users.where((user) {
          final interests = user['interests'] as List<String>;
          return interests.any((interest) => userInterests.contains(interest));
        }).toList();

        if (users.isEmpty) {
          return _buildEmptyState();
        }

        return Stack(
          children: [
            // Map takes most of the space
            Positioned.fill(
              bottom: 80, // Leave space for bottom bar
              child: RadialMapView(
                users: users,
                currentUserArea: currentUserArea!,
                pulseAnimation: _pulseController,
                onUserTap: _showUserProfile,
              ),
            ),
            // User count at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildUserCount(users.length),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('city', isEqualTo: currentUserCity)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        var users = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'username': data['username'] ?? 'User',
            'area': data['area'],
            'interests': List<String>.from(data['interests'] ?? []),
            'profileImageUrl': data['profileImageUrl'],
          };
        }).toList();

        // Apply filters
        if (_filterHobby != null) {
          users = users.where((user) {
            final interests = user['interests'] as List<String>;
            return interests.contains(_filterHobby);
          }).toList();
        }

        users = users.where((user) {
          final interests = user['interests'] as List<String>;
          return interests.any((interest) => userInterests.contains(interest));
        }).toList();

        if (users.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final distance = _calculateDistance(
              currentUserArea!,
              user['area'] as String?,
            );

            return _buildUserListCard(user, distance);
          },
        );
      },
    );
  }

  Widget _buildUserListCard(Map<String, dynamic> user, double distance) {
    final interests = user['interests'] as List<String>;
    final commonInterests = interests
        .where((interest) => userInterests.contains(interest))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFF9b7fd4),
          backgroundImage: user['profileImageUrl'] != null
              ? NetworkImage(user['profileImageUrl'])
              : null,
          child: user['profileImageUrl'] == null
              ? Text(
            user['username'][0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
        title: Text(
          user['username'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${distance.toStringAsFixed(1)} km away',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: commonInterests.take(3).map((interest) {
                final hobby = allHobbies.firstWhere(
                      (h) => h.name == interest,
                  orElse: () => allHobbies[0],
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(hobby.color)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(hobby.emoji, style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        interest,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () => _showUserProfile(user),
      ),
    );
  }

  Widget _buildUserCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, color: Color(0xFF9b7fd4), size: 20),
          const SizedBox(width: 8),
          Text(
            '$count hobby ${count == 1 ? 'friend' : 'friends'} nearby',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9b7fd4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No hobby friends nearby',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Try changing your location or explore different hobbies',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupLocationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 30),
              const Text(
                'Set Your Location',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'To find hobby friends near you, please set your location in your profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationSelectorScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadUserData(); // Reload after setting location
                  }
                },
                icon: const Icon(Icons.edit_location),
                label: const Text('Set Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9b7fd4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(String area1, String? area2) {
    if (area2 == null) return 0.0;

    // Same area = very close (0.5-2 km)
    if (area1 == area2) return 0.5 + math.Random().nextDouble() * 1.5;

    // Helper function to determine if areas are in same zone
    bool sameZone(String a1, String a2) {
      // DHA phases close to each other
      if (a1.contains('DHA') && a2.contains('DHA')) return true;
      // Bahria phases close to each other
      if (a1.contains('Bahria') && a2.contains('Bahria')) return true;
      // Islamabad F sectors
      if (a1.startsWith('F-') && a2.startsWith('F-')) return true;
      // Islamabad G sectors
      if (a1.startsWith('G-') && a2.startsWith('G-')) return true;
      // Islamabad I sectors
      if (a1.startsWith('I-') && a2.startsWith('I-')) return true;
      // Gulberg areas in Lahore
      if ((a1.contains('Gulberg') || a1.contains('Model') || a1.contains('Garden')) &&
          (a2.contains('Gulberg') || a2.contains('Model') || a2.contains('Garden'))) return true;
      // Karachi DHA
      if (a1.contains('DHA') && a2.contains('DHA')) return true;
      // Clifton areas
      if (a1.contains('Clifton') && a2.contains('Clifton')) return true;
      // Gulshan areas
      if ((a1.contains('Gulshan') || a1.contains('Gulistan')) &&
          (a2.contains('Gulshan') || a2.contains('Gulistan'))) return true;
      // North areas
      if ((a1.contains('North') || a1.contains('Nazimabad')) &&
          (a2.contains('North') || a2.contains('Nazimabad'))) return true;
      // Satellite Town
      if (a1.contains('Satellite') && a2.contains('Satellite')) return true;
      // Hayatabad phases
      if (a1.contains('Hayatabad') && a2.contains('Hayatabad')) return true;

      return false;
    }

    // Areas in same zone = close (2-5 km)
    if (sameZone(area1, area2)) {
      return 2.0 + math.Random().nextDouble() * 3.0;
    }

    // Areas in same city but different zones = medium (5-12 km)
    return 5.0 + math.Random().nextDouble() * 7.0;
  }

  void _showUserProfile(Map<String, dynamic> user) {
    final distance = _calculateDistance(
      currentUserArea!,
      user['area'] as String?,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserProfileCard(
        user: user,
        distance: distance,
      ),
    );
  }
}

// Custom Radial Map View Widget
class RadialMapView extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String currentUserArea;
  final AnimationController pulseAnimation;
  final Function(Map<String, dynamic>) onUserTap;

  const RadialMapView({
    super.key,
    required this.users,
    required this.currentUserArea,
    required this.pulseAnimation,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;
        final maxRadius = math.min(centerX, centerY) - 60;

        return Stack(
          children: [
            // Distance rings
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDistanceRing(maxRadius * 0.3, '1 km'),
                  const SizedBox(height: 20),
                  _buildDistanceRing(maxRadius * 0.6, '5 km'),
                  const SizedBox(height: 20),
                  _buildDistanceRing(maxRadius * 0.9, '10 km'),
                ],
              ),
            ),

            // User bubbles
            ...users.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final distance = _calculateDistance(currentUserArea, user['area'] as String?);
              final angle = (index / users.length) * 2 * math.pi;
              final radius = (distance / 10) * maxRadius;
              final x = centerX + radius * math.cos(angle) - 40;
              final y = centerY + radius * math.sin(angle) - 40;

              return Positioned(
                left: x.clamp(10, constraints.maxWidth - 90),
                top: y.clamp(10, constraints.maxHeight - 90),
                child: UserBubble(
                  user: user,
                  distance: distance,
                  onTap: () => onUserTap(user),
                ),
              );
            }),

            // Center "You" marker
            Center(
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF9b7fd4),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF9b7fd4).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: pulseAnimation.value * 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, color: Colors.white, size: 30),
                          Text(
                            'You',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDistanceRing(double radius, String label) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  double _calculateDistance(String area1, String? area2) {
    if (area2 == null) return 0.0;

    final distances = {
      'Gulberg-DHA': 8.5,
      'Gulberg-Johar Town': 6.2,
      'Gulberg-Model Town': 4.1,
      'Gulberg-Bahria Town': 12.3,
      'Gulberg-Cantt': 5.8,
      'DHA-Johar Town': 10.5,
      'DHA-Model Town': 7.2,
      'DHA-Bahria Town': 15.1,
      'DHA-Cantt': 3.5,
      'Johar Town-Model Town': 5.5,
      'Johar Town-Bahria Town': 8.8,
      'Johar Town-Cantt': 9.2,
      'Model Town-Bahria Town': 11.5,
      'Model Town-Cantt': 6.8,
      'Bahria Town-Cantt': 14.2,
    };

    if (area1 == area2) return 0.5 + math.Random().nextDouble() * 1.5;

    final key1 = '$area1-$area2';
    final key2 = '$area2-$area1';

    return distances[key1] ?? distances[key2] ?? (5.0 + math.Random().nextDouble() * 5.0);
  }
}

// User Bubble Widget
class UserBubble extends StatefulWidget {
  final Map<String, dynamic> user;
  final double distance;
  final VoidCallback onTap;

  const UserBubble({
    super.key,
    required this.user,
    required this.distance,
    required this.onTap,
  });

  @override
  State<UserBubble> createState() => _UserBubbleState();
}

class _UserBubbleState extends State<UserBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interests = widget.user['interests'] as List<String>;
    final primaryHobby = interests.isNotEmpty ? interests[0] : 'Hobby';
    final hobby = allHobbies.firstWhere(
          (h) => h.name == primaryHobby,
      orElse: () => allHobbies[0],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(int.parse(hobby.color)),
                boxShadow: [
                  BoxShadow(
                    color: Color(int.parse(hobby.color)).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: widget.user['profileImageUrl'] != null
                    ? ClipOval(
                  child: Image.network(
                    widget.user['profileImageUrl'],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
                    : Text(
                  widget.user['username'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '${widget.distance.toStringAsFixed(1)}km',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9b7fd4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// User Profile Card (Bottom Sheet)
class UserProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final double distance;

  const UserProfileCard({
    super.key,
    required this.user,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final interests = user['interests'] as List<String>;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF9b7fd4),
            backgroundImage: user['profileImageUrl'] != null
                ? NetworkImage(user['profileImageUrl'])
                : null,
            child: user['profileImageUrl'] == null
                ? Text(
              user['username'][0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(height: 15),
          Text(
            user['username'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${distance.toStringAsFixed(1)} km away',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Common Interests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: interests.map((interest) {
              final hobby = allHobbies.firstWhere(
                    (h) => h.name == interest,
                orElse: () => allHobbies[0],
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(int.parse(hobby.color)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hobby.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      interest,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: View full profile
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('View Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9b7fd4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Message user
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9b7fd4),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    side: const BorderSide(color: Color(0xFF9b7fd4)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}