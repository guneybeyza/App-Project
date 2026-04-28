import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taskapp_app/models/task_model.dart';
import 'package:taskapp_app/widgets/shared_widgets.dart';

class TasksPage extends StatefulWidget {
  final int userId;
  const TasksPage({super.key, required this.userId});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  List<dynamic> _projects = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final response = await http.get(
        Uri.parse('https://localhost:7062/api/Project/user/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _projects = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Proje yükleme hatası: $e');
    }
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://localhost:7062/api/Task/user/${widget.userId}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _tasks = data.map((json) => Task.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        _showSnack('Görevler alınamadı.', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnack('Hata: $e', isError: true);
      setState(() => _isLoading = false);
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
      } else {
        _showSnack('Durum güncellenemedi.', isError: true);
      }
    } catch (e) {
      _showSnack('Bağlantı hatası.', isError: true);
    }
  }

  Future<void> _updateTask(int id, String title, String description, String status, DateTime dueDate, int projectId) async {
    try {
      final response = await http.put(
        Uri.parse('https://localhost:7062/api/Task/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'status': status,
          'dueDate': dueDate.toIso8601String(),
          'projectId': projectId,
        }),
      );

      if (response.statusCode == 200) {
        _showSnack('Görev güncellendi.');
        _fetchTasks();
      } else {
        _showSnack('Güncelleme başarısız.', isError: true);
      }
    } catch (e) {
      _showSnack('Bağlantı hatası.', isError: true);
    }
  }

  Future<void> _deleteTask(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: const Text('Bu görevi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(Uri.parse('https://localhost:7062/api/Task/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnack('Görev silindi.');
        _fetchTasks();
      } else {
        _showSnack('Silme başarısız.', isError: true);
      }
    } catch (e) {
      _showSnack('Bağlantı hatası.', isError: true);
    }
  }

  Future<void> _createTask(String title, String description, String status, DateTime dueDate, int projectId) async {
    try {
      final response = await http.post(
        Uri.parse('https://localhost:7062/api/Task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'status': status,
          'dueDate': dueDate.toIso8601String(),
          'projectId': projectId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnack('Görev başarıyla oluşturuldu! 🎉');
        _fetchTasks();
      } else {
        _showSnack('Görev oluşturulamadı.', isError: true);
      }
    } catch (e) {
      _showSnack('Bağlantı hatası.', isError: true);
    }
  }

  void _showTaskDialog({Task? task}) {
    final isEdit = task != null;
    final titleController = TextEditingController(text: task?.title);
    final descController = TextEditingController(text: task?.description);
    String status = task?.status ?? 'Pending';
    DateTime selectedDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    int? selectedProjectId = task?.projectId ?? (_projects.isNotEmpty ? _projects[0]['id'] : null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Görevi Düzenle' : 'Yeni Görev Ekle', style: const TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StyledTextField(controller: titleController, label: 'Başlık', icon: Icons.title_rounded),
                const SizedBox(height: 12),
                StyledTextField(controller: descController, label: 'Açıklama', icon: Icons.description_outlined),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: 'Durum',
                    prefixIcon: const Icon(Icons.info_outline_rounded),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: ['Pending', 'In Progress', 'Completed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => status = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedProjectId,
                  decoration: InputDecoration(
                    labelText: 'Proje',
                    prefixIcon: const Icon(Icons.folder_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _projects
                      .map((p) => DropdownMenuItem<int>(value: p['id'], child: Text(p['name'])))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selectedProjectId = val),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setStateDialog(() => selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Bitiş Tarihi',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEdit ? const Color(0xFF667eea) : const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (titleController.text.isEmpty || selectedProjectId == null) {
                  _showSnack('Başlık ve Proje gereklidir.', isError: true);
                  return;
                }
                if (isEdit) {
                  _updateTask(task.id, titleController.text.trim(), descController.text.trim(), status, selectedDate, selectedProjectId!);
                } else {
                  _createTask(titleController.text.trim(), descController.text.trim(), status, selectedDate, selectedProjectId!);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Görevlerim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toplam ${_tasks.length} görev bulunmaktadır',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        backgroundColor: const Color(0xFF2ECC71),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Yeni Görev',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Henüz görev bulunmuyor',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchTasks,
            child: const Text('Yenile'),
          )
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () => _toggleTaskStatus(task),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isDone ? const Color(0xFF2ECC71) : Colors.transparent,
              border: Border.all(
                color: task.isDone ? const Color(0xFF2ECC71) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: task.isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? Colors.grey : const Color(0xFF1A1A2E),
          ),
        ),
        subtitle: task.description.isNotEmpty
            ? Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
          onSelected: (val) {
            if (val == 'edit') {
              _showTaskDialog(task: task);
            } else if (val == 'delete') {
              _deleteTask(task.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_rounded, size: 18),
                SizedBox(width: 8),
                Text('Düzenle')
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Sil', style: TextStyle(color: Colors.red))
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
