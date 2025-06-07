import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReadingQuality {
  baik,
  cukup,
  perluPerbaikan,
}

class ProgressModel {
  final String id;
  final String studentId;
  final String surah;
  final String ayat;
  final ReadingQuality quality;
  final String? notes;
  final DateTime date;
  final String guruId;

  ProgressModel({
    required this.id,
    required this.studentId,
    required this.surah,
    required this.ayat,
    required this.quality,
    this.notes,
    required this.date,
    required this.guruId,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'surah': surah,
      'ayat': ayat,
      'quality': quality.toString().split('.').last,
      'notes': notes,
      'date': Timestamp.fromDate(date),
      'guruId': guruId,
    };
  }

  // Create from Firestore Map
  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      surah: map['surah'] ?? '',
      ayat: map['ayat'] ?? '',
      quality: _parseQuality(map['quality']),
      notes: map['notes'],
      date: _parseDateTime(map['date']),
      guruId: map['guruId'] ?? '',
    );
  }

  // Helper method to parse ReadingQuality from string
  static ReadingQuality _parseQuality(dynamic value) {
    if (value == null) return ReadingQuality.baik;
    
    String qualityString = value.toString();
    
    switch (qualityString) {
      case 'baik':
        return ReadingQuality.baik;
      case 'cukup':
        return ReadingQuality.cukup;
      case 'perluPerbaikan':
        return ReadingQuality.perluPerbaikan;
      default:
        return ReadingQuality.baik;
    }
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
  ProgressModel copyWith({
    String? id,
    String? studentId,
    String? surah,
    String? ayat,
    ReadingQuality? quality,
    String? notes,
    DateTime? date,
    String? guruId,
  }) {
    return ProgressModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      surah: surah ?? this.surah,
      ayat: ayat ?? this.ayat,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      guruId: guruId ?? this.guruId,
    );
  }

  // Get quality display text
  String get qualityText {
    switch (quality) {
      case ReadingQuality.baik:
        return 'Baik';
      case ReadingQuality.cukup:
        return 'Cukup';
      case ReadingQuality.perluPerbaikan:
        return 'Perlu Perbaikan';
    }
  }

  // Get quality color
  Color get qualityColor {
    switch (quality) {
      case ReadingQuality.baik:
        return Colors.green;
      case ReadingQuality.cukup:
        return Colors.orange;
      case ReadingQuality.perluPerbaikan:
        return Colors.red;
    }
  }

  @override
  String toString() {
    return 'ProgressModel(id: $id, studentId: $studentId, surah: $surah, ayat: $ayat, quality: $quality, date: $date, guruId: $guruId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ProgressModel &&
        other.id == id &&
        other.studentId == studentId &&
        other.surah == surah &&
        other.ayat == ayat &&
        other.quality == quality &&
        other.notes == notes &&
        other.date == date &&
        other.guruId == guruId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        studentId.hashCode ^
        surah.hashCode ^
        ayat.hashCode ^
        quality.hashCode ^
        notes.hashCode ^
        date.hashCode ^
        guruId.hashCode;
  }
}