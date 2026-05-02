import 'package:flutter/material.dart';
import 'package:pet_appointment/config/config.dart';
import 'package:pet_appointment/screens/screens.dart';
import 'package:pet_appointment/services/auth_service.dart';
import 'package:pet_appointment/widgets/booking_flow_navigator.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.child});

  final Widget? child;

  static void selectTab(BuildContext context, int index) {
    final shellState = context.findAncestorStateOfType<_AppShellState>();
    shellState?._onTabSelected(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // IndexedStack mantiene vivos todos los tabs — el estado no se pierde
  // al cambiar de pestaña (ej. el stack de navegación de Citas se preserva).
  static const List<Widget> _screens = [
    HomeScreen(),
    PetsScreen(),
    BookingFlowNavigator(), // flujo Servicio → Profesional → Calendario
    ProfileScreen(),
  ];

  // Tabs que requieren sesión activa
  static const _protectedTabs = {1, 2, 3};

  void _onTabSelected(int index) {
    if (_protectedTabs.contains(index) && !AuthService().hasActiveSession) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Si recibe un child de Go Router, usarlo; de lo contrario, mostrar la pantalla del índice
    final body = widget.child ?? _screens[_currentIndex];

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        indicatorColor: AppColors.primaryContainer,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Mascotas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
