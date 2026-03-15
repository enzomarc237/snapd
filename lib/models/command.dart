// Command model representing a user-defined shell command.
class Command {
  final String id;
  final String name;
  final String description;
  final String script;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Command({
    required this.id,
    required this.name,
    required this.description,
    required this.script,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Command copyWith({
    String? id,
    String? name,
    String? description,
    String? script,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Command(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      script: script ?? this.script,
      tags: tags ?? List.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'script': script,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Command.fromJson(Map<String, dynamic> json) => Command(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        script: json['script'] as String,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Command && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Command(id: $id, name: $name)';
}
