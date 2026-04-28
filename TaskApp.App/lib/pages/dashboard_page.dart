import 'package:flutter/material.dart';
import 'package:taskapp_app/models/task_model.dart';
import 'package:taskapp_app/pages/login_page.dart';
import 'package:taskapp_app/pages/projects_page.dart';
import 'package:taskapp_app/widgets/shared_widgets.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  final int userId;
  const DashboardPage(
      {super.key, required this.userName, required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Task> _tasks = [
    Task(
      title: 'UI tasarım revizyonu',
      category: 'Tasarım',
      categoryColor: Color(0xFF667eea),
      time: '09:00',
    ),
    Task(
      title: 'Haftalık rapor hazırla',
      category: 'İş',
      categoryColor: Color(0xFFFF8E53),
      time: '11:30',
    ),
    Task(
      title: 'Backend API entegrasyonu',
      category: 'Geliştirme',
      categoryColor: Color(0xFF2ECC71),
      time: '14:00',
      isDone: true,
    ),
    Task(
      title: 'Müşteri toplantısı',
      category: 'Toplantı',
      categoryColor: Color(0xFFFF6584),
      time: '15:00',
    ),
    Task(
      title: 'Unit testleri yaz',
      category: 'Geliştirme',
      categoryColor: Color(0xFF2ECC71),
      time: '16:30',
    ),
    Task(
      title: 'Pazar araştırması',
      category: 'Araştırma',
      categoryColor: Color(0xFF764ba2),
      time: '10:00',
      isDone: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
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

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yeni Görev',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Görev başlığı...',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  _tasks.insert(
                    0,
                    Task(
                      title: titleController.text.trim(),
                      category: 'Genel',
                      categoryColor: const Color(0xFF667eea),
                      time:
                          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
                    ),
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: FadeTransition(
        opacity: _fadeAnim,
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
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProjectsPage(
                          userId: widget.userId,
                          userName: widget.userName,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (_, animation, __) => FadeTransition(
                            opacity: animation, child: const LoginPage()),
                        transitionDuration: const Duration(milliseconds: 400),
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
                                backgroundColor: Colors.white.withOpacity(0.25),
                                child: Text(
                                  widget.userName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: Colors.white.withOpacity(0.75),
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
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _completionRatio,
                                          backgroundColor:
                                              Colors.white.withOpacity(0.2),
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
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = _tasks[index];
                  return _TaskCard(
                    task: task,
                    onToggle: () => setState(() => task.isDone = !task.isDone),
                  );
                },
                childCount: _tasks.length,
              ),
            ),

            // ── Add Task Button ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: GradientButton(
                  label: '+ Yeni Görev Ekle',
                  onPressed: () => _showAddTaskDialog(context),
                  isLoading: false,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF667eea).withOpacity(0.12),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF667eea)),
              label: 'Ana Sayfa'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon:
                  Icon(Icons.bar_chart_rounded, color: Color(0xFF667eea)),
              label: 'İstatistik'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon:
                  Icon(Icons.calendar_today_rounded, color: Color(0xFF667eea)),
              label: 'Takvim'),
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
                color:
                    task.isDone ? const Color(0xFF2ECC71) : Colors.transparent,
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
              color:
                  task.isDone ? Colors.grey.shade400 : const Color(0xFF1A1A2E),
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
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 12)),
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
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
