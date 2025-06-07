import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String parentId;
  final String guruId;
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.parentId,
    required this.guruId,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'guruId': guruId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore Map
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentId: map['parentId'] ?? '',
      guruId: map['guruId'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is DateTime) {
      return value;
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    return DateTime.now();
  }

  // Copy with method for updates
  StudentModel copyWith({
    String? id,
    String? name,
    String? parentId,
    String? guruId,
    DateTime? createdAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      guruId: guruId ?? this.guruId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'StudentModel(id: $id, name: $name, parentId: $parentId, guruId: $guruId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is StudentModel &&
        other.id == id &&
        other.name == name &&
        other.parentId == parentId &&
        other.guruId == guruId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        parentId.hashCode ^
        guruId.hashCode ^
        createdAt.hashCode;
  }
}