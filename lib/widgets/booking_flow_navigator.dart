import 'package:flutter/material.dart';
import 'package:pet_appointment/screens/calendar_screen.dart';

/// Tab de agendamiento — renderiza directamente CalendarScreen.
class BookingFlowNavigator extends StatelessWidget {
  const BookingFlowNavigator({super.key});

  @override
  Widget build(BuildContext context) => const CalendarScreen();
}
