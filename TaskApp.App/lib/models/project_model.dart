class Project {
  final int id;
  final String name;
  final String description;
  final int userId;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse('${json['userId']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userId': userId,
    };
  }
}
