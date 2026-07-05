import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String hobbyName;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likes;
  final int comments;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.hobbyName,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      hobbyName: data['hobbyName'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'hobbyName': hobbyName,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'comments': comments,
    };
  }
}