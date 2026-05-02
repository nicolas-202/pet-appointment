import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:pet_appointment/screens/screens.dart';
import 'package:pet_appointment/widgets/app_shell.dart';
import 'package:pet_appointment/services/auth_service.dart';

/// Router configuration with authentication guards and role-based navigation.
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'otp-verification',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return OtpVerificationScreen(email: email);
            },
          ),
          // Deep link para reset de contraseña
          GoRoute(
            path: 'reset-password',
            builder: (context, state) => const ResetPasswordScreen(),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/pets',
            builder: (context, state) => const PetsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddPetScreen(),
              ),
              GoRoute(
                path: ':petId/detail',
                builder: (context, state) {
                  final petId = state.pathParameters['petId'];
                  return PetDetailScreen(
                    petId: petId ?? '',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );

  /// Handles redirects based on authentication and role.
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final authService = AuthService();
    final isLogged = authService.hasActiveSession;

    // Routes que no requieren autenticación
    final publicRoutes = [
      '/',
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
    ];

    // Si está en una ruta pública, permitir acceso
    if (publicRoutes.contains(state.matchedLocation)) {
      return null;
    }

    // Si no está autenticado y trata de acceder a ruta protegida, ir a login
    if (!isLogged) {
      return '/login';
    }

    // Redirigir al home después de login exitoso
    if (state.matchedLocation == '/login' && isLogged) {
      return '/home';
    }

    return null;
  }
}
