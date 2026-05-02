import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_appointment/config/theme.dart';
import 'package:pet_appointment/models/availability_slot.dart';
import 'package:pet_appointment/models/service_model.dart';
import 'package:pet_appointment/services/appointment_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _service = AppointmentService();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _pets = [];
  List<ServiceModel> _services = [];
  String? _selectedPetId;
  String? _selectedServiceId;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<AvailabilitySlot>> _slotsByDay = {};
  Set<String> _bookedIds = {};
  AvailabilitySlot? _selectedSlot;

  bool _isLoading = false;
  bool _isSubmitting = false;

  RealtimeChannel? _appointmentsChannel;
  RealtimeChannel? _slotsChannel;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _appointmentsChannel?.unsubscribe();
    _slotsChannel?.unsubscribe();
    super.dispose();
  }

  // ─── Data ────────────────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.fetchUserPets(),
        _service.fetchServices(),
      ]);
      final pets = results[0] as List<Map<String, dynamic>>;
      final services = results[1] as List<ServiceModel>;
      if (mounted) {
        setState(() {
          _pets = pets;
          _services = services;
          if (pets.isNotEmpty) _selectedPetId = pets.first['id'] as String;
        });
        await _loadMonth(_focusedDay);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error al cargar datos: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMonth(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    try {
      final slots = await _service.fetchAllSlots(
        from: from,
        to: to,
        serviceId: _selectedServiceId,
      );
      final booked =
          await _service.fetchAllBookedSlotIds(from: from, to: to);
      final Map<DateTime, List<AvailabilitySlot>> grouped = {};
      for (final s in slots) {
        final key = DateTime(s.start.year, s.start.month, s.start.day);
        grouped.putIfAbsent(key, () => []).add(s);
      }
      if (mounted) setState(() { _slotsByDay = grouped; _bookedIds = booked; });
    } catch (e) {
      debugPrint('_loadMonth error: $e');
    }
  }

  Future<void> _refreshBookedIds() async {
    final month = _focusedDay;
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    try {
      final booked =
          await _service.fetchAllBookedSlotIds(from: from, to: to);
      if (mounted) {
        setState(() {
          _bookedIds = booked;
          if (_selectedSlot != null && booked.contains(_selectedSlot!.id)) {
            _selectedSlot = null;
          }
        });
      }
    } catch (e) {
      debugPrint('_refreshBookedIds error: $e');
    }
  }

  Future<void> _refreshSlots() async {
    final month = _focusedDay;
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    try {
      final slots = await _service.fetchAllSlots(
        from: from,
        to: to,
        serviceId: _selectedServiceId,
      );
      final Map<DateTime, List<AvailabilitySlot>> grouped = {};
      for (final s in slots) {
        final key = DateTime(s.start.year, s.start.month, s.start.day);
        grouped.putIfAbsent(key, () => []).add(s);
      }
      if (mounted) setState(() => _slotsByDay = grouped);
    } catch (e) {
      debugPrint('_refreshSlots error: $e');
    }
  }

  void _subscribeRealtime() {
    _appointmentsChannel = _service.subscribeToAllAppointments(
      onChanged: () => _refreshBookedIds(),
    );
    _slotsChannel = _service.subscribeToAllSlots(
      onChanged: () => _refreshSlots(),
    );
  }

  Future<void> _confirm() async {
    if (_selectedPetId == null) {
      _showSnack('Selecciona una mascota');
      return;
    }
    if (_selectedSlot == null) {
      _showSnack('Selecciona una hora disponible');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _service.createAppointment(
        petId: _selectedPetId!,
        professionalId: _selectedSlot!.professionalId,
        serviceId: _selectedServiceId ?? _selectedSlot!.serviceId,
        availabilityId: _selectedSlot!.id,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) {
        _showSnack('Cita agendada con exito!');
        setState(() {
          _selectedSlot = null;
          _selectedDay = null;
          _notesController.clear();
        });
      }
    } catch (e) {
      if (mounted) _showSnack('Error al agendar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  List<AvailabilitySlot> get _slotsForDay {
    if (_selectedDay == null) return [];
    final key = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    return (_slotsByDay[key] ?? []).where((s) => !s.isPast).toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _SliverSection(child: _buildHeading()),
            if (_pets.isNotEmpty) _SliverSection(child: _buildPetCard()),
            if (_services.isNotEmpty)
              _SliverSection(child: _buildServiceCard()),
            _SliverSection(child: _buildCalendarCard()),
            if (_selectedDay != null)
              _SliverSection(child: _buildTimeSlotsCard()),
            _SliverSection(child: _buildNotesCard()),
            _SliverSection(child: _buildConfirmBtn()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ─── Sections ─────────────────────────────────────────────────────────────

  Widget _buildHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nueva Cita',
            style: TextStyle(
              fontFamily: AppFonts.primary,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agenda una sesion de cuidado para tu companero.',
            style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Mascota'),
          const SizedBox(height: 10),
          _Dropdown(
            value: _selectedPetId,
            items: _pets.map((p) {
              final name = p['name'] as String? ?? '';
              final breed = p['breed'] as String? ?? '';
              final species = p['species'] as String? ?? '';
              final sub = breed.isNotEmpty ? breed : species;
              return DropdownMenuItem(
                value: p['id'] as String,
                child: Text('$name${sub.isNotEmpty ? " ($sub)" : ""}'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedPetId = v),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Tipo de Servicio'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _services.map((svc) {
                final sel = _selectedServiceId == svc.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Chip(
                    label: svc.name,
                    selected: sel,
                    onTap: () async {
                      setState(() {
                        _selectedServiceId = sel ? null : svc.id;
                        _selectedSlot = null;
                      });
                      await _loadMonth(_focusedDay);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return _Card(
      child: TableCalendar<AvailabilitySlot>(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _focusedDay,
        locale: 'es_ES',
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        onDaySelected: (sel, foc) {
          setState(() {
            _selectedDay = sel;
            _focusedDay = foc;
            _selectedSlot = null;
          });
        },
        onPageChanged: (foc) {
          _focusedDay = foc;
          _loadMonth(foc);
        },
        eventLoader: (day) {
          final key = DateTime(day.year, day.month, day.day);
          return (_slotsByDay[key] ?? [])
              .where((s) => !_bookedIds.contains(s.id) && !s.isPast)
              .toList();
        },
        calendarFormat: CalendarFormat.month,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontFamily: AppFonts.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.onSurface,
          ),
          leftChevronIcon: _ChevronBtn(icon: Icons.chevron_left),
          rightChevronIcon: _ChevronBtn(icon: Icons.chevron_right),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.outline,
            letterSpacing: 0.4,
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.outline,
            letterSpacing: 0.4,
          ),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
          markersMaxCount: 0,
          outsideDaysVisible: false,
        ),
        calendarBuilders: CalendarBuilders<AvailabilitySlot>(
          defaultBuilder: (ctx, day, _) {
            if (_slotsByDay.isEmpty) { return null; }
            if (day.year != _focusedDay.year ||
                day.month != _focusedDay.month) { return null; }
            final key = DateTime(day.year, day.month, day.day);
            final slots = _slotsByDay[key] ?? [];
            if (slots.isEmpty) { return null; }
            final hasFree =
                slots.any((s) => !_bookedIds.contains(s.id) && !s.isPast);
            return Container(
              margin: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasFree
                    ? AppColors.secondary.withValues(alpha: 0.15)
                    : AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      hasFree ? FontWeight.w700 : FontWeight.w400,
                  color:
                      hasFree ? AppColors.secondary : AppColors.outline,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeSlotsCard() {
    final slots = _slotsForDay;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Hora Disponible'),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            Text(
              'No hay horarios disponibles para este dia.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final booked = _bookedIds.contains(slot.id);
                final sel = _selectedSlot?.id == slot.id;
                return _TimeChip(
                  label: DateFormat('hh:mm a').format(slot.start),
                  sublabel: slot.professionalName,
                  selected: sel,
                  booked: booked,
                  onTap: booked
                      ? null
                      : () => setState(() => _selectedSlot = slot),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Notas adicionales'),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Sintomas, alergias o solicitudes especiales...',
              hintStyle: TextStyle(
                color: AppColors.outline.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBtn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Confirmar Cita',
                  style: TextStyle(
                    fontFamily: AppFonts.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SliverSection extends StatelessWidget {
  const _SliverSection({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: child);
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2F32).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.primary,
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?) onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded),
          style: TextStyle(fontSize: 15, color: AppColors.onSurface),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? const Color(0xFF005E3E)
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.booked,
    this.sublabel,
    this.onTap,
  });
  final String label;
  final String? sublabel;
  final bool selected;
  final bool booked;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color subFg;
    final BoxBorder? border;
    if (booked) {
      bg = Colors.transparent;
      fg = AppColors.outline.withValues(alpha: 0.35);
      subFg = AppColors.outline.withValues(alpha: 0.3);
      border = Border.all(color: AppColors.outline.withValues(alpha: 0.18));
    } else if (selected) {
      bg = AppColors.secondaryContainer;
      fg = const Color(0xFF005E3E);
      subFg = const Color(0xFF337A5A);
      border = null;
    } else {
      bg = Colors.transparent;
      fg = AppColors.onSurface;
      subFg = AppColors.onSurfaceVariant;
      border = Border.all(color: AppColors.outline.withValues(alpha: 0.28));
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: subFg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChevronBtn extends StatelessWidget {
  const _ChevronBtn({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
    );
  }
}
