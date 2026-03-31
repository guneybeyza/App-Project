import 'package:flutter/material.dart';

class Task {
  final String title;
  final String category;
  final Color categoryColor;
  final String time;
  bool isDone;

  Task({
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.time,
    this.isDone = false,
  });
}
