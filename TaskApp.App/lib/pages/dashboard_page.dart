import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taskapp_app/models/task_model.dart';
import 'package:taskapp_app/pages/login_page.dart';
import 'package:taskapp_app/pages/projects_page.dart';
import 'package:taskapp_app/pages/profile_page.dart';
import 'package:taskapp_app/pages/tasks_page.dart';
import 'package:taskapp_app/widgets/shared_widgets.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  final int userId;
  final String userEmail;
  const DashboardPage({
    super.key,
    required this.userName,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://localhost:7062/api/Task/user/${widget.userId}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          setState(() {
            _tasks = data.map((json) => Task.fromJson(json)).where((task) {
              if (task.dueDate == null) return false;
              final taskDate = task.dueDate!.toLocal();
              return taskDate.year == today.year && 
                     taskDate.month == today.month && 
                     taskDate.day == today.day;
            }).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Dashboard görev çekme hatası: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final newStatus = task.isDone ? 'Pending' : 'Completed';
    try {
      final response = await http.patch(
        Uri.parse('https://localhost:7062/api/Task/${task.id}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          task.isDone = !task.isDone;
        });
      }
    } catch (e) {
      debugPrint('Durum güncellenemedi: $e');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _completedCount => _tasks.where((t) => t.isDone).length;
  double get _completionRatio =>
      _tasks.isEmpty ? 0 : _completedCount / _tasks.length;

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın! ☀️';
    if (hour < 18) return 'İyi öğleden sonralar! 🌤️';
    return 'İyi akşamlar! 🌙';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _selectedIndex == 1
            ? ProjectsPage(userId: widget.userId)
            : _selectedIndex == 2
                ? TasksPage(userId: widget.userId)
                : _selectedIndex == 3
                    ? ProfilePage(
                        userId: widget.userId,
                        userName: widget.userName,
                        userEmail: widget.userEmail,
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchTasks,
                        child: CustomScrollView(
                            slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: const Color(0xFF667eea),
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon:
                      const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (_, animation, __) => FadeTransition(
                            opacity: animation,
                            child: const LoginPage()),
                        transitionDuration:
                            const Duration(milliseconds: 400),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    Colors.white.withOpacity(0.25),
                                child: Text(
                                  widget.userName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Merhaba, ${widget.userName} 👋',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    _greetingText(),
                                    style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.75),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Progress Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Günlük İlerleme',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _completionRatio,
                                          backgroundColor: Colors.white
                                              .withOpacity(0.2),
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  Colors.white),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '$_completedCount/${_tasks.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Stats Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Toplam',
                      value: '${_tasks.length}',
                      icon: Icons.list_alt_rounded,
                      color: const Color(0xFF667eea),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Tamamlanan',
                      value: '$_completedCount',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF2ECC71),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Bekleyen',
                      value: '${_tasks.length - _completedCount}',
                      icon: Icons.pending_outlined,
                      color: const Color(0xFFFF8E53),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section Title ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bugünün Görevleri',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E)),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Tümünü gör',
                          style: TextStyle(color: Color(0xFF667eea))),
                    ),
                  ],
                ),
              ),
            ),

            // ── Task List ──
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    )),
                  )
                : _tasks.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Center(
                            child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('Henüz görev yok.'),
                        )),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = _tasks[index];
                            return _TaskCard(
                              task: task,
                              onToggle: () => _toggleTaskStatus(task),
                            );
                          },
                          childCount: _tasks.length,
                        ),
                      ),


          ],
        ),
      ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          if (i == 0) _fetchTasks();
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF667eea).withOpacity(0.12),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon:
                  Icon(Icons.home_rounded, color: Color(0xFF667eea)),
              label: 'Ana Sayfa'),
          NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon:
                  Icon(Icons.folder_rounded, color: Color(0xFF667eea)),
              label: 'Projeler'),
          NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt_rounded,
                  color: Color(0xFF667eea)),
              label: 'Görevler'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: Color(0xFF667eea)),
              label: 'Profil'),
        ],
      ),
    );
  }
}

// ─── Task Card ────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const _TaskCard({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone
                    ? const Color(0xFF2ECC71)
                    : Colors.transparent,
                border: Border.all(
                  color: task.isDone
                      ? const Color(0xFF2ECC71)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: task.isDone
                  ? Colors.grey.shade400
                  : const Color(0xFF1A1A2E),
              decoration: task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: task.categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.category,
                    style: TextStyle(
                        color: task.categoryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.schedule_rounded,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(task.time,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
          trailing: Icon(Icons.more_vert_rounded,
              color: Colors.grey.shade300, size: 20),
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            Text(label,
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
