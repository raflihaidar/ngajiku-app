import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../models/student_model.dart';
import '../../../models/progress_model.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

class AddProgressScreen extends StatefulWidget {
  final StudentModel student;

  const AddProgressScreen({super.key, required this.student});

  @override
  State<AddProgressScreen> createState() => _AddProgressScreenState();
}

class _AddProgressScreenState extends State<AddProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surahController = TextEditingController();
  final _ayatController = TextEditingController();
  final _notesController = TextEditingController();
  ReadingQuality _selectedQuality = ReadingQuality.baik;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _surahController.dispose();
    _ayatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProgress() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

      final progress = ProgressModel(
        id: '',
        studentId: widget.student.id,
        surah: _surahController.text.trim(),
        ayat: _ayatController.text.trim(),
        quality: _selectedQuality,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        date: _selectedDate,
        guruId: authProvider.user!.id,
      );

      final success = await progressProvider.addProgress(progress);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress berhasil disimpan'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan progress'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Tambah Progress'),
        backgroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryGreen,
                      child: Text(
                        widget.student.name.isNotEmpty 
                            ? widget.student.name[0].toUpperCase() 
                            : 'S',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.black,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Surah Field
              CustomTextField(
                controller: _surahController,
                label: 'Surah',
                hint: 'Contoh: Al-Baqarah',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Surah tidak boleh kosong';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Ayat Field
              CustomTextField(
                controller: _ayatController,
                label: 'Ayat',
                hint: 'Contoh: 1-10 atau 20',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ayat tidak boleh kosong';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quality Selection
              Text(
                'Kualitas Bacaan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 12),
              
              Column(
                children: ReadingQuality.values.map((quality) {
                  return RadioListTile<ReadingQuality>(
                    title: Text(quality.toString().split('.').last == 'baik' 
                        ? 'Baik' 
                        : quality.toString().split('.').last == 'cukup' 
                            ? 'Cukup' 
                            : 'Perlu Perbaikan'),
                    value: quality,
                    groupValue: _selectedQuality,
                    onChanged: (value) {
                      setState(() {
                        _selectedQuality = value!;
                      });
                    },
                    activeColor: AppTheme.primaryGreen,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Date Selection
              Text(
                'Tanggal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.greyText),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: AppTheme.greyText),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notes Field
              CustomTextField(
                controller: _notesController,
                label: 'Catatan (Opsional)',
                hint: 'Catatan tambahan tentang progress siswa',
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              CustomButton(
                onPressed: _saveProgress,
                text: 'Simpan Progress',
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}