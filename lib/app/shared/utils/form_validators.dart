class FormValidators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Please enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  // Returns a validator function that checks against [original] at call time.
  // Usage: validator: FormValidators.confirmPassword(() => passwordCtrl.text)
  static String? Function(String?) confirmPassword(
    String Function() getOriginal,
  ) {
    return (value) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != getOriginal()) return 'Passwords do not match';
      return null;
    };
  }

  // Optional phone — returns null (no error) when the field is empty.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length != 10) return 'Must be 10 digits';
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }
}