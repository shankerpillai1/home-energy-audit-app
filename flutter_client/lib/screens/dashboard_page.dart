import 'package:flutter/material.dart';
import './main_login_page.dart';
import './jobs_page.dart';
import './input_page.dart';
class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  final List<String> pageTitles = [
    'Jobs', 'Templates', 'Input', 'Refine', 'Finance', 'Report', 'Model It', 'Settings', 'Support', 'Logout'
  ];

  final List<IconData> pageIcons = [
    Icons.work, Icons.view_module, Icons.input, Icons.build, Icons.attach_money, Icons.receipt, Icons.architecture, Icons.settings, Icons.support, Icons.exit_to_app
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Container(
            width: 64,
            color: const Color(0xFF1E1E1E),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: List.generate(7, (index) => _buildSidebarItem(index, pageIcons[index], pageTitles[index])),
                ),
                Column(
                  children: List.generate(3, (index) => _buildSidebarItem(index + 7, pageIcons[index + 7], pageTitles[index + 7])),
                )
              ],
            ),
          ),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (selectedIndex == 0) {
      return JobsPage(userName: widget.userName);
    }else if (selectedIndex == 2) {
      return InputPage(userName: widget.userName);


    }else if (selectedIndex == 9) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
      return const SizedBox.shrink();
    } else {
      return Center(
        child: Text(
          '${pageTitles[selectedIndex]} Page',
          style: const TextStyle(fontSize: 24),
        ),
      );
    }
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final bool isSelected = selectedIndex == index;
    final Color iconColor = (index == 9) ? Colors.red : Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        height: 72,
        width: double.infinity,
        color: isSelected ? Colors.blue : Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: iconColor, fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
