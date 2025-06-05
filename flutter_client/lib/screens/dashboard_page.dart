
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_client/screens/home_page.dart';
import 'package:flutter_client/screens/job_page.dart';
import 'package:flutter_client/screens/profile_page.dart';
import 'package:flutter_client/screens/login_page.dart';
import 'package:flutter_client/screens/create_job_page.dart';
import 'package:flutter_client/screens/create_job_wizard_page.dart';
import 'package:flutter_client/screens/report_page.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String currentRoute = '/dashboard/home';
  String activeButton = '/dashboard/home';
  bool showSettingsMenu = false;

  // Method to navigate to a different page
  void _navigate(String route) {
    setState(() {
      currentRoute = route;
      activeButton = route;
      showSettingsMenu = false;
    });
  }

  void _toggleSettingsMenu() {
    setState(() {
      showSettingsMenu = !showSettingsMenu;
      activeButton = 'settings';
    });
  }

  // Handle user logout and clear saved credentials
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userName');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // Returns the correct widget based on currentRoute
  Widget _getPage() {
    switch (currentRoute) {
      case '/dashboard/refine':
        return RefinePage(userName: widget.userName, jobName: '', createdTime: '', status: '', selectedIdleDevices: {},);
      case '/dashboard/profile':
        return ProfilePage(userName: widget.userName, showLogout: true);
      case '/dashboard/report':
        return ReportPage(jobName: '', userName: '', createdTime: '', status: '',);
      case '/dashboard/create':
        return CreateJobWizardPage(
          onBack: () => _navigate('/dashboard/refine'), 
          
        );
      case '/dashboard/home':
      default:
        return HomePage(
          userName: widget.userName,
          onNavigate: _navigate, 
        );
    }
  }

  // Determine if the platform is mobile
  bool get isMobile {
    final width = MediaQuery.of(context).size.width;
    final platform = defaultTargetPlatform;
    return width < 600 || platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Scaffold(
              body: isMobile
                  ? Column(
                      children: [
                        Expanded(child: _getPage()),
                        BottomNavigationBar(
                          currentIndex: _getMobileIndex(),
                          onTap: _onMobileTap,
                          items: const [
                            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                            BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Refine'),
                            BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
                            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 64,
                          color: const Color(0xFF1E1E1E),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  _buildSidebarIcon(Icons.home, '/dashboard/home', 'Home'),
                                  _buildSidebarIcon(Icons.task, '/dashboard/refine', 'Refine'),
                                  _buildSidebarIcon(Icons.book,'/dashboard/report', 'Report'),
                                ],
                              ),
                              Column(
                                children: [
                                  _buildSettingsIcon(Icons.settings, 'Settings'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _getPage()),
                      ],
                    ),
            ),
            if (!isMobile && showSettingsMenu)
              Positioned(
                left: 64,
                bottom: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 140,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2C2C),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _navigate('/dashboard/profile');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
                            child: Text('Profile', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const Divider(color: Colors.grey, height: 1),
                        GestureDetector(
                          onTap: _logout,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
                            child: Text('Logout', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  int _getMobileIndex() {
    switch (activeButton) {
      case '/dashboard/home':
        return 0;
      case '/dashboard/history':
        return 1;
      case '/dashboard/profile':
        return 2;
      default:
        return 0;
    }
  }

  void _onMobileTap(int index) {
    switch (index) {
      case 0:
        _navigate('/dashboard/home');
        break;
      case 1:
        _navigate('/dashboard/history');
        break;
      case 2:
        _navigate('/dashboard/profile');
        break;
    }
  }

  // Sidebar button builder
  Widget _buildSidebarIcon(IconData icon, String route, String label) {
    final bool isActive = activeButton == route;
    return GestureDetector(
      onTap: () => _navigate(route),
      child: Container(
        height: 72,
        width: 64,
        color: isActive ? Colors.blue : Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // Settings button builder
  Widget _buildSettingsIcon(IconData icon, String label) {
    final bool isActive = activeButton == 'settings';
    return GestureDetector(
      onTap: _toggleSettingsMenu,
      child: Container(
        height: 72,
        width: 64,
        color: isActive ? Colors.blue : Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}