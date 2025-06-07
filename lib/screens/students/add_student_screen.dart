import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentEmailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final student = StudentModel(
        id: '',
        name: _nameController.text.trim(),
        parentId: user.role == UserRole.orangtua ? user.id : _parentEmailController.text.trim(),
        guruId: user.role == UserRole.guru ? user.id : '', // Provide empty string instead of null
        createdAt: DateTime.now(),
      );

      final success = await studentProvider.addStudent(student);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Siswa berhasil ditambahkan'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final errorMessage = studentProvider.errorMessage ?? 'Gagal menambahkan siswa';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(user?.role == UserRole.guru ? 'Tambah Siswa' : 'Tambah Anak'),
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          user?.role == UserRole.guru ? Icons.school : Icons.family_restroom,
                          color: AppTheme.primaryGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user?.role == UserRole.guru ? 'Tambah Siswa Baru' : 'Tambah Anak',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.role == UserRole.guru 
                          ? 'Daftarkan siswa baru untuk mengikuti program ngaji'
                          : 'Daftarkan anak Anda untuk tracking progress ngaji',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Name Field
              CustomTextField(
                controller: _nameController,
                label: user?.role == UserRole.guru ? 'Nama Siswa' : 'Nama Anak',
                hint: 'Masukkan nama lengkap',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  if (value.trim().length < 2) {
                    return 'Nama terlalu pendek (minimal 2 karakter)';
                  }
                  if (value.trim().length > 50) {
                    return 'Nama terlalu panjang (maksimal 50 karakter)';
                  }
                  return null;
                },
              ),
              
              // Parent Email Field (only for Guru)
              if (user?.role == UserRole.guru) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _parentEmailController,
                  label: 'Email Orang Tua',
                  hint: 'Masukkan email orang tua siswa',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email orang tua tidak boleh kosong';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user?.role == UserRole.guru
                            ? 'Setelah siswa ditambahkan, Anda dapat mulai mencatat progress ngaji mereka.'
                            : 'Setelah anak ditambahkan, guru akan dapat mencatat progress ngaji anak Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              Consumer<StudentProvider>(
                builder: (context, studentProvider, child) {
                  return CustomButton(
                    onPressed: studentProvider.isLoading ? null : _saveStudent,
                    text: studentProvider.isLoading 
                        ? 'Menyimpan...' 
                        : (user?.role == UserRole.guru ? 'Tambah Siswa' : 'Tambah Anak'),
                    width: double.infinity,
                    isLoading: studentProvider.isLoading,
                  );
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}