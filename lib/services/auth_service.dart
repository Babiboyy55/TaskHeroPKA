import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google (Web-optimized)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('[Auth] Starting Google Sign-In with popup...');
      print('[Auth] Current domain: ${Uri.base.host}');
      
      // Create Google provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Optional: Add custom parameters
      googleProvider.setCustomParameters({
        'prompt': 'select_account',  // Always show account selection
      });

      print('[Auth] Calling signInWithPopup...');
      
      // Sign in with popup
      final UserCredential userCredential = 
          await _auth.signInWithPopup(googleProvider);

      print('[Auth] Successfully signed in: ${userCredential.user?.email}');
      print('[Auth] User ID: ${userCredential.user?.uid}');
      
      // Create or update user profile in Firestore
      if (userCredential.user != null) {
        try {
          await _firestoreService.createOrUpdateUserProfile(userCredential.user!);
        } catch (e) {
          print('[Auth] Warning: Failed to create/update profile, but sign-in succeeded. Error: $e');
          // We continue anyway so the user can use the app
        }
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[Auth] FirebaseAuthException: ${e.code} - ${e.message}');
      
      if (e.code == 'popup-closed-by-user') {
        print('[Auth] User closed the popup');
      } else if (e.code == 'popup-blocked') {
        print('[Auth] Popup was blocked by browser');
      }
      
      return null;
    } catch (e, stackTrace) {
      print('[Auth] ERROR: $e');
      print('[Auth] Stack trace: $stackTrace');
      return null;
    }
  }

  // ─── EMAIL/PASSWORD AUTHENTICATION ────────────────────────────────

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('[Auth] Starting email/password registration...');
      print('[Auth] Email: $email');
      
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('[Auth] User created successfully: ${userCredential.user?.uid}');
      
      // Update display name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
        print('[Auth] Display name updated to: $displayName');
        
        // Create user profile in Firestore
        try {
          await _firestoreService.createOrUpdateUserProfile(
            _auth.currentUser!,
          );
          print('[Auth] Firestore profile created');
        } catch (e) {
          print('[Auth] Warning: Failed to create Firestore profile: $e');
        }
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[Auth] Registration error: ${e.code} - ${e.message}');
      rethrow; // Let the UI handle the error
    } catch (e, stackTrace) {
      print('[Auth] Unexpected registration error: $e');
      print('[Auth] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('[Auth] Starting email/password sign-in...');
      print('[Auth] Email: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('[Auth] Successfully signed in: ${userCredential.user?.email}');
      print('[Auth] User ID: ${userCredential.user?.uid}');
      
      // Update user profile in Firestore (in case of any changes)
      if (userCredential.user != null) {
        try {
          await _firestoreService.createOrUpdateUserProfile(userCredential.user!);
        } catch (e) {
          print('[Auth] Warning: Failed to update profile: $e');
        }
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[Auth] Sign-in error: ${e.code} - ${e.message}');
      rethrow; // Let the UI handle the error
    } catch (e, stackTrace) {
      print('[Auth] Unexpected sign-in error: $e');
      print('[Auth] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      print('[Auth] Sending password reset email to: $email');
      
      await _auth.sendPasswordResetEmail(email: email);
      
      print('[Auth] Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      print('[Auth] Password reset error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('[Auth] Unexpected password reset error: $e');
      print('[Auth] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        print('[Auth] Display name updated to: $displayName');
      }
    } catch (e) {
      print('[Auth] Error updating display name: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('[Auth] User signed out');
    } catch (e) {
      print('[Auth] Sign out error: $e');
    }
  }
}

