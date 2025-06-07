import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/progress_provider.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../utils/app_theme.dart';
import '../progress/progress_screen.dart';
// Import StudentsScreen dengan alias untuk menghindari konflik
import '../students/students_screen.dart' as StudentsScreenPage;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _todayProgressCount = 0; // Simpan count lokal untuk mencegah perubahan

  @override
  void initState() {
    super.initState();
    // Panggil setelah frame pertama selesai dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void didPopNext() {
    // Dipanggil ketika kembali ke halaman ini dari halaman lain
    super.didPopNext();
    _refreshTodayProgressCount();
  }

  void _refreshTodayProgressCount() {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      final user = authProvider.user!;
      final userRole = user.role.toString().split('.').last;
      
      // Reload progress data untuk mendapatkan count yang akurat
      progressProvider.loadAllProgresses(user.id, userRole, userEmail: user.email).then((_) {
        if (mounted) {
          setState(() {
            _todayProgressCount = progressProvider.getTodayProgressCount();
          });
        }
      });
    }
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      final user = authProvider.user!;
      final userRole = user.role.toString().split('.').last;
      
      // Load students - untuk parent kirim email karena parentId di Firestore berisi email
      await studentProvider.loadStudents(
        user.id,
        userRole,
        userEmail: user.email,
      );
      
      // Load progress untuk menghitung progress hari ini
      await progressProvider.loadAllProgresses(user.id, userRole, userEmail: user.email);
      
      // Simpan count progress hari ini ke state lokal
      setState(() {
        _todayProgressCount = progressProvider.getTodayProgressCount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Ngajiku'),
        backgroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: Consumer3<AuthProvider, StudentProvider, ProgressProvider>(
        builder: (context, authProvider, studentProvider, progressProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadInitialData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  _buildWelcomeCard(user),
                  
                  const SizedBox(height: 24),
                  
                  // Statistics Cards
                  _buildStatisticsRow(user, studentProvider, progressProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Section Title
                  _buildSectionTitle(user),
                  
                  const SizedBox(height: 12),
                  
                  // Error Message
                  if (studentProvider.errorMessage != null)
                    _buildErrorMessage(studentProvider.errorMessage!),
                  
                  // Students/Children List
                  _buildStudentsList(user, studentProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat ${_getGreeting()}',
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.name,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.role == UserRole.guru ? 'Guru Ngaji' : 'Orang Tua',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(UserModel user, StudentProvider studentProvider, ProgressProvider progressProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            user.role == UserRole.guru ? 'Jumlah Siswa' : 'Jumlah Anak',
            studentProvider.students.length.toString(),
            user.role == UserRole.guru ? Icons.people : Icons.child_care,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Progress Hari Ini',
            _todayProgressCount.toString(), // Gunakan state lokal
            Icons.calendar_today,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: Text(
            user.role == UserRole.guru 
                ? 'Daftar Siswa' 
                : 'Daftar Anak',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
          ),
        ),
        // Hanya tampilkan tombol "Lihat Semua" untuk guru
        if (user.role == UserRole.guru)
          TextButton(
            onPressed: () {
              // Navigate ke halaman daftar siswa menggunakan alias
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentsScreenPage.StudentsScreen(),
                ),
              );
            },
            child: const Text('Lihat Semua'),
          ),
      ],
    );
  }

  Widget _buildErrorMessage(String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(UserModel user, StudentProvider studentProvider) {
    if (studentProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (studentProvider.students.isEmpty) {
      return _buildEmptyState(user);
    }

    // Untuk guru, limit hanya 3 siswa
    // Untuk parent, tampilkan semua anak
    final studentsToShow = user.role == UserRole.guru 
        ? studentProvider.students.take(3).toList()
        : studentProvider.students;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: studentsToShow.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = studentsToShow.elementAt(index);
        return _buildStudentCard(student, user);
      },
    );
  }

  Widget _buildEmptyState(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            user.role == UserRole.guru ? Icons.people_outline : Icons.child_care_outlined,
            size: 64,
            color: AppTheme.greyText,
          ),
          const SizedBox(height: 16),
          Text(
            user.role == UserRole.guru
                ? 'Belum ada siswa yang terdaftar'
                : 'Belum ada anak yang terdaftar',
            style: TextStyle(
              color: AppTheme.greyText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            user.role == UserRole.guru
                ? 'Tambahkan siswa untuk mulai mencatat progress'
                : 'Hubungi guru ngaji untuk mendaftarkan anak Anda',
            style: TextStyle(
              color: AppTheme.greyText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student, UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProgressScreen(student: student),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.role == UserRole.guru ? 'Siswa' : 'Anak Anda',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bergabung: ${_formatDate(student.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.greyText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  int _getTodayProgressCount(ProgressProvider progressProvider) {
    // Jika data progress kosong, return 0
    if (progressProvider.progresses.isEmpty) {
      return 0;
    }
    
    // Menghitung progress yang dibuat hari ini berdasarkan tanggal saat ini
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    int count = 0;
    for (final progress in progressProvider.progresses) {
      // Cek apakah progress dibuat hari ini
      if (progress.date.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
          progress.date.isBefore(todayEnd)) {
        count++;
      }
    }
    
    return count;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}