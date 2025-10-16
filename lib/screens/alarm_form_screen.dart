import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';

class AlarmFormScreen extends ConsumerStatefulWidget {
  final Alarm? alarm;
  
  const AlarmFormScreen({super.key, this.alarm});

  @override
  ConsumerState<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends ConsumerState<AlarmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedCompartment = 1;
  List<String> _selectedDays = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _weekDays = [
    {'key': 'mon', 'name': 'Lun'},
    {'key': 'tue', 'name': 'Mar'},
    {'key': 'wed', 'name': 'Mié'},
    {'key': 'thu', 'name': 'Jue'},
    {'key': 'fri', 'name': 'Vie'},
    {'key': 'sat', 'name': 'Sáb'},
    {'key': 'sun', 'name': 'Dom'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _nameController.text = widget.alarm!.name;
      _selectedTime = TimeOfDay.fromDateTime(widget.alarm!.time);
      _selectedCompartment = widget.alarm!.compartment;
      _selectedDays = List.from(widget.alarm!.repeat);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF007AFF),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAlarm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final alarmDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final alarmManager = ref.read(alarmManagerProvider);

      if (widget.alarm == null) {
        // Crear nueva alarma
        final newAlarm = Alarm.create(
          name: _nameController.text.trim(),
          time: alarmDateTime,
          compartment: _selectedCompartment,
          repeat: _selectedDays,
        );
        await alarmManager.createAlarm(newAlarm);
      } else {
        // Actualizar alarma existente
        final updatedAlarm = widget.alarm!.copyWith(
          name: _nameController.text.trim(),
          time: alarmDateTime,
          compartment: _selectedCompartment,
          repeat: _selectedDays,
        );
        await alarmManager.updateAlarm(updatedAlarm);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.alarm == null 
                ? 'Alarma creada exitosamente'
                : 'Alarma actualizada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.alarm == null ? 'Nueva Alarma' : 'Editar Alarma',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAlarm,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hora
            _buildSection(
              title: 'Hora',
              child: GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.black54),
                      const SizedBox(width: 16),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.black26),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Nombre
            _buildSection(
              title: 'Nombre',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Tomar vitamina D',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    if (value.trim().length > 50) {
                      return 'El nombre es muy largo';
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Compartimento
            _buildSection(
              title: 'Compartimento',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        final compartment = index + 1;
                        final isSelected = _selectedCompartment == compartment;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCompartment = compartment);
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF007AFF) 
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF007AFF) 
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$compartment',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        final compartment = index + 5;
                        final isSelected = _selectedCompartment == compartment;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCompartment = compartment);
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF007AFF) 
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF007AFF) 
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$compartment',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Repetir
            _buildSection(
              title: 'Repetir',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _weekDays.map((day) {
                        final isSelected = _selectedDays.contains(day['key']);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDays.remove(day['key']);
                              } else {
                                _selectedDays.add(day['key']);
                              }
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF007AFF) 
                                  : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                day['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedDays.isEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Solo una vez',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        child,
      ],
    );
  }
}