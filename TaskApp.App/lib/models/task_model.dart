import 'package:flutter/material.dart';

class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final DateTime? dueDate;
  final int projectId;
  final String category;
  final Color categoryColor;
  final String time;
  bool isDone;

  Task({
    this.id = 0,
    required this.title,
    this.description = '',
    this.status = 'Pending',
    this.dueDate,
    this.projectId = 0,
    this.category = 'Genel',
    this.categoryColor = const Color(0xFF667eea),
    this.time = '',
    this.isDone = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final dueDateStr = json['dueDate'];
    DateTime? dueDate;
    String time = '';
    if (dueDateStr != null) {
      dueDate = DateTime.parse(dueDateStr);
      time = '${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    }

    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Pending',
      dueDate: dueDate,
      projectId: json['projectId'] ?? 0,
      category: json['category'] ?? (json['status'] ?? 'Genel'),
      time: time,
      isDone: json['status'] == 'Completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': isDone ? 'Completed' : 'Pending',
      'dueDate': dueDate?.toIso8601String(),
      'projectId': projectId,
    };
  }
}
