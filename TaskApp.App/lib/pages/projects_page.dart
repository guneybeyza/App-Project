import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taskapp_app/models/project_model.dart';

const String _apiBaseUrl = 'http://localhost:5062';

class ProjectsPage extends StatefulWidget {
  final int userId;
  final String userName;

  const ProjectsPage({super.key, required this.userId, required this.userName});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/Project/user/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        _projects = data
            .map((item) => Project.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = 'Projeler yüklenirken hata oluştu.';
      }
    } catch (e) {
      _errorMessage = 'Projeler yüklenirken hata oluştu: $e';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showAddProjectDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yeni Proje',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Proje adı...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: 'Açıklama (isteğe bağlı)...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              _createProject(name, descriptionController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _createProject(String name, String description) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/Project'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'userId': widget.userId,
        }),
      );

      if (response.statusCode == 201) {
        _showSnack('Proje oluşturuldu.');
        _loadProjects();
      } else {
        final body = jsonDecode(response.body);
        final message = body['message'] ?? 'Proje oluşturulamadı.';
        _showSnack(message, isError: true);
      }
    } catch (e) {
      _showSnack('Proje oluşturulurken hata oluştu: $e', isError: true);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor:
          isError ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Projeler - ${widget.userName}'),
        backgroundColor: const Color(0xFF667eea),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _showAddProjectDialog,
        backgroundColor: const Color(0xFF667eea),
        icon: const Icon(Icons.add),
        label: const Text('Proje Ekle'),
      ),
      body: Container(
        color: const Color(0xFFF4F6FB),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Color(0xFFE74C3C), fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _projects.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz proje yok. Sağ alt düğmeden yeni bir proje ekleyin.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _projects.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                title: Text(project.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(project.description.isEmpty
                                    ? 'Açıklama yok'
                                    : project.description),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
