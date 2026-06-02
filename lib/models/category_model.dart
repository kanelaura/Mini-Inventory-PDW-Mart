class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final DateTime modifiedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.modifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '📦',
      modifiedAt: DateTime.parse(map['modified_at'] as String),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? emoji,
    DateTime? modifiedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}
