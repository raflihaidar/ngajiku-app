import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';

class EditStudentScreen extends StatefulWidget {
  final StudentModel student;

  const EditStudentScreen({
    super.key,
    required this.student,
  });

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  
  List<UserModel> _teachers = [];
  UserModel? _selectedTeacher;
  bool _isLoading = false;
  bool _isLoadingTeachers = true;

  @override
  void initState() {
    super.initState();
    // Populate form dengan data student yang akan diedit
    _nameController.text = widget.student.name;
    _parentEmailController.text = widget.student.parentId; // parentId berisi email
    _loadTeachers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'guru')
          .get();

      final teachers = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();

      setState(() {
        _teachers = teachers;
        // Set selected teacher berdasarkan guruId dari student
        _selectedTeacher = teachers.where((t) => t.id == widget.student.guruId).firstOrNull;
        _isLoadingTeachers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTeachers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data guru: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Edit Siswa'),
        backgroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateStudent,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoadingTeachers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.lightGreen,
                            child: Text(
                              widget.student.name.isNotEmpty 
                                  ? widget.student.name[0].toUpperCase() 
                                  : 'S',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Data Siswa',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Perbarui informasi siswa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Form Fields
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Field
                          const Text(
                            'Nama Siswa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama siswa',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama siswa harus diisi';
                              }
                              if (value.trim().length < 2) {
                                return 'Nama siswa minimal 2 karakter';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Parent Email Field
                          const Text(
                            'Email Orang Tua',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _parentEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'email@orangtua.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email orang tua harus diisi';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Teacher Selection
                          const Text(
                            'Guru Ngaji',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonFormField<UserModel>(
                              value: _selectedTeacher,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.school),
                              ),
                              hint: const Text('Pilih Guru Ngaji'),
                              items: _teachers.map((teacher) {
                                return DropdownMenuItem(
                                  value: teacher,
                                  child: Text(teacher.name),
                                );
                              }).toList(),
                              onChanged: (teacher) {
                                setState(() {
                                  _selectedTeacher = teacher;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Pilih guru ngaji';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Menyimpan...'),
                                ],
                              )
                            : const Text(
                                'Update Siswa',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      
      final updatedStudent = StudentModel(
        id: widget.student.id,
        name: _nameController.text.trim(),
        parentId: _parentEmailController.text.trim(), // parentId berisi email
        guruId: _selectedTeacher!.id,
        createdAt: widget.student.createdAt,
      );

      final success = await studentProvider.updateStudent(updatedStudent);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data siswa berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(studentProvider.errorMessage ?? 'Gagal mengupdate data siswa'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}