/// Extracts a senior-friendly first name for greeting display.
///
/// Splits [username] on whitespace and returns the first token, capped at
/// 24 characters. Returns `'friend'` for null, empty, or whitespace-only
/// input (the welcome screen's fallback greeting).
String extractFirstName(String? username) {
  final rawFirst = (username ?? '').trim().split(RegExp(r'\s+')).first;
  if (rawFirst.isEmpty) return 'friend';
  return rawFirst.length > 24 ? rawFirst.substring(0, 24) : rawFirst;
}
