import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_info_screen.dart';

void main() {
  runApp(HomeAuditApp());
}

class HomeAuditApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Energy Audit',
      theme: ThemeData.dark(), 
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      
      routes: {
        '/': (context) => WelcomeScreen(),
        '/home_info': (context) => HomeInfoScreen(),
      },
    );
  }
}
