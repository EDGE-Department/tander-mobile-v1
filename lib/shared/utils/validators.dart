/// Form validation utilities for elder-friendly input.
class Validators {
  Validators._();

  /// Regex for names: letters, spaces, hyphens, dots, and accented characters.
  static final _nameCharRegex = RegExp(r"^[a-zA-ZÀ-ÿñÑ\s.\-']+$");

  /// Validate first name.
  static String? firstName(String? value) {
    if (value == null || value.trim().isEmpty) return 'First name is required';
    final trimmed = value.trim();
    if (trimmed.length < 2) return 'First name must be at least 2 characters';
    if (!_nameCharRegex.hasMatch(trimmed)) {
      return 'First name can only contain letters, spaces, hyphens, and dots';
    }
    return null;
  }

  /// Validate last name.
  static String? lastName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Last name is required';
    final trimmed = value.trim();
    if (trimmed.length < 2) return 'Last name must be at least 2 characters';
    if (!_nameCharRegex.hasMatch(trimmed)) {
      return 'Last name can only contain letters, spaces, hyphens, and dots';
    }
    return null;
  }

  /// Validate email format.
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address';
    return null;
  }

  /// Validate password strength (8+ chars, 1 uppercase, 1 digit).
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validate password confirmation matches.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  /// Validate OTP code.
  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP code is required';
    if (value.length != 6) return 'OTP code must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP code must contain only numbers';
    }
    return null;
  }
}
