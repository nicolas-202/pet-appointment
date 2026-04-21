import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/theme.dart';
import 'widgets/app_shell.dart';
import 'app/sprint2_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env.local');
  } catch (error) {
    debugPrint('No se pudo cargar .env.local: $error');
  }

  final isSupabaseReady = await initializeSupabase();
  runApp(
    isSupabaseReady
        ? MaterialApp(
            title: 'PetAppointment',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const AppShell(),
          )
        : const PetAppointmentApp(isSupabaseReady: false),
  );
}

Future<bool> initializeSupabase() async {
  final defineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  final defineSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final supabaseUrl = defineSupabaseUrl.isNotEmpty
      ? defineSupabaseUrl
      : dotenv.maybeGet('SUPABASE_URL') ?? '';
  final supabaseAnonKey = defineSupabaseAnonKey.isNotEmpty
      ? defineSupabaseAnonKey
      : dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint(
      'Supabase no configurado: define SUPABASE_URL y SUPABASE_ANON_KEY en .env.local o con --dart-define-from-file=.env.local.',
    );
    return false;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  return true;
}
