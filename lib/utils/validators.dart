class Validators {
  static String? validateAlarmName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }
    return null;
  }
  
  static bool isValidCompartment(int compartment) {
    return compartment >= 1 && compartment <= 8;
  }
  
  static bool isValidTime(DateTime time) {
    return time.isAfter(DateTime.now());
  }
}