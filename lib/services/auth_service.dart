import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up with Email and Password
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      // Create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      
      if (user != null) {
        // Update display name
        await user.updateDisplayName(username);
        
        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
          'interests': [],
          'profileComplete': false,
        });

        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': 'Failed to create user'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }
      
      Fluttertoast.showToast(msg: message);
      return {'success': false, 'message': message};
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Sign In with Email and Password
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      
      if (user != null) {
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': 'Failed to sign in'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }
      
      Fluttertoast.showToast(msg: message);
      return {'success': false, 'message': message};
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    Fluttertoast.showToast(msg: 'Signed out successfully');
  }

  // Update user interests
  Future<bool> updateUserInterests(List<String> interests) async {
    try {
      User? user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'interests': interests,
          'profileComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating interests: ${e.toString()}');
      return false;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching user data: ${e.toString()}');
      return null;
    }
  }

  // Check if profile is complete
  Future<bool> isProfileComplete() async {
    try {
      User? user = currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        return data?['profileComplete'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
