import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ===== USER PROFILE METHODS =====

  /// Create or update user profile when they first sign in
  Future<void> createOrUpdateUserProfile(User firebaseUser) async {
    print('[Firestore] createOrUpdateUserProfile called for uid: ${firebaseUser.uid}');
    
    try {
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      
      print('[Firestore] Checking if user document exists...');
      final docSnapshot = await userDoc.get();
      print('[Firestore] Document exists: ${docSnapshot.exists}');

      if (!docSnapshot.exists) {
        // New user - create profile
        print('[Firestore] Creating new user profile...');
        final newProfile = UserProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'New User',
          photoURL: firebaseUser.photoURL ?? '',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
        
        final profileData = newProfile.toFirestore();
        print('[Firestore] Profile data to write: $profileData');
        
        await userDoc.set(profileData);
        print('[Firestore] ✅ Successfully created new user profile for ${firebaseUser.email}');
      } else {
        // Existing user - update last active
        print('[Firestore] Updating existing user last active...');

        // Check if we need to reset thisMonthEarned (new month)
        final existingData = docSnapshot.data() as Map<String, dynamic>?;
        final lastActive = existingData?['lastActive'];
        final now = DateTime.now();
        Map<String, dynamic> updates = {'lastActive': Timestamp.now()};

        if (lastActive != null && lastActive is Timestamp) {
          final lastDate = lastActive.toDate();
          if (lastDate.month != now.month || lastDate.year != now.year) {
            // New month — reset monthly earnings
            updates['thisMonthEarned'] = 0.0;
            print('[Firestore] New month detected — resetting thisMonthEarned');
          }
        }

        await userDoc.update(updates);
        print('[Firestore] ✅ Updated last active for ${firebaseUser.email}');
      }
    } catch (e, stackTrace) {
      print('[Firestore] ❌ Error in createOrUpdateUserProfile: $e');
      print('[Firestore] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile([String? uid]) async {
    final userId = uid ?? currentUserId;
    if (userId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      print('[Firestore] Error getting user profile: $e');
      return null;
    }
  }

  /// Stream of current user's profile (real-time updates)
  Stream<UserProfile?> getUserProfileStream() {
    if (currentUserId == null) return Stream.value(null);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null)
        .handleError((e) {
          print('[Firestore] Error in user profile stream: $e');
          return null; // Return null on error so UI can handle it gracefully
        });
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('users').doc(currentUserId).update(updates);
    } catch (e) {
      print('[Firestore] Error updating profile: $e');
    }
  }

  // ===== TASK METHODS =====

  /// Create a new task
  Future<String> createTask(HeroTask task) async {
    if (currentUserId == null) throw Exception('User not logged in');

    try {
      // Read poster's actual rating from their profile
      double posterRating = 5.0;
      try {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (userDoc.exists) {
          posterRating = (userDoc.data()?['rating'] as num?)?.toDouble() ?? 5.0;
        }
      } catch (_) {
        // Fallback to 5.0 if we can't read the profile
      }

      final taskData = {
        'title': task.title,
        'description': task.description,
        'category': task.category.name,
        'compensation': task.compensation,
        'status': task.status.name,
        'urgency': task.urgency.name,
        'estimatedMinutes': task.estimatedMinutes,
        'pickup': {
          'building': task.pickup.building,
          'level': task.pickup.level,
          'landmark': task.pickup.landmark,
        },
        'delivery': {
          'building': task.delivery.building,
          'level': task.delivery.level,
          'landmark': task.delivery.landmark,
        },
        'posterId': currentUserId,
        'posterName': _auth.currentUser?.displayName ?? 'Unknown',
        'posterRating': posterRating,
        'posterAvatarUrl': _auth.currentUser?.photoURL ?? '',
        'heroId': null,
        'heroName': null,
        'pickedUp': false,
        'delivered': false,
        'createdAt': Timestamp.now(),
        'acceptedAt': null,
        'completedAt': null,
      };

      final docRef = await _firestore.collection('tasks').add(taskData);
      
      // Increment user's tasks posted count (best-effort)
      try {
        await _firestore.collection('users').doc(currentUserId).update({
          'tasksPosted': FieldValue.increment(1),
        });
      } catch (_) {
        // Non-critical — ignore
      }

      print('[Firestore] Created new task: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      final msg = e.toString();
      // Firestore Web SDK 11.9.1 bug: INTERNAL ASSERTION FAILED fires AFTER
      // the write succeeds. Treat it as non-fatal so the user sees success.
      if (msg.contains('INTERNAL ASSERTION FAILED') || msg.contains('Unexpected state')) {
        print('[Firestore] Ignoring known SDK assertion (write already committed): $e');
        return 'unknown';
      }
      print('[Firestore] Error creating task: $e');
      rethrow;
    }
  }

  /// Get all open tasks (for browsing)
  Stream<List<HeroTask>> getOpenTasks() {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _taskFromFirestore(doc))
            .toList())
        .handleError((e) {
          print('[Firestore] Error in open tasks stream: $e');
          return <HeroTask>[]; // Return empty list on error
        });
  }

  /// Stream a single task by ID (real-time updates)
  Stream<HeroTask?> getTaskStream(String taskId) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .snapshots()
        .map((doc) => doc.exists ? _taskFromFirestore(doc) : null)
        .handleError((e) {
          print('[Firestore] Error in task stream: $e');
          return null;
        });
  }

  /// Get ALL tasks (for browsing with filters)
  Stream<List<HeroTask>> getAllTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _taskFromFirestore(doc))
            .toList())
        .handleError((e) {
          print('[Firestore] Error in all tasks stream: $e');
          return <HeroTask>[];
        });
  }

  /// Get tasks posted by current user
  Stream<List<HeroTask>> getMyPostedTasks() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('posterId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _taskFromFirestore(doc))
            .toList())
        .handleError((e) {
          print('[Firestore] Error in posted tasks stream: $e');
          return <HeroTask>[];
        });
  }

  /// Get tasks accepted by current user
  Stream<List<HeroTask>> getMyAcceptedTasks() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('heroId', isEqualTo: currentUserId)
        .orderBy('acceptedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _taskFromFirestore(doc))
            .toList())
        .handleError((e) {
          print('[Firestore] Error in accepted tasks stream: $e');
          return <HeroTask>[];
        });
  }

  /// Get completed tasks for the last 7 days for the activity chart
  Future<List<Map<String, dynamic>>> getWeeklyCompletedTasks() async {
    if (currentUserId == null) return [];

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      print('[Firestore] Fetching completed tasks for activity chart...');
      
      // Simplify query: Fetch ALL completed tasks for user, filter locally.
      // This avoids "Int64 accessor" errors with Timestamp queries on web.
      final query = await _firestore
          .collection('tasks')
          .where('heroId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'completed')
          .get();

      print('[Firestore] Found ${query.docs.length} completed tasks. Filtering...');
      
      final tasks = query.docs
          .map((doc) {
            try {
              return _taskFromFirestore(doc);
            } catch (e) {
              print('[Firestore] Error mapping task ${doc.id}: $e');
              return null;
            }
          })
          .whereType<HeroTask>() // Filter out nulls
          .where((t) => t.completedAt != null && t.completedAt!.isAfter(sevenDaysAgo))
          .toList();
      
      print('[Firestore] Filtered to ${tasks.length} tasks in last 7 days.');

      // Group by day of week (Mon, Tue, etc.)
      // ... (rest of the processing logic remains the same)
      final Map<String, int> dayCounts = {
        'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
      };
      
      // Helper to get day name
      String getDayName(int weekday) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[weekday - 1];
      }

      // Initialize with 0 for the last 7 days specifically in order
      List<Map<String, dynamic>> result = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = getDayName(date.weekday);
        result.add({'day': dayName, 'count': 0, 'date': date});
      }

      // Populate counts
      for (var task in tasks) {
        if (task.completedAt != null) {
          final dayName = getDayName(task.completedAt!.weekday);
          // Find the matching day in our result list to ensure we count correctly for the specific date window
          for (var dayData in result) {
             final dayDate = dayData['date'] as DateTime;
             if (dayDate.day == task.completedAt!.day && dayDate.month == task.completedAt!.month) {
               dayData['count'] = (dayData['count'] as int) + 1;
             }
          }
        }
      }
      
      return result;
    } catch (e, stack) {
      print('[Firestore] Error fetching weekly tasks: $e');
      print('[Firestore] Stack trace: $stack');
      return []; // Return empty list on error
    }
  }

  /// Accept a task (uses transaction to prevent race conditions)
  Future<void> acceptTask(String taskId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final taskRef = _firestore.collection('tasks').doc(taskId);

    await _firestore.runTransaction((transaction) async {
      final taskSnapshot = await transaction.get(taskRef);
      final taskData = taskSnapshot.data();
      if (taskData == null) throw Exception('Task not found');

      if (taskData['posterId'] == currentUserId) {
        throw Exception('You cannot accept your own task');
      }

      if (taskData['status'] != 'open') {
        throw Exception('This task is no longer available');
      }

      transaction.update(taskRef, {
        'status': TaskStatus.accepted.name,
        'heroId': currentUserId,
        'heroName': _auth.currentUser?.displayName ?? 'Unknown',
        'acceptedAt': Timestamp.now(),
        'pickedUp': false,
        'delivered': false,
      });
    });

    print('[Firestore] Task $taskId accepted by $currentUserId');
  }

  /// Update task progress (pickedUp, delivered steps)
  Future<void> updateTaskProgress(String taskId, Map<String, dynamic> progress) async {
    if (currentUserId == null) throw Exception('User not logged in');
    await _firestore.collection('tasks').doc(taskId).update(progress);
    print('[Firestore] Task $taskId progress updated: $progress');
  }

  /// Cancel a task (only the poster can cancel an open task)
  Future<void> cancelTask(String taskId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final taskData = taskDoc.data();
    if (taskData == null) return;

    // Verify current user is the poster
    if (taskData['posterId'] != currentUserId) {
      throw Exception('Only the task poster can cancel this task');
    }

    // Only allow cancelling open tasks
    if (taskData['status'] != 'open') {
      throw Exception('Can only cancel tasks that are still open');
    }

    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.cancelled.name,
    });

    // Decrement the poster's tasksPosted count
    await _firestore.collection('users').doc(currentUserId).update({
      'tasksPosted': FieldValue.increment(-1),
    });

    print('[Firestore] Task $taskId cancelled by poster $currentUserId');
  }

  /// Complete a task
  Future<void> completeTask(String taskId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final taskData = taskDoc.data();
    if (taskData == null) throw Exception('Task not found');

    // Verify the current user is involved in this task (either hero or poster)
    final heroId = taskData['heroId'];
    final posterId = taskData['posterId'];
    if (heroId == null) throw Exception('No hero assigned to this task');

    if (currentUserId != heroId && currentUserId != posterId) {
      throw Exception('You are not authorized to complete this task');
    }

    if (taskData['status'] == TaskStatus.completed.name) {
      throw Exception('This task is already completed');
    }

    final compensation = (taskData['compensation'] as num).toDouble();
    final heroEarnings = compensation * 0.95; // 5% platform fee

    // Update task status
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.completed.name,
      'completedAt': Timestamp.now(),
    });

    // Update hero's earnings and completed count (use heroId, not currentUserId)
    await _firestore.collection('users').doc(heroId).update({
      'totalEarned': FieldValue.increment(heroEarnings),
      'thisMonthEarned': FieldValue.increment(heroEarnings),
      'tasksCompleted': FieldValue.increment(1),
    });

    print('[Firestore] Task $taskId completed. Hero $heroId earned \$$heroEarnings');
  }

  /// Helper to convert Firestore doc to HeroTask
  HeroTask _taskFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return HeroTask(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: TaskCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => TaskCategory.errands,
      ),
      compensation: (data['compensation'] as num).toDouble(),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TaskStatus.open,
      ),
      urgency: TaskUrgency.values.firstWhere(
        (u) => u.name == data['urgency'],
        orElse: () => TaskUrgency.normal,
      ),
      estimatedMinutes: data['estimatedMinutes'] ?? 0,
      pickup: TaskLocation(
        building: (data['pickup'] is Map) ? (data['pickup']['building'] ?? '') : '',
        level: (data['pickup'] is Map) ? (data['pickup']['level'] ?? '') : '',
        landmark: (data['pickup'] is Map) ? (data['pickup']['landmark'] ?? '') : '',
      ),
      delivery: TaskLocation(
        building: (data['delivery'] is Map) ? (data['delivery']['building'] ?? '') : '',
        level: (data['delivery'] is Map) ? (data['delivery']['level'] ?? '') : '',
        landmark: (data['delivery'] is Map) ? (data['delivery']['landmark'] ?? '') : '',
      ),
      posterId: data['posterId'],
      posterName: data['posterName'] ?? 'Unknown',
      posterRating: (data['posterRating'] as num?)?.toDouble() ?? 5.0,
      posterAvatarUrl: data['posterAvatarUrl'] ?? '',
      heroId: data['heroId'],
      heroName: data['heroName'],
      pickedUp: data['pickedUp'] ?? false,
      delivered: data['delivered'] ?? false,

      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // Fallback to avoid crash
      acceptedAt: data['acceptedAt'] != null && data['acceptedAt'] is Timestamp
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null && data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
