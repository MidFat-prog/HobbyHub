import 'package:flutter/material.dart';
import 'package:final_project/widgets/background_container.dart';
import 'package:final_project/widgets/custom_button.dart';
import 'package:final_project/services/auth_service.dart';
import 'package:final_project/screens/home_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InterestSelectionScreen extends StatefulWidget {
  final bool isEditing;

  const InterestSelectionScreen({super.key, this.isEditing = false});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final Set<String> _selectedInterests = {};
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final List<Map<String, dynamic>> hobbies = [
    {'name': 'Knitting', 'color': Color(0xFFFFF4C2)},
    {'name': 'Video Games', 'color': Color(0xFFBAB3FF)},
    {'name': 'Cooking', 'color': Color(0xFFFFD9B3)},
    {'name': 'Baking', 'color': Color(0xFFFFE6B3)},
    {'name': 'Reading', 'color': Color(0xFFB3FFB3)},
    {'name': 'Badminton', 'color': Color(0xFFFFB3BA)},
    {'name': 'Photography', 'color': Color(0xFFE6B3FF)},
    {'name': 'Painting', 'color': Color(0xFFB3E5FC)},
    {'name': 'Gardening', 'color': Color(0xFFB3FFE6)},
    {'name': 'Music', 'color': Color(0xFFD4B3FF)},
    {'name': 'Crochet', 'color': Color(0xFFB3D4FF)},
    {'name': 'Fitness', 'color': Color(0xFFFFB3D4)},
    {'name': 'Drawing', 'color': Color(0xFFB3FFD9)},
    {'name': 'Writing', 'color': Color(0xFFFFB3E6)},
    {'name': 'Yoga', 'color': Color(0xFFB3FFFF)},
    {'name': 'Programming', 'color': Color(0xFFD9B3FF)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadCurrentInterests();
    }
  }

  Future<void> _loadCurrentInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted && userDoc.exists) {
        setState(() {
          final interests = List<String>.from(userDoc.data()?['interests'] ?? []);
          _selectedInterests.addAll(interests);
        });
      }
    }
  }

  Future<void> _handleContinue() async {
    if (_selectedInterests.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select at least one interest');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success = await _authService.updateUserInterests(
      _selectedInterests.toList(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;

      if (widget.isEditing) {
        // If editing, just go back
        Fluttertoast.showToast(msg: 'Interests updated!');
        Navigator.pop(context, true);
      } else {
        // If new user, go to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(isNewUser: false),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundContainer(),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Back button if editing
                if (widget.isEditing)
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    widget.isEditing ? 'Edit your interests' : 'Choose your interests',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  widget.isEditing
                      ? 'Update hobbies you love'
                      : 'Select hobbies you love',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.6),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30),

                // Interest Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: hobbies.length,
                      itemBuilder: (context, index) {
                        final hobby = hobbies[index];
                        final isSelected = _selectedInterests.contains(hobby['name']);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedInterests.remove(hobby['name']);
                              } else {
                                _selectedInterests.add(hobby['name']);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: hobby['color'],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                hobby['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Continue Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: CustomButton(
                    text: 'Continue',
                    onPressed: _handleContinue,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}