/// Constants used across the registration flow.
class RegistrationConstants {
  RegistrationConstants._();

  /// Step labels for the registration progress indicator.
  static const List<String> stepLabels = [
    'Account',
    'Verify',
    'Profile',
    'Photos',
  ];

  /// OTP configuration.
  static const int otpLength = 6;
  static const int otpCooldownSeconds = 60;

  /// Twilio email OTP verification enabled.
  static const bool otpEnabled = true;

  /// Current consent document version. Update when terms/privacy policy change.
  static const String consentVersion = '1.0';

  /// Philippine country code for phone numbers.
  static const String phoneCountryCode = '+63';

  /// Phone number length (digits after country code).
  static const int phoneDigitLength = 10;

  /// Philippine cities for the city picker.
  static const List<String> philippineCities = [
    'Manila',
    'Quezon City',
    'Davao City',
    'Caloocan',
    'Cebu City',
    'Zamboanga City',
    'Taguig',
    'Antipolo',
    'Pasig',
    'Cagayan de Oro',
    'Paranaque',
    'Dasmarinas',
    'Valenzuela',
    'Bacoor',
    'General Santos',
    'Las Pinas',
    'Makati',
    'San Jose del Monte',
    'Muntinlupa',
    'Lapu-Lapu City',
  ];

  /// Gender options.
  static const List<String> genderOptions = ['Male', 'Female'];
}
