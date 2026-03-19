import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/task_model.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/browse_screen.dart';
import 'screens/post_task_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';
import 'services/firestore_service.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    try {
      // Use long polling instead of WebSockets to fix "Unable to establish connection on channel" error
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        webExperimentalForceLongPolling: true,
      );
      print('[Firebase] Firestore settings applied with long polling enabled');
    } catch (e) {
      print('[Firebase] Settings already applied or error: $e');
    }
  }

  Animate.restartOnHotReload = true;
  runApp(const TaskHeroApp());
}

class TaskHeroApp extends StatelessWidget {
  const TaskHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'TaskHero',
      themeMode: ThemeMode.light,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadOrangeColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadOrangeColorScheme.dark(),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Show login screen if not authenticated
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen();
          }
          
          // Show app if authenticated
          return const AppShell();
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final FirestoreService _firestoreService = FirestoreService();
  int _page = 0;
  HeroTask? _selectedTask;
  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _firestoreService.getUserProfileStream().listen((profile) {
      if (mounted) setState(() => _currentUser = profile);
    });
  }

  bool get _isAdmin => _currentUser?.isAdmin == true;

  List<({IconData icon, String label})> get _navItems {
    final base = [
      (icon: LucideIcons.house, label: 'Bảng điều khiển'),
      (icon: LucideIcons.listTodo, label: 'Nhiệm vụ'),
      (icon: LucideIcons.circlePlus, label: 'Đăng nhiệm vụ'),
      (icon: LucideIcons.user, label: 'Hồ sơ'),
    ];
    if (_isAdmin) {
      return [...base, (icon: LucideIcons.shieldCheck, label: 'Admin')];
    }
    return base;
  }

  void _nav(int i) => setState(() {
        _page = i;
        _selectedTask = null;
      });
  void _openTask(HeroTask t) => setState(() => _selectedTask = t);
  void _closeTask() => setState(() => _selectedTask = null);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: isMobile
          ? (_selectedTask != null
              ? TaskDetailScreen(task: _selectedTask!, onBack: _closeTask)
              : _buildPage())
          : Row(
              children: [
                _buildSidebar(theme),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTask?.id ?? _page),
                      child: _selectedTask != null
                          ? TaskDetailScreen(
                              task: _selectedTask!, onBack: _closeTask)
                          : _buildPage(),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isMobile ? _buildBottomNav(theme) : null,
    );
  }

  // ─── SIDEBAR (desktop) ─────────────────────────────────────
  Widget _buildSidebar(ShadThemeData theme) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        border:
            Border(right: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(LucideIcons.shield,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text('TaskHero', style: theme.textTheme.h4),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Trang chủ',
                style: theme.textTheme.muted.copyWith(
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final active = _page == i && _selectedTask == null;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Material(
                color: active
                    ? AppColors.orangeLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _nav(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(item.icon,
                            size: 16,
                            color: active
                                ? AppColors.orange600
                                : theme.colorScheme.mutedForeground),
                        const SizedBox(width: 10),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: active
                                ? AppColors.orange600
                                : theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Tích hợp',
                style: theme.textTheme.muted.copyWith(
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          _sidebarLabel(theme, LucideIcons.sparkles, 'OpenAI GPT-4o'),
          _sidebarLabel(theme, LucideIcons.mic, 'Deepgram STT'),
          _sidebarLabel(theme, LucideIcons.database, 'Firebase Storage'),
          _sidebarLabel(theme, LucideIcons.creditCard, 'Google Pay'),
          const Spacer(),
          // Bottom user - from Firestore
          StreamBuilder<UserProfile?>(
            stream: _firestoreService.getUserProfileStream(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final displayName = user?.displayName ?? 'Loading...';
              final pillarYear = user != null ? '${user.pillar} Year ${user.year}' : '';
              final photoUrl = user?.photoURL ?? '';
              final initials = user?.initials ?? '?';
              
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: theme.colorScheme.border)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    photoUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(photoUrl),
                          )
                        : CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.orangeMid,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orange600,
                              ),
                            ),
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.foreground)),
                          Text(pillarYear,
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      theme.colorScheme.mutedForeground)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sidebarLabel(
      ShadThemeData theme, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon,
                size: 14, color: theme.colorScheme.mutedForeground),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.mutedForeground)),
            const Spacer(),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF16A34A)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM NAV (mobile) ───────────────────────────────────
  Widget _buildBottomNav(ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(
            top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final active = _page == i && _selectedTask == null;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _nav(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon,
                          size: 20,
                          color: active
                              ? AppColors.orange500
                              : theme.colorScheme.mutedForeground),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active
                              ? AppColors.orange500
                              : theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case 0:
        return HomeScreen(onNavigate: _nav, onTaskTap: _openTask);
      case 1:
        return BrowseScreen(onTaskTap: _openTask);
      case 2:
        return const PostTaskScreen();
      case 3:
        return ProfileScreen(onTaskTap: _openTask);
      case 4:
        return _isAdmin ? const AdminScreen() : HomeScreen(onNavigate: _nav, onTaskTap: _openTask);
      default:
        return HomeScreen(onNavigate: _nav, onTaskTap: _openTask);
    }
  }
}
