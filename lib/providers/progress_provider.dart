import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress_model.dart';

class ProgressProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ProgressModel> _progresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProgressModel> get progresses => _progresses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadProgresses(String studentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      // Jangan panggil notifyListeners() di sini untuk menghindari konflik build

      final QuerySnapshot snapshot = await _firestore
          .collection('progresses')
          .where('studentId', isEqualTo: studentId)
          .get();
      
      _progresses = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ProgressModel.fromMap({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
      
      // Sort by date descending (newest first)
      _progresses.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('Progresses loaded for student $studentId: ${_progresses.length}');
    } catch (e) {
      debugPrint('Load progresses error: $e');
      _errorMessage = 'Gagal memuat progress';
      _progresses = [];
    } finally {
      _isLoading = false;
      // Panggil notifyListeners() hanya di akhir
      notifyListeners();
    }
  }

  Future<bool> addProgress(ProgressModel progress) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      // Jangan panggil notifyListeners() di sini

      final Map<String, dynamic> progressData = progress.toMap();
      progressData.remove('id');
      
      final docRef = await _firestore.collection('progresses').add(progressData);
      
      final newProgress = ProgressModel(
        id: docRef.id,
        studentId: progress.studentId,
        surah: progress.surah,
        ayat: progress.ayat,
        quality: progress.quality,
        notes: progress.notes,
        date: progress.date,
        guruId: progress.guruId,
      );
      
      _progresses.insert(0, newProgress);
      debugPrint('Progress added: ${newProgress.surah}');
      return true;
    } catch (e) {
      debugPrint('Add progress error: $e');
      _errorMessage = 'Gagal menambah progress';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProgress(ProgressModel progress) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      // Jangan panggil notifyListeners() di sini

      final Map<String, dynamic> progressData = progress.toMap();
      progressData.remove('id');
      
      await _firestore
          .collection('progresses')
          .doc(progress.id)
          .update(progressData);
      
      final index = _progresses.indexWhere((p) => p.id == progress.id);
      if (index != -1) {
        _progresses[index] = progress;
        debugPrint('Progress updated: ${progress.surah}');
      }
      return true;
    } catch (e) {
      debugPrint('Update progress error: $e');
      _errorMessage = 'Gagal update progress';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProgress(String progressId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      // Jangan panggil notifyListeners() di sini

      await _firestore.collection('progresses').doc(progressId).delete();
      
      _progresses.removeWhere((p) => p.id == progressId);
      debugPrint('Progress deleted: $progressId');
      return true;
    } catch (e) {
      debugPrint('Delete progress error: $e');
      _errorMessage = 'Gagal hapus progress';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all progresses for dashboard dengan email support
  Future<void> loadAllProgresses(String userId, String userRole, {String? userEmail}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      // Jangan panggil notifyListeners() di sini untuk menghindari konflik build

      Query query = _firestore.collection('progresses');
      
      if (userRole == 'guru') {
        query = query.where('guruId', isEqualTo: userId);
      } else {
        // For orangtua, load progresses of their children
        // First get student IDs berdasarkan email parent
        Query studentQuery = _firestore.collection('students');
        
        if (userEmail != null) {
          studentQuery = studentQuery.where('parentId', isEqualTo: userEmail);
        } else {
          studentQuery = studentQuery.where('parentId', isEqualTo: userId);
        }
        
        final studentSnapshot = await studentQuery.get();
        final studentIds = studentSnapshot.docs.map((doc) => doc.id).toList();
        
        if (studentIds.isNotEmpty) {
          query = query.where('studentId', whereIn: studentIds);
        } else {
          _progresses = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      final QuerySnapshot snapshot = await query
          .limit(50) // Limit for performance
          .get();
      
      _progresses = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ProgressModel.fromMap({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
      
      // Sort by date descending (newest first)
      _progresses.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('All progresses loaded: ${_progresses.length}');
    } catch (e) {
      debugPrint('Load all progresses error: $e');
      _errorMessage = 'Gagal memuat semua progress';
      _progresses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter methods
  List<ProgressModel> getProgressesByMonth(DateTime month) {
    return _progresses.where((p) => 
      p.date.year == month.year && p.date.month == month.month
    ).toList();
  }

  List<ProgressModel> getProgressesBySurah(String surah) {
    return _progresses.where((p) => 
      p.surah.toLowerCase().contains(surah.toLowerCase())
    ).toList();
  }

  List<ProgressModel> getProgressesByQuality(ReadingQuality quality) {
    return _progresses.where((p) => p.quality == quality).toList();
  }

  // Statistics methods
  int getTodayProgressCount() {
    final today = DateTime.now();
    return _progresses
        .where((p) => 
            p.date.year == today.year &&
            p.date.month == today.month &&
            p.date.day == today.day)
        .length;
  }

  int getThisWeekProgressCount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return _progresses
        .where((p) => 
            p.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            p.date.isBefore(weekEnd.add(const Duration(days: 1))))
        .length;
  }

  int getTotalProgressCount() {
    return _progresses.length;
  }

  int getStudentProgressCount(String studentId) {
    return _progresses.where((p) => p.studentId == studentId).length;
  }

  List<ProgressModel> getRecentProgresses({int limit = 5}) {
    final sortedProgresses = List<ProgressModel>.from(_progresses);
    sortedProgresses.sort((a, b) => b.date.compareTo(a.date));
    return sortedProgresses.take(limit).toList();
  }

  // Quality statistics
  Map<ReadingQuality, int> getQualityStatistics() {
    final stats = <ReadingQuality, int>{
      ReadingQuality.baik: 0,
      ReadingQuality.cukup: 0,
      ReadingQuality.perluPerbaikan: 0,
    };

    for (final progress in _progresses) {
      stats[progress.quality] = (stats[progress.quality] ?? 0) + 1;
    }

    return stats;
  }

  // Monthly statistics
  Map<String, int> getMonthlyStatistics() {
    final stats = <String, int>{};
    
    for (final progress in _progresses) {
      final monthKey = '${progress.date.year}-${progress.date.month.toString().padLeft(2, '0')}';
      stats[monthKey] = (stats[monthKey] ?? 0) + 1;
    }

    return stats;
  }

  void clearProgresses() {
    _progresses.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    debugPrint('Progresses cleared');
  }
}