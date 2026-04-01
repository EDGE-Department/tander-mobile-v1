/// Registration method chosen by the user on the Sign Up screen.
enum RegistrationMethod { phone, email }

/// Convert stored string to [RegistrationMethod] enum.
RegistrationMethod registrationMethodFromString(String? value) {
  return switch (value) {
    'phone' => RegistrationMethod.phone,
    _ => RegistrationMethod.email,
  };
}

/// Convert [RegistrationMethod] enum to storage string.
String registrationMethodToString(RegistrationMethod method) {
  return switch (method) {
    RegistrationMethod.phone => 'phone',
    RegistrationMethod.email => 'email',
  };
}
