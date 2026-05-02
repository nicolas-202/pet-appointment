import 'package:flutter/material.dart';
import 'package:pet_appointment/config/theme.dart';
import 'package:pet_appointment/services/appointment_service.dart';

/// Pantalla que lista los profesionales disponibles.
/// Al tocar uno navega a [CalendarScreen] pasando el ID por ruta.
class ProfessionalPickerScreen extends StatefulWidget {
  const ProfessionalPickerScreen({super.key});

  @override
  State<ProfessionalPickerScreen> createState() =>
      _ProfessionalPickerScreenState();
}

class _ProfessionalPickerScreenState extends State<ProfessionalPickerScreen> {
  final _service = AppointmentService();
  List<Map<String, String>> _professionals = [];
  bool _isLoading = true;
  String? _serviceId; // recibido desde ServicePickerScreen

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_serviceId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    _serviceId = args is String ? args : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.fetchProfessionals();
      setState(() => _professionals = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar profesionales: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Agendar Cita'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _professionals.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _professionals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pro = _professionals[index];
                  return _ProfessionalTile(
                    professional: pro,
                    onTap: () => Navigator.of(context).pushNamed(
                      '/calendar',
                      arguments: {
                        'professionalId': pro['id'],
                        'serviceId': _serviceId,
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin profesionales disponibles',
              style: TextStyle(
                fontFamily: AppFonts.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Por el momento no hay veterinarios registrados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget de cada profesional ────────────────────────────────────────────────

class _ProfessionalTile extends StatelessWidget {
  const _ProfessionalTile({
    required this.professional,
    required this.onTap,
  });

  final Map<String, String> professional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                (professional['full_name'] ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppFonts.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    professional['full_name'] ?? '',
                    style: const TextStyle(
                      fontFamily: AppFonts.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    professional['email'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
