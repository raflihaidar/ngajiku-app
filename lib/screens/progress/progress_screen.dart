import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../models/student_model.dart';
import '../../models/progress_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/progress_item_card.dart';
import 'add_progress_screen.dart';
import 'edit_progress_screen.dart';

class ProgressScreen extends StatefulWidget {
  final StudentModel student;

  const ProgressScreen({super.key, required this.student});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Panggil setelah frame pertama selesai dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    await progressProvider.loadProgresses(widget.student.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Catatan Progress'),
        backgroundColor: AppTheme.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.greyText,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'Progress'),
            Tab(text: 'Keterangan'),
            Tab(text: 'Tanggal'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Student Info Header
          Container(
            width: double.infinity,
            color: AppTheme.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.lightGreen,
                  child: Text(
                    widget.student.name.isNotEmpty 
                        ? widget.student.name[0].toUpperCase() 
                        : 'S',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                      Text(
                        'Progress Terakhir - ${DateFormat('dd MMMM yyyy', 'id').format(DateTime.now())}',
                        style: const TextStyle(
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
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProgressTab(),
                _buildKeteranganTab(),
                _buildTanggalTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.user?.role == UserRole.guru) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProgressScreen(student: widget.student),
                  ),
                ).then((_) => _loadProgress());
              },
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.add, color: AppTheme.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProgressTab() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        if (progressProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final progresses = progressProvider.progresses;
        
        if (progresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: AppTheme.greyText,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada progress yang dicatat',
                  style: TextStyle(
                    color: AppTheme.greyText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.user?.role == UserRole.guru) {
                      return Text(
                        'Tap tombol + untuk menambah progress',
                        style: TextStyle(
                          color: AppTheme.greyText,
                          fontSize: 14,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadProgress,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: progresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final progress = progresses[index];
              return _buildProgressItemWithActions(progress);
            },
          ),
        );
      },
    );
  }

  Widget _buildProgressItemWithActions(ProgressModel progress) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isTeacher = authProvider.user?.role == UserRole.guru;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: isTeacher ? () => _showProgressOptions(progress) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'QS ${progress.surah} | ${progress.ayat}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isTeacher)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editProgress(progress);
                            } else if (value == 'delete') {
                              _deleteProgress(progress);
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
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: progress.qualityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          progress.qualityText,
                          style: TextStyle(
                            color: progress.qualityColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM yyyy', 'id').format(progress.date),
                        style: TextStyle(
                          color: AppTheme.greyText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (progress.notes != null && progress.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        progress.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProgressOptions(ProgressModel progress) {
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
              'QS ${progress.surah} | ${progress.ayat}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Progress'),
              onTap: () {
                Navigator.pop(context);
                _editProgress(progress);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Progress'),
              onTap: () {
                Navigator.pop(context);
                _deleteProgress(progress);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProgress(ProgressModel progress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProgressScreen(
          student: widget.student,
          progress: progress,
        ),
      ),
    ).then((_) => _loadProgress());
  }

  void _deleteProgress(ProgressModel progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Progress'),
        content: Text(
          'Apakah Anda yakin ingin menghapus progress QS ${progress.surah} | ${progress.ayat}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
              final success = await progressProvider.deleteProgress(progress.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progress berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(progressProvider.errorMessage ?? 'Gagal menghapus progress'),
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

  Widget _buildKeteranganTab() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final progresses = progressProvider.progresses
            .where((p) => p.notes != null && p.notes!.isNotEmpty)
            .toList();

        if (progresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 64,
                  color: AppTheme.greyText,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada keterangan khusus',
                  style: TextStyle(
                    color: AppTheme.greyText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keterangan akan muncul saat guru menambahkan catatan khusus',
                  style: TextStyle(
                    color: AppTheme.greyText,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: progresses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final progress = progresses[index];
            return Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isTeacher = authProvider.user?.role == UserRole.guru;
                
                return Card(
                  child: InkWell(
                    onTap: isTeacher ? () => _showProgressOptions(progress) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'QS ${progress.surah} | ${progress.ayat}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: progress.qualityColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      progress.qualityText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: progress.qualityColor,
                                      ),
                                    ),
                                  ),
                                  if (isTeacher) ...[
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editProgress(progress);
                                        } else if (value == 'delete') {
                                          _deleteProgress(progress);
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
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMMM yyyy', 'id').format(progress.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              progress.notes!,
                              style: const TextStyle(
                                color: AppTheme.black,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTanggalTab() {
    return Column(
      children: [
        // Month Selector
        Container(
          color: AppTheme.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'id').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.black,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Bulan sebelumnya',
                  ),
                  IconButton(
                    onPressed: () {
                      final now = DateTime.now();
                      if (_selectedMonth.isBefore(DateTime(now.year, now.month))) {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Bulan selanjutnya',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Progress Count Summary
        Container(
          color: AppTheme.white,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Consumer<ProgressProvider>(
            builder: (context, progressProvider, child) {
              final monthProgresses = progressProvider.getProgressesByMonth(_selectedMonth);
              final totalDays = monthProgresses.length;
              final goodQuality = monthProgresses.where((p) => p.quality == ReadingQuality.baik).length;
              
              return Row(
                children: [
                  Expanded(
                    child: _buildMonthStat('Total Hari', totalDays.toString(), Icons.calendar_today, AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMonthStat('Bacaan Baik', goodQuality.toString(), Icons.star, Colors.orange),
                  ),
                ],
              );
            },
          ),
        ),
        
        // Progress by Month
        Expanded(
          child: Consumer<ProgressProvider>(
            builder: (context, progressProvider, child) {
              final monthProgresses = progressProvider.getProgressesByMonth(_selectedMonth);
              
              if (monthProgresses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: AppTheme.greyText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada progress di bulan ini',
                        style: TextStyle(
                          color: AppTheme.greyText,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gunakan panah untuk berpindah bulan',
                        style: TextStyle(
                          color: AppTheme.greyText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: monthProgresses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final progress = monthProgresses[index];
                  return _buildProgressItemWithActions(progress);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}