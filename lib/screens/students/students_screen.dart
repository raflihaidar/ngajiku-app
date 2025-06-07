import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../utils/app_theme.dart';
import '../progress/progress_screen.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<StudentModel> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    // Panggil setelah frame pertama selesai dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      final user = authProvider.user!;
      final userRole = user.role.toString().split('.').last;
      
      await studentProvider.loadStudents(
        user.id,
        userRole,
        userEmail: user.email,
      );
      
      // Update filtered list
      _updateFilteredStudents();
    }
  }

  void _updateFilteredStudents() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredStudents = studentProvider.students;
      } else {
        _filteredStudents = studentProvider.searchStudents(_searchController.text);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _updateFilteredStudents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : _buildTitle(),
        backgroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Consumer2<AuthProvider, StudentProvider>(
        builder: (context, authProvider, studentProvider, child) {
          if (studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Update filtered students ketika provider berubah
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateFilteredStudents();
          });

          if (studentProvider.students.isEmpty) {
            return _buildEmptyState(authProvider);
          }

          if (_filteredStudents.isEmpty && _searchController.text.isNotEmpty) {
            return _buildNoSearchResults();
          }

          return RefreshIndicator(
            onRefresh: _loadStudents,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredStudents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return _buildStudentCard(student, authProvider.user!);
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

  Widget _buildTitle() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Text(
          authProvider.user?.role == UserRole.guru 
              ? 'Daftar Siswa' 
              : 'Anak Saya',
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Cari nama siswa...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.black, fontSize: 16),
      onChanged: (value) {
        _updateFilteredStudents();
      },
    );
  }

  Widget _buildEmptyState(AuthProvider authProvider) {
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

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.greyText,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil ditemukan',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci yang berbeda',
            style: TextStyle(
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student, UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgressScreen(student: student),
            ),
          );
        },
        onLongPress: () => _showStudentOptions(student, user),
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
              
              // Menu button (only for teachers)
              if (user.role == UserRole.guru)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editStudent(student);
                    } else if (value == 'delete') {
                      _deleteStudent(student);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.greyText,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentOptions(StudentModel student, UserModel user) {
    // Only teachers can edit/delete
    if (user.role != UserRole.guru) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('Lihat Progress'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgressScreen(student: student),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.green),
              title: const Text('Edit Siswa'),
              onTap: () {
                Navigator.pop(context);
                _editStudent(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Siswa'),
              onTap: () {
                Navigator.pop(context);
                _deleteStudent(student);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editStudent(StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStudentScreen(student: student),
      ),
    ).then((_) => _loadStudents());
  }

  void _deleteStudent(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text(
          'Apakah Anda yakin ingin menghapus siswa "${student.name}"?\n\nSemua progress siswa ini juga akan dihapus.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final studentProvider = Provider.of<StudentProvider>(context, listen: false);
              final success = await studentProvider.deleteStudent(student.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Siswa berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadStudents();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(studentProvider.errorMessage ?? 'Gagal menghapus siswa'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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