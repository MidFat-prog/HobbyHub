import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/hobby_resources.dart';
import 'create_post_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'interest_selection_screen.dart';
import 'comments_screen.dart';
import 'nearby_screen_with_maps.dart';

class HomeScreen extends StatefulWidget {
  final bool isNewUser;

  const HomeScreen({super.key, this.isNewUser = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String username = '';
  List<String> userInterests = [];
  bool _isLoading = true;
  final Map<String, bool> _likedPosts = {}; // Don't use setState when updating this

  @override
  void initState() {
    super.initState();
    _loadUserData();

    if (widget.isNewUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InterestSelectionScreen(),
          ),
        ).then((_) => _loadUserData());
      });
    }
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
          username = userDoc.data()?['username'] ?? 'User';
          userInterests = List<String>.from(userDoc.data()?['interests'] ?? []);
          _isLoading = false;
        });

        _loadLikedPosts();
      }
    }
  }

  Future<void> _loadLikedPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final likedSnapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Don't use setState here - just update the map
      for (var doc in likedSnapshot.docs) {
        _likedPosts[doc.data()['postId'] as String] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeFeed(),
      const ExploreScreen(),
      const NearbyScreenWithMaps(),
      const ProfileScreen(userData: null),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF9b7fd4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeFeed() {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFc5aae6), Color(0xFFabc2e6)],
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFc5aae6), Color(0xFFabc2e6)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: userInterests.isEmpty
                  ? _buildEmptyInterests()
                  : _buildPostsFeed(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            username,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Following', '${userInterests.length}', Icons.favorite),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.black.withOpacity(0.2),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final postCount = snapshot.data?.docs.length ?? 0;
                    return _buildStatItem('Posts', '$postCount', Icons.article);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '📰 Your Feed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.black.withOpacity(0.6)),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  Widget _buildPostsFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('hobbyName', whereIn: userInterests.isEmpty ? ['none'] : userInterests)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyFeed();
        }

        final posts = snapshot.data!.docs.map((doc) => Post.fromFirestore(doc)).toList();
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return RefreshIndicator(
          onRefresh: () async {
            await _loadUserData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _PostCard(
                key: ValueKey(posts[index].id),
                post: posts[index],
                isLiked: _likedPosts[posts[index].id] ?? false,
                onLikeChanged: (postId, isLiked) {
                  _likedPosts[postId] = isLiked; // Update map WITHOUT setState
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: Colors.black.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Be the first to share something!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInterests() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 80,
              color: Colors.black.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              'No interests selected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Select some hobbies to see posts in your feed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 1; // Explore is now index 1
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Explore Hobbies',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog() async {
    if (userInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select some interests first!'),
        ),
      );
      setState(() {
        _currentIndex = 1;
      });
      return;
    }

    final selectedHobby = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Hobby'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: userInterests.length,
            itemBuilder: (context, index) {
              final hobbyName = userInterests[index];

              final hobby = allHobbies.firstWhere(
                    (h) => h.name == hobbyName,
                orElse: () => HobbyCategory(
                  name: hobbyName,
                  emoji: '🎯',
                  description: '',
                  color: '0xFFB3E5FC',
                  learningVideos: [],
                  resources: [],
                  imageUrl: '',
                ),
              );

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(hobby.color)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      hobby.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                title: Text(hobby.name),
                onTap: () => Navigator.pop(context, hobby.name),
              );
            },
          ),
        ),
      ),
    );

    if (selectedHobby != null && mounted) {
      final hobby = allHobbies.firstWhere(
            (h) => h.name == selectedHobby,
        orElse: () => HobbyCategory(
          name: selectedHobby,
          emoji: '🎯',
          description: '',
          color: '0xFFB3E5FC',
          learningVideos: [],
          resources: [],
          imageUrl: '',
        ),
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePostScreen(
            hobbyName: hobby.name,
            hobbyColor: hobby.color,
          ),
        ),
      );

      if (result == true && mounted) {
        setState(() {});
      }
    }
  }
}

// Separate StatefulWidget for each post card - CRITICAL for no refresh!
class _PostCard extends StatefulWidget {
  final Post post;
  final bool isLiked;
  final Function(String postId, bool isLiked) onLikeChanged;

  const _PostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onLikeChanged,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.post.likes;
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likeId = '${user.uid}_${widget.post.id}';
    final shouldLike = !_isLiked;

    // Update UI IMMEDIATELY - no waiting!
    setState(() {
      _isLiked = shouldLike;
      _likeCount = shouldLike ? _likeCount + 1 : _likeCount - 1;
    });

    // Update parent state WITHOUT causing rebuild
    widget.onLikeChanged(widget.post.id, shouldLike);

    // Update Firebase in background
    try {
      if (shouldLike) {
        await FirebaseFirestore.instance.collection('likes').doc(likeId).set({
          'userId': user.uid,
          'postId': widget.post.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({
          'likes': FieldValue.increment(1),
        });
      } else {
        await FirebaseFirestore.instance.collection('likes').doc(likeId).delete();
        await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({
          'likes': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      // If Firebase fails, revert the UI
      if (mounted) {
        setState(() {
          _isLiked = !shouldLike;
          _likeCount = shouldLike ? _likeCount - 1 : _likeCount + 1;
        });
        widget.onLikeChanged(widget.post.id, !shouldLike);
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openComments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(post: widget.post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hobby = allHobbies.firstWhere(
          (h) => h.name == widget.post.hobbyName,
      orElse: () => allHobbies[0],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(int.parse(hobby.color)),
                  child: Text(
                    widget.post.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(int.parse(hobby.color)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hobby.emoji,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.post.hobbyName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getTimeAgo(widget.post.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
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
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
              child: Image.network(
                widget.post.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.post.content,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    InkWell(
                      onTap: _toggleLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },
                              child: Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(_isLiked),
                                size: 22,
                                color: _isLiked ? Colors.red : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$_likeCount',
                              style: TextStyle(
                                color: _isLiked ? Colors.red : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: _openComments,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.post.comments}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }
}