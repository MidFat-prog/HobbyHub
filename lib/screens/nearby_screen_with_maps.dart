import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hobby_resources.dart';
import 'location_selector_screen.dart';
import 'public_profile_screen.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class NearbyScreenWithMaps extends StatefulWidget {
  const NearbyScreenWithMaps({super.key});

  @override
  State<NearbyScreenWithMaps> createState() => _NearbyScreenWithMapsState();
}

class _NearbyScreenWithMapsState extends State<NearbyScreenWithMaps> with SingleTickerProviderStateMixin {
  bool _isMapView = true; // true = Google Maps, false = Radial
  bool _isListView = false;
  String? _filterHobby;
  String? currentUserCity;
  String? currentUserArea;
  List<String> userInterests = [];
  late AnimationController _pulseController;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  bool _markersCreated = false; // Add this flag to prevent recreating markers

  // City center coordinates
  final Map<String, LatLng> _cityCenters = {
    'Lahore': LatLng(31.5204, 74.3587),
    'Karachi': LatLng(24.8607, 67.0011),
    'Islamabad': LatLng(33.6844, 73.0479),
    'Rawalpindi': LatLng(33.5651, 73.0169),
    'Faisalabad': LatLng(31.4504, 73.1350),
    'Multan': LatLng(30.1575, 71.5249),
    'Peshawar': LatLng(34.0151, 71.5249),
    'Quetta': LatLng(30.1798, 66.9750),
    'Sialkot': LatLng(32.4945, 74.5229),
    'Gujranwala': LatLng(32.1617, 74.1883),
    'Bahawalpur': LatLng(29.3956, 71.6722),
  };

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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted && userDoc.exists)
      {
        setState(() {
          currentUserCity = userDoc.data()?['city'];
          currentUserArea = userDoc.data()?['area'];
          userInterests = List<String>.from(userDoc.data()?['interests'] ?? []);
        });

        if (currentUserCity != null && _isMapView)
        {
          _getUserLocation();
        }
      }
    }
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Use city center if no permission
        _useAreaCenter();
        return;
      }
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 13),
      );
    } catch (e) {// Fallback to area center
      _useAreaCenter();
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _useAreaCenter() {
    // Use city center as fallback
    if (currentUserCity != null && _cityCenters.containsKey(currentUserCity)) {
      setState(() {
        _userLocation = _cityCenters[currentUserCity!];
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 12),
      );
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(
      String hobby,
      String initial,
      Color color,
      ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Draw circle
    canvas.drawCircle(Offset(25, 25), 20, paint);

    // Draw white circle for initial
    paint.color = Colors.white;
    canvas.drawCircle(Offset(25, 25), 15, paint);

    // Draw initial
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(25 - textPainter.width / 2, 25 - textPainter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(50, 50);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _createMarkers(List<Map<String, dynamic>> users) async {
    // Only create markers once or when users change
    if (_markersCreated && _markers.isNotEmpty) return;

    final markers = <Marker>{};
    final cityCenter = _cityCenters[currentUserCity] ?? LatLng(31.5204, 74.3587);

    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      final interests = user['interests'] as List<String>;
      if (interests.isEmpty) continue;

      final hobby = allHobbies.firstWhere(
            (h) => h.name == interests[0],
        orElse: () => allHobbies[0],
      );

      // Use area name to generate consistent position (won't jump around)
      final areaHash = user['area'].hashCode;
      final random = math.Random(areaHash); // Seed with area hash for consistency

      // Generate position based on distance from user's area
      final distance = _calculateDistance(currentUserArea!, user['area'] as String?);
      final angle = (random.nextDouble() * 2 * math.pi); // Random angle but consistent
      final radiusKm = distance / 111; // Convert km to degrees (roughly)

      final lat = cityCenter.latitude + (radiusKm * math.cos(angle));
      final lng = cityCenter.longitude + (radiusKm * math.sin(angle));

      final markerIcon = await _createCustomMarker(
        interests[0],
        user['username'][0].toUpperCase(),
        Color(int.parse(hobby.color)),
      );

      markers.add(
        Marker(
          markerId: MarkerId(user['id']),
          position: LatLng(lat, lng),
          icon: markerIcon,
          onTap: () => _showUserProfile(user),
          infoWindow: InfoWindow(
            title: user['username'],
            snippet: '${distance.toStringAsFixed(1)} km away',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _markersCreated = true;
    });
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
              child: _isListView
                  ? _buildListView()
                  : (_isMapView ? _buildGoogleMapView() : _buildRadialMapView()),
            ),
          ],
        ),
      ),
      floatingActionButton: _isMapView && _userLocation != null
          ? FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white,
        onPressed: () {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_userLocation!, 13),
          );
        },
        child: Icon(Icons.my_location, color: Color(0xFF9b7fd4)),
      )
          : null,
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
                  icon: Icons.map,
                  label: 'Map',
                  isSelected: _isMapView && !_isListView,
                  onTap: () => setState(() {
                    _isMapView = true;
                    _isListView = false;
                    if (_userLocation == null) _getUserLocation();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildViewToggle(
                  icon: Icons.radar,
                  label: 'Radial',
                  isSelected: !_isMapView && !_isListView,
                  onTap: () => setState(() {
                    _isMapView = false;
                    _isListView = false;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildViewToggle(
                  icon: Icons.list,
                  label: 'List',
                  isSelected: _isListView,
                  onTap: () => setState(() => _isListView = true),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
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
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFF9b7fd4) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
      onTap: () {
        setState(() {
          _filterHobby = hobby;
          _markersCreated = false; // Reset markers when filter changes
          _markers.clear();
        });
      },
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
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
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

  Widget _buildGoogleMapView() {
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

        _createMarkers(users);

        final initialPosition = _userLocation ??
            _cityCenters[currentUserCity] ??
            LatLng(31.5204, 74.3587);

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 13.5, // Better zoom level - not too far, not too close
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                // Animate to better view after map loads
                Future.delayed(Duration(milliseconds: 500), () {
                  if (_markers.isNotEmpty && mounted) {
                    // Calculate bounds to show all markers
                    double minLat = double.infinity;
                    double maxLat = -double.infinity;
                    double minLng = double.infinity;
                    double maxLng = -double.infinity;

                    for (var marker in _markers) {
                      minLat = math.min(minLat, marker.position.latitude);
                      maxLat = math.max(maxLat, marker.position.latitude);
                      minLng = math.min(minLng, marker.position.longitude);
                      maxLng = math.max(maxLng, marker.position.longitude);
                    }

                    // Add user location to bounds
                    if (_userLocation != null) {
                      minLat = math.min(minLat, _userLocation!.latitude);
                      maxLat = math.max(maxLat, _userLocation!.latitude);
                      minLng = math.min(minLng, _userLocation!.longitude);
                      maxLng = math.max(maxLng, _userLocation!.longitude);
                    }

                    final bounds = LatLngBounds(
                      southwest: LatLng(minLat, minLng),
                      northeast: LatLng(maxLat, maxLng),
                    );

                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds, 100), // 100 padding
                    );
                  }
                });
              },
            ),
            if (_isLoadingLocation)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
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

  Widget _buildRadialMapView() {
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

        return Stack(
          children: [
            Positioned.fill(
              bottom: 80,
              child: RadialMapView(
                users: users,
                currentUserArea: currentUserArea!,
                pulseAnimation: _pulseController,
                onUserTap: _showUserProfile,
              ),
            ),
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
                    _loadUserData();
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
    if (area1 == area2) return 0.5 + math.Random().nextDouble() * 1.5;

    bool sameZone(String a1, String a2) {
      if (a1.contains('DHA') && a2.contains('DHA')) return true;
      if (a1.contains('Bahria') && a2.contains('Bahria')) return true;
      if (a1.startsWith('F-') && a2.startsWith('F-')) return true;
      if (a1.startsWith('G-') && a2.startsWith('G-')) return true;
      if (a1.startsWith('I-') && a2.startsWith('I-')) return true;
      if ((a1.contains('Gulberg') || a1.contains('Model') || a1.contains('Garden')) &&
          (a2.contains('Gulberg') || a2.contains('Model') || a2.contains('Garden'))) return true;
      if (a1.contains('Clifton') && a2.contains('Clifton')) return true;
      if ((a1.contains('Gulshan') || a1.contains('Gulistan')) &&
          (a2.contains('Gulshan') || a2.contains('Gulistan'))) return true;
      if ((a1.contains('North') || a1.contains('Nazimabad')) &&
          (a2.contains('North') || a2.contains('Nazimabad'))) return true;
      if (a1.contains('Satellite') && a2.contains('Satellite')) return true;
      if (a1.contains('Hayatabad') && a2.contains('Hayatabad')) return true;
      return false;
    }

    if (sameZone(area1, area2)) {
      return 2.0 + math.Random().nextDouble() * 3.0;
    }

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

// Keep existing RadialMapView, UserBubble, and UserProfileCard classes
// (Copy from previous nearby_screen.dart)

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
    if (area1 == area2) return 0.5 + math.Random().nextDouble() * 1.5;

    bool sameZone(String a1, String a2) {
      if (a1.contains('DHA') && a2.contains('DHA')) return true;
      if (a1.contains('Bahria') && a2.contains('Bahria')) return true;
      if (a1.startsWith('F-') && a2.startsWith('F-')) return true;
      if (a1.startsWith('G-') && a2.startsWith('G-')) return true;
      if (a1.contains('Gulberg') && a2.contains('Gulberg')) return true;
      if (a1.contains('Clifton') && a2.contains('Clifton')) return true;
      return false;
    }

    if (sameZone(area1, area2)) {
      return 2.0 + math.Random().nextDouble() * 3.0;
    }

    return 5.0 + math.Random().nextDouble() * 7.0;
  }
}

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

class UserProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final double distance;

  const UserProfileCard({
    super.key,
    required this.user,
    required this.distance,
  });

  void _sendMessageNotification(BuildContext context) {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.message, color: Color(0xFF9b7fd4)),
            const SizedBox(width: 10),
            const Text('Send Message'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF9b7fd4),
              backgroundImage: user['profileImageUrl'] != null
                  ? NetworkImage(user['profileImageUrl'])
                  : null,
              child: user['profileImageUrl'] == null
                  ? Text(
                user['username'][0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(height: 15),
            Text(
              'Message ${user['username']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Messaging feature coming soon! You\'ll be able to chat with hobby friends.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xFF9b7fd4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active,
                    color: Color(0xFF9b7fd4),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We\'ll notify you when messaging is available!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9b7fd4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PublicProfileScreen(
                          userId: user['id'],
                          username: user['username'],
                        ),
                      ),
                    );
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
                  onPressed: () => _sendMessageNotification(context),
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