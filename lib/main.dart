import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:pet_appointment/config/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await _initializeSupabase();
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

Future<void> _initializeSupabase() async {
  final supabaseUrl = dotenv.maybeGet('SUPABASE_URL') ?? '';
  final supabaseAnonKey = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint(
      'Supabase no configurado: asegúrate de que .env contiene SUPABASE_URL y SUPABASE_ANON_KEY.',
    );
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Escuchar deep links entrantes
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Error en deep link: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link recibido: $uri');

    // Ejemplo: petappointment://reset-password?token=xxx&type=recovery
    if (uri.scheme == 'petappointment' && uri.path == '/reset-password') {
      AppRouter.router.go('/reset-password');
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PetAppointment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('es', 'ES'), Locale('en')],
      locale: const Locale('es', 'ES'),
      routerConfig: AppRouter.router,
    );
  }
}
