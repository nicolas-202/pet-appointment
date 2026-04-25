import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/pet_service.dart';
import '../utils/field_validators.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key, this.initialPet});

  final Pet? initialPet;

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _petService = PetService();
  final _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;

  String _selectedSpecies = 'Perro';
  DateTime? _selectedBirthDate;
  Uint8List? _selectedPhotoBytes;
  String? _existingPhotoUrl;
  bool _removeExistingPhoto = false;
  bool _isLoading = false;

  bool get _isEditMode => widget.initialPet != null;

  @override
  void initState() {
    super.initState();

    final initialPet = widget.initialPet;
    _nameController = TextEditingController(text: initialPet?.name ?? '');
    _breedController = TextEditingController(text: initialPet?.breed ?? '');
    _weightController = TextEditingController(
      text: initialPet?.weight?.toString() ?? '',
    );
    _notesController = TextEditingController(text: initialPet?.notes ?? '');

    if (initialPet != null) {
      _selectedSpecies = initialPet.species;
      _selectedBirthDate = initialPet.birthDate;
      _existingPhotoUrl = initialPet.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedPhotoBytes = bytes;
          _removeExistingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error seleccionando foto: $e')));
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Localizations(
          locale: const Locale('es', 'ES'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de nacimiento')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final weight = _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null;

      final cleanBreed = _breedController.text.trim().isNotEmpty
          ? _breedController.text.trim()
          : null;
      final cleanNotes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      if (_isEditMode) {
        final updatedPet = await _petService.updatePet(
          petId: widget.initialPet!.id,
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: cleanBreed,
          birthDate: _selectedBirthDate!,
          weight: weight,
          notes: cleanNotes,
          photoBytes: _selectedPhotoBytes,
          removePhoto: _removeExistingPhoto,
        );

        if (updatedPet == null) {
          throw Exception('No fue posible actualizar la mascota');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Cambios guardados exitosamente!')),
          );
          Navigator.of(context).pop(updatedPet);
        }
      } else {
        await _petService.createPet(
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: cleanBreed,
          birthDate: _selectedBirthDate,
          weight: weight,
          notes: cleanNotes,
          photoBytes: _selectedPhotoBytes,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Mascota registrada exitosamente!')),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando mascota: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSpeciesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Especie *', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(label: Text('Perro'), value: 'Perro'),
            ButtonSegment(label: Text('Gato'), value: 'Gato'),
            ButtonSegment(label: Text('Otro'), value: 'Otro'),
          ],
          selected: {_selectedSpecies},
          onSelectionChanged: (selected) {
            setState(() {
              _selectedSpecies = selected.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPhotoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto (opcional)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        if (_selectedPhotoBytes != null)
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _selectedPhotoBytes!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPhotoBytes = null;
                      _removeExistingPhoto = true;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        else if (_existingPhotoUrl != null && !_removeExistingPhoto)
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _existingPhotoUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 120,
                    color: AppColors.surfaceContainerLow,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _removeExistingPhoto = true;
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Seleccionar foto'),
          ),
      ],
    );
  }

  Widget _buildBirthDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de nacimiento *',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectBirthDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 12),
                Text(
                  _selectedBirthDate != null
                      ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                      : 'Selecciona una fecha',
                  style: _selectedBirthDate != null
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.outline,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar mascota' : 'Agregar mascota'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Max, Luna, Pelusa',
                  prefixIcon: const Icon(Icons.pets),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: FieldValidators.petName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Especie
              _buildSpeciesSelector(),
              const SizedBox(height: 16),

              // Raza
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: 'Raza (opcional)',
                  hintText: 'Ej: Golden Retriever',
                  prefixIcon: const Icon(Icons.tag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: FieldValidators.petBreed,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Fecha de nacimiento
              _buildBirthDateSelector(),
              const SizedBox(height: 16),

              // Peso
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Peso en kg (opcional)',
                  hintText: '25.5',
                  prefixIcon: const Icon(Icons.scale),
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: FieldValidators.petWeight,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Notas
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notas / Condiciones médicas (opcional)',
                  hintText: 'Ej: Alérgico a....',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: FieldValidators.petNotes,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              // Foto
              _buildPhotoSelector(),
              const SizedBox(height: 24),

              // Botón guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _savePet,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditMode ? 'Guardar cambios' : 'Guardar mascota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
