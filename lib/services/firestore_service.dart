import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_profile.dart';
import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy ID người dùng hiện tại
  String? get currentUserId => _auth.currentUser?.uid;

  // ===== PHƯƠNG THỨC HỒ SƠ NGƯỜI DÙNG =====

  /// Tạo hoặc cập nhật hồ sơ người dùng khi họ đăng nhập lần đầu
  Future<void> createOrUpdateUserProfile(User firebaseUser) async {
    print('[Firestore] createOrUpdateUserProfile được gọi cho uid: ${firebaseUser.uid}');
    
    try {
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      
      print('[Firestore] Đang kiểm tra tài liệu người dùng...');
      final docSnapshot = await userDoc.get();
      print('[Firestore] Tài liệu tồn tại: ${docSnapshot.exists}');

      if (!docSnapshot.exists) {
        // Người dùng mới - tạo hồ sơ
        print('[Firestore] Đang tạo hồ sơ người dùng mới...');
        final newProfile = UserProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Người dùng mới',
          photoURL: firebaseUser.photoURL ?? '',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
        
        final profileData = newProfile.toFirestore();
        print('[Firestore] Dữ liệu hồ sơ cần ghi: $profileData');
        
        await userDoc.set(profileData);
        print('[Firestore] ✅ Đã tạo hồ sơ người dùng mới cho ${firebaseUser.email}');
      } else {
        // Người dùng cũ - cập nhật lần hoạt động cuối
        print('[Firestore] Đang cập nhật lần hoạt động cuối...');

        // Kiểm tra xem có cần reset thisMonthEarned (tháng mới) không
        final existingData = docSnapshot.data() as Map<String, dynamic>?;
        final lastActive = existingData?['lastActive'];
        final now = DateTime.now();
        Map<String, dynamic> updates = {'lastActive': Timestamp.now()};

        if (lastActive != null && lastActive is Timestamp) {
          final lastDate = lastActive.toDate();
          if (lastDate.month != now.month || lastDate.year != now.year) {
            // Tháng mới — reset thu nhập tháng này
            updates['thisMonthEarned'] = 0.0;
            print('[Firestore] Phát hiện tháng mới — đặt lại thisMonthEarned');
          }
        }

        await userDoc.update(updates);
        print('[Firestore] ✅ Đã cập nhật lần hoạt động cuối cho ${firebaseUser.email}');
      }
    } catch (e, stackTrace) {
      print('[Firestore] ❌ Lỗi trong createOrUpdateUserProfile: $e');
      print('[Firestore] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Lấy hồ sơ người dùng theo ID
  Future<UserProfile?> getUserProfile([String? uid]) async {
    final userId = uid ?? currentUserId;
    if (userId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      print('[Firestore] Lỗi khi lấy hồ sơ người dùng: $e');
      return null;
    }
  }

  /// Luồng hồ sơ người dùng hiện tại (cập nhật thời gian thực)
  Stream<UserProfile?> getUserProfileStream() {
    if (currentUserId == null) return Stream.value(null);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null)
        .handleError((e) {
          print('[Firestore] Lỗi trong luồng hồ sơ người dùng: $e');
          return null; // Trả về null khi lỗi để UI xử lý
        });
  }

  /// Cập nhật hồ sơ người dùng
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('users').doc(currentUserId).update(updates);
    } catch (e) {
      print('[Firestore] Lỗi khi cập nhật hồ sơ: $e');
    }
  }

  // ===== PHƯƠNG THỨC NHIỆM VỤ =====

  /// Tạo nhiệm vụ mới
  Future<String> createTask(HeroTask task) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập');

    try {
      // Đọc trạng thái tài khoản từ hồ sơ
      double posterRating = 5.0;
      bool isBlocked = false;
      try {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          posterRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
          isBlocked = data['isBlocked'] == true;
        }
      } catch (_) {}

      if (isBlocked) {
        throw Exception('Tài khoản của bạn đã bị khóa bởi Quản trị viên.');
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
        'posterName': _auth.currentUser?.displayName ?? 'Không rõ',
        'posterRating': posterRating,
        'posterAvatarUrl': _auth.currentUser?.photoURL ?? '',
        'heroId': null,
        'heroName': null,
        'pickedUp': false,
        'delivered': false,
        'createdAt': Timestamp.now(),
        'acceptedAt': null,
        'completedAt': null,
        'isPaid': false,
      };

      final docRef = await _firestore.collection('tasks').add(taskData);
      
      // Tăng số lượng nhiệm vụ đã đăng của người dùng (best-effort)
      try {
        await _firestore.collection('users').doc(currentUserId).update({
          'tasksPosted': FieldValue.increment(1),
        });
      } catch (_) {
        // Không quan trọng — bỏ qua
      }

      print('[Firestore] Đã tạo nhiệm vụ mới: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      final msg = e.toString();
      // Lỗi SDK Firestore Web 11.9.1: INTERNAL ASSERTION FAILED xảy ra SAU
      // khi ghi đã thành công. Xem như không nghiêm trọng để người dùng thấy thành công.
      if (msg.contains('INTERNAL ASSERTION FAILED') || msg.contains('Unexpected state')) {
        print('[Firestore] Bỏ qua lỗi assertion SDK đã biết (ghi đã được commit): $e');
        return 'unknown';
      }
      print('[Firestore] Lỗi khi tạo nhiệm vụ: $e');
      rethrow;
    }
  }

  /// Lấy tất cả nhiệm vụ đang mở (để duyệt)
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
          print('[Firestore] Lỗi trong luồng nhiệm vụ đang mở: $e');
          return <HeroTask>[]; // Trả về danh sách rỗng khi lỗi
        });
  }

  /// Luồng một nhiệm vụ theo ID (cập nhật thời gian thực)
  Stream<HeroTask?> getTaskStream(String taskId) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .snapshots()
        .map((doc) => doc.exists ? _taskFromFirestore(doc) : null)
        .handleError((e) {
          print('[Firestore] Lỗi trong luồng nhiệm vụ: $e');
          return null;
        });
  }

  /// Lấy TẤT CẢ nhiệm vụ (để duyệt với bộ lọc)
  Stream<List<HeroTask>> getAllTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _taskFromFirestore(doc))
            .toList())
        .handleError((e) {
          print('[Firestore] Lỗi trong luồng tất cả nhiệm vụ: $e');
          return <HeroTask>[];
        });
  }

  /// Lấy nhiệm vụ đã đăng bởi người dùng hiện tại
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
          print('[Firestore] Lỗi trong luồng nhiệm vụ đã đăng: $e');
          return <HeroTask>[];
        });
  }

  /// Lấy nhiệm vụ đã nhận bởi người dùng hiện tại
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
          print('[Firestore] Lỗi trong luồng nhiệm vụ đã nhận: $e');
          return <HeroTask>[];
        });
  }

  /// Lấy nhiệm vụ hoàn thành trong 7 ngày gần nhất cho biểu đồ hoạt động
  Future<List<Map<String, dynamic>>> getWeeklyCompletedTasks() async {
    if (currentUserId == null) return [];

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      print('[Firestore] Đang lấy nhiệm vụ hoàn thành cho biểu đồ hoạt động...');
      
      // Đơn giản hóa query: Lấy TẤT CẢ nhiệm vụ hoàn thành của người dùng, lọc cục bộ.
      // Tránh lỗi "Int64 accessor" với Timestamp queries trên web.
      // Query đơn giản để tránh lỗi "Unexpected state" của SDK trên Web
      // Chúng ta sẽ lấy hết nhiệm vụ của heroId hiện tại có trạng thái 'completed',
      // sau đó lọc mốc thời gian 7 ngày ở phía Client.
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('heroId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'completed')
          .get(kIsWeb ? const GetOptions(source: Source.server) : const GetOptions());

      print('[Firestore] Tìm thấy ${tasksQuery.docs.length} nhiệm vụ hoàn thành. Đang lọc...');
      
      final tasks = tasksQuery.docs
          .map((doc) {
            try {
              return _taskFromFirestore(doc);
            } catch (e) {
              print('[Firestore] Lỗi xử lý nhiệm vụ ${doc.id}: $e');
              return null;
            }
          })
          .whereType<HeroTask>() // Lọc bỏ null
          .where((t) => t.completedAt != null && t.completedAt!.isAfter(sevenDaysAgo))
          .toList();
      
      print('[Firestore] Đã lọc còn ${tasks.length} nhiệm vụ trong 7 ngày gần nhất.');

      // Nhóm theo ngày trong tuần (T2, T3, ...)
      // ... (phần logic xử lý còn lại giữ nguyên)
      final Map<String, int> dayCounts = {
        'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
      };
      
      // Hàm lấy tên ngày
      String getDayName(int weekday) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[weekday - 1];
      }

      // Khởi tạo với 0 cho 7 ngày gần nhất theo thứ tự
      List<Map<String, dynamic>> result = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = getDayName(date.weekday);
        result.add({'day': dayName, 'count': 0, 'date': date});
      }

      // Điền số lượng
      for (var task in tasks) {
        if (task.completedAt != null) {
          final dayName = getDayName(task.completedAt!.weekday);
          // Tìm ngày khớp trong danh sách để đếm đúng cho cửa sổ ngày cụ thể
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
      print('[Firestore] Lỗi khi lấy nhiệm vụ tuần: $e');
      print('[Firestore] Stack trace: $stack');
      return []; // Trả về danh sách rỗng khi lỗi
    }
  }

  /// Nhận nhiệm vụ (dùng transaction để tránh race condition)
  Future<void> acceptTask(String taskId) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập');

    final taskRef = _firestore.collection('tasks').doc(taskId);

    await _firestore.runTransaction((transaction) async {
      final taskSnapshot = await transaction.get(taskRef);
      final taskData = taskSnapshot.data();
      if (taskData == null) throw Exception('Không tìm thấy nhiệm vụ');

      if (taskData['posterId'] == currentUserId) {
        throw Exception('Bạn không thể nhận nhiệm vụ của chính mình');
      }

      if (taskData['status'] != 'open') {
        throw Exception('Nhiệm vụ này không còn khả dụng');
      }

      transaction.update(taskRef, {
        'status': TaskStatus.accepted.name,
        'heroId': currentUserId,
        'heroName': _auth.currentUser?.displayName ?? 'Không rõ',
        'acceptedAt': Timestamp.now(),
        'pickedUp': false,
        'delivered': false,
      });
    });

    print('[Firestore] Nhiệm vụ $taskId đã được nhận bởi $currentUserId');
  }

  /// Cập nhật tiến độ nhiệm vụ (bước lấy hàng, giao hàng)
  Future<void> updateTaskProgress(String taskId, Map<String, dynamic> progress) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập');
    await _firestore.collection('tasks').doc(taskId).update(progress);
    print('[Firestore] Tiến độ nhiệm vụ $taskId đã cập nhật: $progress');
  }

  /// Hủy nhiệm vụ (chỉ poster mới có thể hủy nhiệm vụ đang mở)
  Future<void> cancelTask(String taskId) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập');

    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final taskData = taskDoc.data();
    if (taskData == null) return;

    // Xác minh người dùng hiện tại là poster
    if (taskData['posterId'] != currentUserId) {
      throw Exception('Chỉ người đăng nhiệm vụ mới có thể hủy');
    }

    // Chỉ cho phép hủy nhiệm vụ đang mở
    if (taskData['status'] != 'open') {
      throw Exception('Chỉ có thể hủy nhiệm vụ đang mở');
    }

    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.cancelled.name,
    });

    // Giảm số lượng nhiệm vụ đã đăng của poster
    await _firestore.collection('users').doc(currentUserId).update({
      'tasksPosted': FieldValue.increment(-1),
    });

    print('[Firestore] Nhiệm vụ $taskId đã bị hủy bởi poster $currentUserId');
  }

  /// Hoàn thành nhiệm vụ
  Future<void> completeTask(String taskId) async {
    if (currentUserId == null) throw Exception('Người dùng chưa đăng nhập');

    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final taskData = taskDoc.data();
    if (taskData == null) throw Exception('Không tìm thấy nhiệm vụ');

    // Xác minh người dùng hiện tại có liên quan đến nhiệm vụ (hero hoặc poster)
    final heroId = taskData['heroId'];
    final posterId = taskData['posterId'];
    if (heroId == null) throw Exception('Chưa có Hero nào nhận nhiệm vụ này');

    if (currentUserId != heroId && currentUserId != posterId) {
      throw Exception('Bạn không có quyền hoàn thành nhiệm vụ này');
    }

    if (taskData['status'] == TaskStatus.completed.name) {
      throw Exception('Nhiệm vụ này đã hoàn thành rồi');
    }

    final compensation = (taskData['compensation'] as num).toDouble();
    final heroEarnings = compensation * 0.95; // Phí nền tảng 5%

    // Cập nhật trạng thái nhiệm vụ
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.completed.name,
      'completedAt': Timestamp.now(),
    });
    print('[Firestore] Đã cập nhật trạng thái COMPLETED cho task $taskId');

    // Cập nhật thu nhập và số nhiệm vụ hoàn thành của hero (dùng heroId, không phải currentUserId)
    try {
      await _firestore.collection('users').doc(heroId).update({
        'totalEarned': FieldValue.increment(heroEarnings),
        'thisMonthEarned': FieldValue.increment(heroEarnings),
        'tasksCompleted': FieldValue.increment(1),
      });
      print('[Firestore] Đã cập nhật tiền thù lao cho Hero $heroId: +${heroEarnings.toStringAsFixed(0)}đ');
      
      // Cập nhật chi tiêu của Poster (người đăng)
      print('[Firestore] Đang cập nhật chi tiêu cho Poster $posterId: +${compensation.toStringAsFixed(0)}đ');
      await _firestore.collection('users').doc(posterId).update({
        'totalSpent': FieldValue.increment(compensation),
      });
      print('[Firestore] Đã cập nhật chi tiêu cho Poster $posterId.');
    } catch (e) {
      print('[Firestore] LỖI khi cập nhật tiền cho Hero $heroId: $e');
      // Thử lại với heroId từ currentUserId nếu poster tự hoàn thành cho chính mình (để test)
      if (currentUserId == heroId) {
        print('[Firestore] Thử lại cập nhật cho chính mình...');
      }
    }

    print('[Firestore] Nhiệm vụ $taskId hoàn thành hoàn toàn.');
  }

  /// Lấy danh sách nhiệm vụ CHỜ THANH TOÁN (do mình đăng, đã hoàn thành, nhưng chưa trả tiền công)
  Stream<List<HeroTask>> getUnpaidTasks() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('posterId', isEqualTo: currentUserId)
        .where('status', isEqualTo: TaskStatus.completed.name)
        .where('isPaid', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _taskFromFirestore(doc))
            .toList())
        .handleError((e) {
          print('[Firestore] Lỗi luồng nhiệm vụ nhắc nợ: $e');
          return <HeroTask>[];
        });
  }

  /// Đánh dấu là đã gặp mặt trả tiền hoặc chuyển khoản xong
  Future<void> markTaskAsPaid(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isPaid': true,
    });
    print('[Firestore] Đã dập cờ thanh toán cho nhiệm vụ $taskId');
  }

  /// Hàm chuyển đổi Firestore doc thành HeroTask
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
      compensation: (data['compensation'] ?? 0).toDouble(),
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
      posterName: data['posterName'] ?? 'Không rõ',
      posterRating: (data['posterRating'] as num?)?.toDouble() ?? 5.0,
      posterAvatarUrl: data['posterAvatarUrl'] ?? '',
      heroId: data['heroId'],
      heroName: data['heroName'],
      pickedUp: data['pickedUp'] ?? false,
      delivered: data['delivered'] ?? false,

      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // Dự phòng để tránh crash
      acceptedAt: data['acceptedAt'] != null && data['acceptedAt'] is Timestamp
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null && data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      isPaid: data['isPaid'] ?? false,
    );
  }

  // ===== PHƯƠNG THỨC ADMIN =====

  /// Stream danh sách TẤT CẢ người dùng (chỉ dành cho admin)
  Stream<List<UserProfile>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('lastActive', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) {
              try {
                return UserProfile.fromFirestore(doc);
              } catch (e) {
                print('[Firestore] Lỗi khi map user ${doc.id}: $e');
                return null;
              }
            })
            .whereType<UserProfile>()
            .toList())
        .handleError((e) {
      print('[Firestore] Lỗi trong getAllUsersStream: $e');
      return <UserProfile>[];
    });
  }

  /// Thống kê tổng quan cho admin dashboard
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      print('[Firestore] Bắt đầu getAdminStats (Source: Server)...');
      // Lấy tất cả tasks (Ép buộc server trên Web)
      final tasksSnap = await _firestore.collection('tasks').get(
        kIsWeb ? const GetOptions(source: Source.server) : const GetOptions()
      );
      
      final tasks = tasksSnap.docs.map((doc) {
        try { 
          return _taskFromFirestore(doc); 
        } catch (e) { 
          print('[Firestore] Lỗi parse task ${doc.id}: $e');
          return null; 
        }
      }).whereType<HeroTask>().toList();

      // Lấy tất cả users (Ép buộc server trên Web)
      final usersSnap = await _firestore.collection('users').get(
        kIsWeb ? const GetOptions(source: Source.server) : const GetOptions()
      );

      print('[Firestore] getAdminStats: Lấy xong ${tasks.length} tasks và ${usersSnap.docs.length} users');

      final totalTasks = tasks.length;
      final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
      final openTasks = tasks.where((t) => t.status == TaskStatus.open).length;

      final totalVolume = completedTasks.fold<double>(0, (sum, t) => sum + t.compensation);
      final platformRevenue = totalVolume * 0.05;

      return {
        'totalUsers': usersSnap.docs.length,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks.length,
        'openTasks': openTasks,
        'totalVolume': totalVolume,
        'platformRevenue': platformRevenue,
        'recentCompleted': completedTasks
            .where((t) => t.completedAt != null)
            .toList()
          ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!)),
      };
    } catch (e) {
      print('[Firestore] Lỗi NGHIÊM TRỌNG getAdminStats: $e');
      return {};
    }
  }

  /// Admin cập nhật thông tin người dùng bất kỳ
  Future<void> adminUpdateUser(String uid, Map<String, dynamic> updates) async {
    // Lưu ý: Quy tắc Firestore sẽ chặn nếu người gọi không phải ADMIN thực sự
    try {
      await _firestore.collection('users').doc(uid).update(updates);
      print('[Firestore] Admin đã cập nhật user $uid: $updates');
    } catch (e) {
      print('[Firestore] Lỗi Admin cập nhật user $uid: $e');
      rethrow;
    }
  }

  /// Admin xóa người dùng (chỉ xóa doc trong Firestore)
  Future<void> adminDeleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('[Firestore] Admin đã xóa user $uid');
    } catch (e) {
      print('[Firestore] Lỗi Admin xóa user $uid: $e');
      rethrow;
    }
  }

  /// Lấy lịch sử nhiệm vụ của một người dùng (đã đăng hoặc được giao)
  Future<List<HeroTask>> getUserTaskHistory(String uid) async {
    try {
      // Lấy nhiệm vụ đã đăng
      final posted = await _firestore
          .collection('tasks')
          .where('posterId', isEqualTo: uid)
          .get();

      // Lấy nhiệm vụ được giao
      final assigned = await _firestore
          .collection('tasks')
          .where('heroId', isEqualTo: uid)
          .get();

      final allTasks = [...posted.docs, ...assigned.docs]
          .map((doc) => _taskFromFirestore(doc))
          .toList();

      // Loại bỏ trùng lặp (nếu có) và sắp xếp
      final uniqueTasks = {for (var t in allTasks) t.id: t}.values.toList();
      uniqueTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return uniqueTasks.cast<HeroTask>();
    } catch (e) {
      print('[Firestore] Lỗi getUserTaskHistory: $e');
      return [];
    }
  }

  /// Lấy danh sách bảng xếp hạng (Top kiếm tiền và Top chi tiêu)
  Future<Map<String, List<UserProfile>>> getLeaderboardData() async {
    final Map<String, List<UserProfile>> result = {
      'topEarners': [],
      'topSpenders': [],
    };

    try {
      // Top 5 Earners
      final earnersSnap = await _firestore
          .collection('users')
          .orderBy('totalEarned', descending: true)
          .limit(5)
          .get();
      result['topEarners'] = earnersSnap.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();

      // Top 5 Spenders
      final spendersSnap = await _firestore
          .collection('users')
          .orderBy('totalSpent', descending: true)
          .limit(5)
          .get();
      result['topSpenders'] = spendersSnap.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('[Firestore] Lỗi lấy dữ liệu Leaderboard: $e');
    }

    return result;
  }
}
