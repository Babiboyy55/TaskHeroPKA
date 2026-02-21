import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String pillar;
  final int year;
  final double totalEarned;
  final double thisMonthEarned;
  final int tasksCompleted;
  final int tasksPosted;
  final double rating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime lastActive;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    this.pillar = 'ISTD',
    this.year = 1,
    this.totalEarned = 0.0,
    this.thisMonthEarned = 0.0,
    this.tasksCompleted = 0,
    this.tasksPosted = 0,
    this.rating = 5.0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.lastActive,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'] ?? '',
      pillar: data['pillar'] ?? 'ISTD',
      year: data['year'] ?? 1,
      totalEarned: (data['totalEarned'] ?? 0.0).toDouble(),
      thisMonthEarned: (data['thisMonthEarned'] ?? 0.0).toDouble(),
      tasksCompleted: data['tasksCompleted'] ?? 0,
      tasksPosted: data['tasksPosted'] ?? 0,
      rating: (data['rating'] ?? 5.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActive: data['lastActive'] is Timestamp
          ? (data['lastActive'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'pillar': pillar,
      'year': year,
      'totalEarned': totalEarned,
      'thisMonthEarned': thisMonthEarned,
      'tasksCompleted': tasksCompleted,
      'tasksPosted': tasksPosted,
      'rating': rating,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? pillar,
    int? year,
    double? totalEarned,
    double? thisMonthEarned,
    int? tasksCompleted,
    int? tasksPosted,
    double? rating,
    int? totalReviews,
    DateTime? lastActive,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      pillar: pillar ?? this.pillar,
      year: year ?? this.year,
      totalEarned: totalEarned ?? this.totalEarned,
      thisMonthEarned: thisMonthEarned ?? this.thisMonthEarned,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksPosted: tasksPosted ?? this.tasksPosted,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  String get pillarYear => 'Pillar: $pillar | Year $year';
}
