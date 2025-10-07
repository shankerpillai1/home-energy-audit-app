import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kvtlizvspugeepqbnquj.supabase.co',
    anonKey: 'sb_secret_QpPS89on8DuVNHb-1jLX0g_rSea_sA_',
  );

  runApp(
    const ProviderScope(
      child: EnergyAuditApp(), // App root widget
    ),
  );
}
