enum TaskCategory {
  food('Đồ ăn & Vật phẩm', '🍔'),
  academic('Hỗ trợ học tập', '📚'),
  errands('Việc vặt trong khuôn viên', '🏃'),
  tech('Công nghệ & Chế tạo', '🛠️'),
  social('Sự kiện & Giao lưu', '🤝'),
  marketplace('Chợ', '💼');

  final String label;
  final String emoji;
  const TaskCategory(this.label, this.emoji);
}

enum TaskStatus {
  open('Đang mở'),
  accepted('Đã nhận'),
  inProgress('Đang thực hiện'),
  completed('Đã hoàn thành'),
  cancelled('Đã hủy');

  final String label;
  const TaskStatus(this.label);
}

enum TaskUrgency { normal, urgent, emergency }

class TaskLocation {
  final String building;
  final String level;
  final String landmark;

  const TaskLocation({
    required this.building,
    required this.level,
    this.landmark = '',
  });

  String get short => '$building, $level';
  String get full => landmark.isNotEmpty ? '$building, $level ($landmark)' : short;
}

class HeroTask {
  final String? id;
  final String title;
  final String description;
  final TaskCategory category;
  final double compensation;
  final TaskStatus status;
  final TaskUrgency urgency;
  final int estimatedMinutes;
  final TaskLocation pickup;
  final TaskLocation delivery;
  final String? posterId;
  final String posterName;
  final double posterRating;
  final String posterAvatarUrl;
  final String? heroId;
  final String? heroName;
  final bool pickedUp;
  final bool delivered;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final bool isPaid;

  const HeroTask({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.compensation,
    required this.status,
    required this.urgency,
    required this.estimatedMinutes,
    required this.pickup,
    required this.delivery,
    this.posterId,
    required this.posterName,
    required this.posterRating,
    required this.posterAvatarUrl,
    this.heroId,
    this.heroName,
    this.pickedUp = false,
    this.delivered = false,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.isPaid = false,
  });

  double get platformFee => compensation * 0.05;
  double get heroEarnings => compensation - platformFee;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  HeroTask copyWith({TaskStatus? status, String? heroId, String? heroName, bool? pickedUp, bool? delivered, DateTime? acceptedAt, DateTime? completedAt, bool? isPaid}) {
    return HeroTask(
      id: id,
      title: title,
      description: description,
      category: category,
      compensation: compensation,
      status: status ?? this.status,
      urgency: urgency,
      estimatedMinutes: estimatedMinutes,
      pickup: pickup,
      delivery: delivery,
      posterId: posterId,
      posterName: posterName,
      posterRating: posterRating,
      posterAvatarUrl: posterAvatarUrl,
      heroId: heroId ?? this.heroId,
      heroName: heroName ?? this.heroName,
      pickedUp: pickedUp ?? this.pickedUp,
      delivered: delivered ?? this.delivered,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

// Mock data
final List<HeroTask> mockTasks = [
  HeroTask(
    id: '1',
    title: '🍗 Canteen Food Delivery',
    description: 'Pick up chicken rice (extra meat) from canteen',
    category: TaskCategory.food,
    compensation: 3.50,
    status: TaskStatus.open,
    urgency: TaskUrgency.normal,
    estimatedMinutes: 15,
    pickup: const TaskLocation(building: 'Building 2', level: 'Level 2', landmark: 'PKA Canteen'),
    delivery: const TaskLocation(building: 'Building 1', level: 'Level 7', landmark: 'Near Lobby C'),
    posterName: 'John Tan',
    posterRating: 4.8,
    posterAvatarUrl: 'https://ui-avatars.com/api/?name=John+Tan&background=random',
    createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
  ),
  HeroTask(
    id: '2',
    title: '📚 Math Tutoring Needed',
    description: '1hr session on calculus - help with integration by parts',
    category: TaskCategory.academic,
    compensation: 15.00,
    status: TaskStatus.open,
    urgency: TaskUrgency.normal,
    estimatedMinutes: 60,
    pickup: const TaskLocation(building: 'Building 1', level: 'Level 3', landmark: 'Study Room 3.2'),
    delivery: const TaskLocation(building: 'Building 1', level: 'Level 3', landmark: 'Study Room 3.2'),
    posterName: 'Ming Wei',
    posterRating: 5.0,
    posterAvatarUrl: 'https://ui-avatars.com/api/?name=Ming+Wei&background=random',
    createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  HeroTask(
    id: '3',
    title: '🏃 Package Pickup from Locker',
    description: 'Collect Shopee parcel from locker at Building 2 entrance and bring to hostel',
    category: TaskCategory.errands,
    compensation: 2.00,
    status: TaskStatus.open,
    urgency: TaskUrgency.urgent,
    estimatedMinutes: 10,
    pickup: const TaskLocation(building: 'Building 2', level: 'Level 1', landmark: 'Parcel Lockers'),
    delivery: const TaskLocation(building: 'Hostel', level: 'Level 5', landmark: 'Room 512'),
    posterName: 'Aisha Bte',
    posterRating: 4.6,
    posterAvatarUrl: 'https://ui-avatars.com/api/?name=Aisha+Bte&background=random',
    createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
  ),
  HeroTask(
    id: '4',
    title: '🛠️ Help Debug Python Script',
    description: 'Selenium scraper keeps crashing on dynamic page load. Need someone familiar with async waits.',
    category: TaskCategory.tech,
    compensation: 8.00,
    status: TaskStatus.open,
    urgency: TaskUrgency.normal,
    estimatedMinutes: 30,
    pickup: const TaskLocation(building: 'Building 1', level: 'Level 5', landmark: 'ISTD Cohort Space'),
    delivery: const TaskLocation(building: 'Building 1', level: 'Level 5', landmark: 'ISTD Cohort Space'),
    posterName: 'Raj Kumar',
    posterRating: 4.9,
    posterAvatarUrl: 'https://ui-avatars.com/api/?name=Raj+Kumar&background=random',
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  HeroTask(
    id: '5',
    title: '🍔 Bubble Tea Run',
    description: 'LiHo order: Brown Sugar Pearl Milk Tea (less ice, less sugar) x2',
    category: TaskCategory.food,
    compensation: 4.00,
    status: TaskStatus.open,
    urgency: TaskUrgency.normal,
    estimatedMinutes: 20,
    pickup: const TaskLocation(building: 'Changi City Point', level: 'Level 1', landmark: 'LiHo'),
    delivery: const TaskLocation(building: 'Building 2', level: 'Level 4', landmark: 'Near ASD Studio'),
    posterName: 'Sarah Lim',
    posterRating: 4.7,
    posterAvatarUrl: 'https://ui-avatars.com/api/?name=Sarah+Lim&background=random',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  HeroTask(
    id: '6',
    title: '📚 Proofread Report (2 pages)',
    description: 'Quick grammar and flow check on HASS essay due tonight',
    category: TaskCategory.academic,
    compensation: 5.00,
    status: TaskStatus.accepted,
    urgency: TaskUrgency.urgent,
    estimatedMinutes: 20,
    pickup: const TaskLocation(building: 'Online', level: 'Google Docs', landmark: 'Link in chat'),
    delivery: const TaskLocation(building: 'Online', level: 'Google Docs', landmark: 'Link in chat'),
    posterName: 'Li Xuan',
    posterRating: 4.5,
    posterAvatarUrl: 'https://ui-avatars.com/api/?name=Li+Xuan&background=random',
    heroName: 'You',
    createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    acceptedAt: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
];
