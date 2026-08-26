class MaterialFolderModel {
  const MaterialFolderModel({
    this.id,
    required this.name,
    this.itemCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MaterialFolderModel.fromJson(Map<String, dynamic> json) {
    return MaterialFolderModel(
      id: _readOptionalInteger(json['id']),
      name: _readString(json['name']),
      itemCount: _readInteger(json['item_count']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'item_count': itemCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseJson() {
    return <String, dynamic>{
      'name': name.trim(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MaterialFolderModel copyWith({
    int? id,
    String? name,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialFolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _readString(dynamic value) {
    return value is String ? value.trim() : '';
  }

  static int _readInteger(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readOptionalInteger(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is String) {
      final DateTime? parsedValue = DateTime.tryParse(value);

      if (parsedValue != null) {
        return parsedValue;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
