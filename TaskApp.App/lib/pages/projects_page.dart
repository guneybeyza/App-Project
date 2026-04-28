import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProjectsPage extends StatefulWidget {
  final int userId;
  const ProjectsPage({super.key, required this.userId});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<dynamic> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://localhost:7062/api/Project/user/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _projects = jsonDecode(response.body);
        });
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        setState(() {
          _projects = [];
        });
      } else {
        _showSnack('Projeler yüklenemedi: ${response.statusCode}', true);
      }
    } catch (e) {
      _showSnack('Projeleri çekerken hata: $e', true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProject(int projectId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: const Text(
            'Bu projeyi sildiğinizde içerisindeki tüm görevler de silinecektir. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('https://localhost:7062/api/Project/$projectId'),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        setState(() {
          _projects.removeAt(index);
        });
        _showSnack('Proje başarıyla silindi.');
      } else {
        _showSnack('Silme başarısız oldu.', true);
      }
    } catch (e) {
      _showSnack('Silme hatası: $e', true);
    }
  }

  void _showProjectDialog({Map<String, dynamic>? project, int? index}) {
    final nameController = TextEditingController(text: project?['name'] ?? '');
    final descController =
        TextEditingController(text: project?['description'] ?? '');
    final isEdit = project != null;

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Projeyi Düzenle' : 'Yeni Proje',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Proje Adı',
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
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Açıklama',
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
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            _showSnack('Proje adı boş olamaz.', true);
                            return;
                          }
                          setDialogState(() => isSaving = true);

                          try {
                            if (isEdit) {
                              // UPDATE
                              final response = await http.put(
                                Uri.parse(
                                    'https://localhost:7062/api/Project/${project['id']}'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'name': name,
                                  'description': descController.text.trim(),
                                  'userId': widget.userId,
                                }),
                              );
                              if (response.statusCode == 200) {
                                final updatedProject =
                                    jsonDecode(response.body)['project'] ??
                                        jsonDecode(response.body);
                                setState(() {
                                  _projects[index!] = updatedProject;
                                });
                                if (context.mounted) Navigator.pop(context);
                                _showSnack('Proje güncellendi.');
                              } else {
                                _showSnack('Güncelleme hatası!', true);
                              }
                            } else {
                              // CREATE
                              final response = await http.post(
                                Uri.parse('https://localhost:7062/api/Project'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'name': name,
                                  'description': descController.text.trim(),
                                  'userId': widget.userId,
                                }),
                              );
                              if (response.statusCode == 201 ||
                                  response.statusCode == 200) {
                                final newProject = jsonDecode(response.body);
                                setState(() {
                                  _projects.add(newProject);
                                });
                                if (context.mounted) Navigator.pop(context);
                                _showSnack('Proje oluşturuldu. 🎉');
                              } else {
                                _showSnack('Oluşturma hatası!', true);
                              }
                            }
                          } catch (e) {
                            _showSnack('Bağlantı hatası: $e', true);
                          } finally {
                            if (context.mounted)
                              setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Parent background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Projeleriniz',
            style: TextStyle(
                color: Color(0xFF1A1A2E), fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Henüz bir projeniz yok.',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.folder_special_rounded,
                              color: Color(0xFF667eea)),
                        ),
                        title: Text(project['name'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            project['description']?.isEmpty ?? true
                                ? 'Açıklama yok'
                                : project['description'],
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: Colors.grey.shade400),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showProjectDialog(
                                  project: project, index: index);
                            } else if (val == 'delete') {
                              _deleteProject(project['id'], index);
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
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_rounded,
                                    size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text('Sil',
                                    style: TextStyle(color: Colors.red))
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProjectDialog(),
        backgroundColor: const Color(0xFF667eea),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Yeni Proje',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
