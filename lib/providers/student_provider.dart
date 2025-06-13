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

  // Method untuk cek duplikasi siswa berdasarkan nama dan guru
  Future<bool> checkDuplicateStudent({
    required String studentName,
    required String guruId,
    String? excludeStudentId, // untuk update, exclude student yang sedang di-edit
  }) async {
    try {
      debugPrint('Checking duplicate for student: $studentName, guru: $guruId');
      
      Query query = _firestore
          .collection('students')
          .where('name', isEqualTo: studentName.trim())
          .where('guruId', isEqualTo: guruId);
      
      final QuerySnapshot snapshot = await query.get();
      
      // Jika ada excludeStudentId (untuk update), abaikan document tersebut
      if (excludeStudentId != null) {
        final duplicates = snapshot.docs.where((doc) => doc.id != excludeStudentId);
        bool isDuplicate = duplicates.isNotEmpty;
        debugPrint('Duplicate check result (excluding $excludeStudentId): $isDuplicate');
        return isDuplicate;
      }
      
      bool isDuplicate = snapshot.docs.isNotEmpty;
      debugPrint('Duplicate check result: $isDuplicate');
      return isDuplicate;
    } catch (e) {
      debugPrint('Error checking duplicate student: $e');
      return false; // Jika error, izinkan untuk safety
    }
  }

  // Method untuk cek duplikasi berdasarkan nama dan parent (untuk parent yang login)
  Future<bool> checkDuplicateStudentByParent({
    required String studentName,
    required String parentId,
    String? excludeStudentId,
  }) async {
    try {
      debugPrint('Checking duplicate for student: $studentName, parent: $parentId');
      
      Query query = _firestore
          .collection('students')
          .where('name', isEqualTo: studentName.trim())
          .where('parentId', isEqualTo: parentId);
      
      final QuerySnapshot snapshot = await query.get();
      
      if (excludeStudentId != null) {
        final duplicates = snapshot.docs.where((doc) => doc.id != excludeStudentId);
        bool isDuplicate = duplicates.isNotEmpty;
        debugPrint('Duplicate check result by parent (excluding $excludeStudentId): $isDuplicate');
        return isDuplicate;
      }
      
      bool isDuplicate = snapshot.docs.isNotEmpty;
      debugPrint('Duplicate check result by parent: $isDuplicate');
      return isDuplicate;
    } catch (e) {
      debugPrint('Error checking duplicate student by parent: $e');
      return false;
    }
  }

  // Method untuk validasi apakah email parent ada di koleksi users
  Future<bool> validateParentEmail(String parentEmail) async {
    try {
      debugPrint('Validating parent email: $parentEmail');
      
      // Cari user dengan email tersebut dan role orangtua
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: parentEmail)
          .where('role', isEqualTo: 'orangtua')
          .get();
      
      bool isValid = userQuery.docs.isNotEmpty;
      debugPrint('Parent email validation result: $isValid');
      
      return isValid;
    } catch (e) {
      debugPrint('Error validating parent email: $e');
      return false;
    }
  }

  // Method untuk mendapatkan data parent berdasarkan email
  Future<Map<String, dynamic>?> getParentByEmail(String parentEmail) async {
    try {
      debugPrint('Getting parent data for email: $parentEmail');
      
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: parentEmail)
          .where('role', isEqualTo: 'orangtua')
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final doc = userQuery.docs.first;
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting parent data: $e');
      return null;
    }
  }

  Future<void> loadStudents(String userId, String userRole, {String? userEmail}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      
      debugPrint('Loading students for user: $userId, role: $userRole, email: $userEmail');

      Query query = _firestore.collection('students');
      
      // Filter berdasarkan role
      if (userRole == 'orangtua') {
        // Untuk orang tua, filter berdasarkan parentId yang berisi email
        if (userEmail != null) {
          // Validasi email parent terlebih dahulu
          bool isValidParent = await validateParentEmail(userEmail);
          if (!isValidParent) {
            throw Exception('Email parent tidak valid atau tidak ditemukan');
          }
          
          query = query.where('parentId', isEqualTo: userEmail);
          debugPrint('Filtering by parentId (email): $userEmail');
        } else {
          throw Exception('Email parent tidak tersedia');
        }
      } else if (userRole == 'guru') {
        query = query.where('guruId', isEqualTo: userId);
        debugPrint('Filtering by guruId: $userId');
      }

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

  // Method khusus untuk load anak-anak berdasarkan email parent dengan validasi
  Future<void> loadChildrenByParentEmail(String parentEmail) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('Loading children for parent email: $parentEmail');

      // Validasi email parent terlebih dahulu
      bool isValidParent = await validateParentEmail(parentEmail);
      if (!isValidParent) {
        throw Exception('Email parent tidak valid atau tidak ditemukan dalam sistem');
      }

      // Query berdasarkan parentId yang berisi email
      final QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: parentEmail)
          .get();
      
      debugPrint('Found ${snapshot.docs.length} children for parent email: $parentEmail');
      
      _students = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            debugPrint('Processing child doc ${doc.id}: $data');
            return StudentModel.fromMap({
              'id': doc.id,
              ...data,
            });
          })
          .toList();

      // Sort by createdAt descending (newest first)
      _students.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('Children loaded successfully: ${_students.length}');
    } catch (e) {
      debugPrint('Load children error: $e');
      _errorMessage = 'Gagal memuat data anak: $e';
      _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Method untuk menambahkan siswa
  Future<bool> addStudent(StudentModel student) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Validasi email parent sebelum menambahkan student
      if (student.parentId.isNotEmpty) {
        bool isValidParent = await validateParentEmail(student.parentId);
        if (!isValidParent) {
          _errorMessage = 'Email parent tidak valid atau tidak ditemukan dalam sistem';
          return false;
        }
        debugPrint('Parent email validated successfully: ${student.parentId}');
      }

      // CEK DUPLIKASI SEBELUM MENAMBAHKAN
      bool isDuplicate = await checkDuplicateStudent(
        studentName: student.name,
        guruId: student.guruId,
      );

      if (isDuplicate) {
        _errorMessage = 'Siswa dengan nama "${student.name}" sudah terdaftar untuk guru ini';
        debugPrint('Duplicate student detected: ${student.name}');
        return false;
      }

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
      
      // SHOW NOTIFICATION WHEN STUDENT IS ADDED
      _showStudentAddedNotification(newStudent.name);
      
      return true;
    } catch (e) {
      debugPrint('Add student error: $e');
      _errorMessage = _errorMessage ?? 'Gagal menambahkan siswa: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Method untuk update siswa
  Future<bool> updateStudent(StudentModel student) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Validasi email parent sebelum update student
      if (student.parentId.isNotEmpty) {
        bool isValidParent = await validateParentEmail(student.parentId);
        if (!isValidParent) {
          _errorMessage = 'Email parent tidak valid atau tidak ditemukan dalam sistem';
          return false;
        }
        debugPrint('Parent email validated successfully for update: ${student.parentId}');
      }

      // CEK DUPLIKASI SEBELUM UPDATE (exclude student yang sedang di-edit)
      bool isDuplicate = await checkDuplicateStudent(
        studentName: student.name,
        guruId: student.guruId,
        excludeStudentId: student.id, // exclude student ini dari pengecekan
      );

      if (isDuplicate) {
        _errorMessage = 'Siswa dengan nama "${student.name}" sudah terdaftar untuk guru ini';
        debugPrint('Duplicate student detected on update: ${student.name}');
        return false;
      }

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
      
      // SHOW NOTIFICATION WHEN STUDENT IS UPDATED
      _showStudentUpdatedNotification(student.name);
      
      return true;
    } catch (e) {
      debugPrint('Update student error: $e');
      _errorMessage = _errorMessage ?? 'Gagal update siswa: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //method untuk hapus siswa
  Future<bool> deleteStudent(String studentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get student name before deletion for notification
      final studentToDelete = getStudentById(studentId);
      final studentName = studentToDelete?.name ?? 'Unknown';

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
      
      // SHOW NOTIFICATION WHEN STUDENT IS DELETED
      _showStudentDeletedNotification(studentName);
      
      return true;
    } catch (e) {
      debugPrint('Delete student error: $e');
      _errorMessage = 'Gagal hapus siswa: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NOTIFICATION METHODS
  void _showStudentAddedNotification(String studentName) {
    try {
      // Call notification helper if available
      _showNotification('Siswa Ditambahkan', 'Siswa $studentName berhasil ditambahkan');
    } catch (e) {
      debugPrint('Error showing student added notification: $e');
    }
  }

  void _showStudentUpdatedNotification(String studentName) {
    try {
      _showNotification('Siswa Diperbarui', 'Data siswa $studentName berhasil diperbarui');
    } catch (e) {
      debugPrint('Error showing student updated notification: $e');
    }
  }

  void _showStudentDeletedNotification(String studentName) {
    try {
      _showNotification('Siswa Dihapus', 'Siswa $studentName berhasil dihapus');
    } catch (e) {
      debugPrint('Error showing student deleted notification: $e');
    }
  }

  void _showNotification(String title, String message) {
    // This can be replaced with your notification service
    debugPrint('NOTIFICATION: $title - $message');
    
    // If you have NotificationHelper from the previous implementation:
    // NotificationHelper.showCustomNotification(title, message);
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

  // Search students with duplicate check
  List<StudentModel> searchStudentsWithDuplicateInfo(String query) {
    if (query.isEmpty) return _students;
    
    final results = _students
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    // Add duplicate info to debug
    for (var student in results) {
      final duplicates = _students
          .where((s) => s.name.toLowerCase() == student.name.toLowerCase() && s.id != student.id)
          .toList();
      
      if (duplicates.isNotEmpty) {
        debugPrint('Potential duplicate found for ${student.name}: ${duplicates.length} similar names');
      }
    }
    
    return results;
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

  // Method untuk mencari semua email parent yang terdaftar
  Future<List<String>> getAllParentEmails() async {
    try {
      debugPrint('Getting all parent emails');
      
      final QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'orangtua')
          .get();
      
      List<String> parentEmails = userQuery.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['email'] as String)
          .where((email) => email.isNotEmpty)
          .toList();
      
      debugPrint('Found ${parentEmails.length} parent emails');
      return parentEmails;
    } catch (e) {
      debugPrint('Error getting parent emails: $e');
      return [];
    }
  }

  // Method untuk mendapatkan statistik duplikasi
  Map<String, dynamic> getDuplicateStats() {
    final Map<String, List<StudentModel>> nameGroups = {};
    
    for (var student in _students) {
      final name = student.name.toLowerCase().trim();
      if (!nameGroups.containsKey(name)) {
        nameGroups[name] = [];
      }
      nameGroups[name]!.add(student);
    }
    
    final duplicateGroups = nameGroups.entries
        .where((entry) => entry.value.length > 1)
        .toList();
    
    return {
      'totalStudents': _students.length,
      'uniqueNames': nameGroups.length,
      'duplicateGroups': duplicateGroups.length,
      'duplicateStudents': duplicateGroups.fold<int>(0, (sum, group) => sum + group.value.length),
      'duplicateDetails': duplicateGroups.map((group) => {
        'name': group.key,
        'count': group.value.length,
        'students': group.value.map((s) => {'id': s.id, 'guru': s.guruId, 'parent': s.parentId}).toList(),
      }).toList(),
    };
  }
}