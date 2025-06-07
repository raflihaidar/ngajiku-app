import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<StudentModel> _students = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadStudents(String userId, String userRole) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('Loading students for user: $userId, role: $userRole');

      Query query = _firestore.collection('students');
      
      // Filter berdasarkan role
      if (userRole == 'orangtua') {
        query = query.where('parentId', isEqualTo: userId);
        debugPrint('Filtering by parentId: $userId');
      } else if (userRole == 'guru') {
        query = query.where('guruId', isEqualTo: userId);
        debugPrint('Filtering by guruId: $userId');
      }

      // Simple query without orderBy to avoid composite index
      final QuerySnapshot snapshot = await query.get();
      
      debugPrint('Query returned ${snapshot.docs.length} documents');
      
      _students = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            debugPrint('Processing doc ${doc.id}: $data');
            return StudentModel.fromMap({
              'id': doc.id,
              ...data,
            });
          })
          .toList();

      // Sort by createdAt descending (newest first)
      _students.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('Students loaded successfully: ${_students.length}');
      _students.forEach((student) {
        debugPrint('Student: ${student.name} (${student.id})');
      });
    } catch (e) {
      debugPrint('Load students error: $e');
      _errorMessage = 'Gagal memuat data siswa: $e';
      _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStudent(StudentModel student) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final Map<String, dynamic> studentData = student.toMap();
      studentData.remove('id'); // Remove ID for Firestore auto-generation
      
      debugPrint('Adding student with data: $studentData');
      
      final docRef = await _firestore.collection('students').add(studentData);
      
      final newStudent = StudentModel(
        id: docRef.id,
        name: student.name,
        parentId: student.parentId,
        guruId: student.guruId,
        createdAt: student.createdAt,
      );
      
      _students.insert(0, newStudent); // Add to beginning of list
      debugPrint('Student added successfully: ${newStudent.name} (ID: ${newStudent.id})');
      debugPrint('ParentId: ${newStudent.parentId}, GuruId: ${newStudent.guruId}');
      return true;
    } catch (e) {
      debugPrint('Add student error: $e');
      _errorMessage = 'Gagal menambahkan siswa: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStudent(StudentModel student) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final Map<String, dynamic> studentData = student.toMap();
      studentData.remove('id');
      
      await _firestore
          .collection('students')
          .doc(student.id)
          .update(studentData);
      
      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = student;
        debugPrint('Student updated: ${student.name}');
      }
      return true;
    } catch (e) {
      debugPrint('Update student error: $e');
      _errorMessage = 'Gagal update siswa';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Delete student
      await _firestore.collection('students').doc(studentId).delete();
      
      // Also delete all progresses for this student
      final progressQuery = await _firestore
          .collection('progresses')
          .where('studentId', isEqualTo: studentId)
          .get();
      
      for (final doc in progressQuery.docs) {
        await doc.reference.delete();
      }
      
      _students.removeWhere((s) => s.id == studentId);
      debugPrint('Student deleted: $studentId');
      return true;
    } catch (e) {
      debugPrint('Delete student error: $e');
      _errorMessage = 'Gagal hapus siswa';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  StudentModel? getStudentById(String studentId) {
    try {
      return _students.firstWhere((s) => s.id == studentId);
    } catch (e) {
      return null;
    }
  }

  List<StudentModel> searchStudents(String query) {
    if (query.isEmpty) return _students;
    
    return _students
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get students count for statistics
  int getStudentsCount() {
    return _students.length;
  }

  // Get recently added students
  List<StudentModel> getRecentStudents({int limit = 5}) {
    final sortedStudents = List<StudentModel>.from(_students);
    sortedStudents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedStudents.take(limit).toList();
  }

  void clearStudents() {
    _students.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    debugPrint('Students cleared');
  }
}