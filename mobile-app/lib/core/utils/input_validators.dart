class InputValidators {
  static final RegExp _emailRegExp = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  const InputValidators._();

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isValidEmail(String? value) {
    if (!isNotEmpty(value)) {
      return false;
    }
    return _emailRegExp.hasMatch(value!.trim());
  }

  static bool hasMinLength(String? value, int minLength) {
    if (!isNotEmpty(value)) {
      return false;
    }
    return value!.trim().length >= minLength;
  }
}
