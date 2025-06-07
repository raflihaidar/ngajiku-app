import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/progress_card.dart';
import '../progress/progress_screen.dart';
import 'add_student_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await studentProvider.loadStudents(
        authProvider.user!.id,
        authProvider.user!.role.toString().split('.').last,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Text(
              authProvider.user?.role == UserRole.guru 
                  ? 'Daftar Siswa' 
                  : 'Anak Saya',
            );
          },
        ),
        backgroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, StudentProvider>(
        builder: (context, authProvider, studentProvider, child) {
          if (studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentProvider.students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: AppTheme.greyText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.user?.role == UserRole.guru
                        ? 'Belum ada siswa terdaftar'
                        : 'Belum ada anak terdaftar',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.greyText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.user?.role == UserRole.guru
                        ? 'Tambahkan siswa untuk mulai mencatat progress'
                        : 'Tambahkan data anak untuk melihat progress ngaji',
                    style: TextStyle(
                      color: AppTheme.greyText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddStudentScreen(),
                        ),
                      ).then((_) => _loadStudents());
                    },
                    icon: const Icon(Icons.add),
                    label: Text(authProvider.user?.role == UserRole.guru
                        ? 'Tambah Siswa'
                        : 'Tambah Anak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadStudents,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: studentProvider.students.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = studentProvider.students[index];
                return StudentCard(
                  student: student,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgressScreen(student: student),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddStudentScreen(),
            ),
          ).then((_) => _loadStudents());
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
    );
  }
}