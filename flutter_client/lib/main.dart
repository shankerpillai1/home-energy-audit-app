import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for the current platform
  

  runApp(
    const ProviderScope(
      child: EnergyAuditApp(), // App root widget
    ),
  );
}
