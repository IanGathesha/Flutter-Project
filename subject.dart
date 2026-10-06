class Subject {
  final String id;
  final String name;
  final String createdAt;

  Subject({required this.id, required this.name, required this.createdAt});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt,
      };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: map['created_at'] as String,
      );
}
