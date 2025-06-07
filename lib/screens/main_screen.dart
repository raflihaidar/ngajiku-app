import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import 'home/home_screen.dart';
import 'students/students_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Cek apakah user adalah parent (orangtua)
    final bool isParent = user.role == UserRole.orangtua;
    
    // Daftar screen yang tersedia
    final List<Widget> allScreens = [
      const HomeScreen(),
      const StudentsScreen(),
      const ProfileScreen(),
    ];

    // Daftar navigation items yang tersedia
    final List<BottomNavigationBarItem> allNavItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Beranda',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        activeIcon: Icon(Icons.people),
        label: 'Siswa',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    // Filter screens dan navigation items berdasarkan role
    List<Widget> availableScreens = [];
    List<BottomNavigationBarItem> availableNavItems = [];
    List<int> screenIndexMapping = []; // Untuk mapping index asli

    for (int i = 0; i < allScreens.length; i++) {
      // Skip halaman siswa jika user adalah parent
      if (i == 1 && isParent) {
        continue;
      }
      
      availableScreens.add(allScreens[i]);
      availableNavItems.add(allNavItems[i]);
      screenIndexMapping.add(i);
    }

    // Pastikan currentIndex tidak melebihi jumlah screen yang tersedia
    if (_currentIndex >= availableScreens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: availableScreens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.greyText,
        items: availableNavItems,
      ),
    );
  }
}