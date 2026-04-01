import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of on-device OCR processing on a Philippine ID.
class OcrResult {
  final bool success;
  final DateTime? dateOfBirth;
  final int? age;
  final String? idType;
  final bool meetsAgeRequirement;
  final String? errorMessage;
  final int rawTextLength;
  final double qualityScore;
  final DateTime? expirationDate;

  const OcrResult({
    required this.success,
    this.dateOfBirth,
    this.age,
    this.idType,
    this.meetsAgeRequirement = false,
    this.errorMessage,
    this.rawTextLength = 0,
    this.qualityScore = 0.0,
    this.expirationDate,
  });

  Map<String, dynamic> toFrontendOcrData() => {
        'extractedAge': age,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'idType': idType ?? 'unknown',
        'meetsAgeRequirement': meetsAgeRequirement,
        'rawTextLength': rawTextLength,
        'qualityScore': qualityScore,
        'expirationDate': expirationDate?.toIso8601String(),
        'ocrEngine': 'google_mlkit_text_recognition',
        'extractionTimestamp': DateTime.now().toIso8601String(),
      };
}

/// On-device OCR for Philippine government IDs.
///
/// Extracts date of birth, validates age, scores image quality,
/// and detects expiration dates. Supports Filipino/English labels
/// and 18+ date patterns including 2-digit years and OCR artifacts.
class IdOcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<OcrResult> extractDobFromId(String imagePath, int minimumAge) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(inputImage).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('[OCR] Processing timed out after 15s');
          throw TimeoutException(
            'OCR processing timed out',
            const Duration(seconds: 15),
          );
        },
      );
      final rawText = recognized.text;
      final quality = _calculateQuality(rawText);

      if (quality < 0.15 || rawText.length < 15) {
        return OcrResult(
          success: false,
          errorMessage: 'Could not read text clearly. Try better lighting.',
          rawTextLength: rawText.length,
          qualityScore: quality,
        );
      }

      final idType = _detectIdType(rawText);

      // Senior Citizen ID / OSCA auto-passes (Philippine law requires 60+)
      if (idType == 'senior_citizen') {
        return OcrResult(
          success: true,
          age: 60,
          idType: idType,
          meetsAgeRequirement: minimumAge <= 60,
          rawTextLength: rawText.length,
          qualityScore: quality,
          expirationDate: _parseExpiration(rawText),
        );
      }

      if (!_isValidIdDocument(rawText)) {
        return OcrResult(
          success: false,
          errorMessage: "This doesn't appear to be an ID. Try again.",
          rawTextLength: rawText.length,
          qualityScore: quality,
        );
      }

      // Try label-proximity first (Filipino + English), then general patterns
      final dob = _extractDobNearLabel(rawText) ?? _parseDateOfBirth(rawText);
      if (dob == null) {
        return OcrResult(
          success: false,
          idType: idType,
          errorMessage: 'Could not find date of birth on your ID.',
          rawTextLength: rawText.length,
          qualityScore: quality,
        );
      }

      final age = _calculateAge(dob);
      return OcrResult(
        success: true,
        dateOfBirth: dob,
        age: age,
        idType: idType,
        meetsAgeRequirement: age >= minimumAge,
        rawTextLength: rawText.length,
        qualityScore: quality,
        expirationDate: _parseExpiration(rawText),
      );
    } on TimeoutException {
      return const OcrResult(
        success: false,
        errorMessage:
            'Reading your ID took too long. Please take a clearer photo '
            'with good lighting and try again.',
      );
    } catch (e) {
      return const OcrResult(
        success: false,
        errorMessage: 'OCR processing failed. Please try again.',
      );
    }
  }

  void dispose() => _recognizer.close();

  // --- Image Quality Scoring (5-factor) ---

  double _calculateQuality(String text) {
    if (text.isEmpty) return 0.0;
    final words = text.split(RegExp(r'\s+'));
    if (words.length < 3) return 0.1;

    final avgLen =
        words.map((w) => w.length).reduce((a, b) => a + b) / words.length;
    final singleRatio =
        words.where((w) => w.length == 1).length / words.length;
    final alphaNum = text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final alphaRatio = alphaNum.isEmpty ? 0.0 : alphaNum.length / text.length;
    final readable = words
        .where((w) => w.length >= 3 && RegExp(r'^[a-zA-Z]+$').hasMatch(w))
        .length;

    final scores = [
      (text.length / 150).clamp(0.0, 1.0), // text length
      (avgLen >= 2 && avgLen <= 12) ? 1.0 : 0.3, // avg word length
      (1.0 - singleRatio * 2.5).clamp(0.0, 1.0), // single-char ratio
      (alphaRatio * 1.5).clamp(0.0, 1.0), // alphanumeric ratio
      (readable / 5).clamp(0.0, 1.0), // readable word count
    ];
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  // --- ID Type Detection ---

  String? _detectIdType(String text) {
    final t = text.toLowerCase();
    if (t.contains('philsys') ||
        t.contains('phil-sys') ||
        t.contains('national id')) {
      return 'philsys';
    }
    if (t.contains('driver') && t.contains('license')) {
      return 'drivers_license';
    }
    if (t.contains('senior citizen') || t.contains('osca')) {
      return 'senior_citizen';
    }
    if (t.contains('sss') || t.contains('social security')) return 'sss';
    if (t.contains('umid')) return 'umid';
    if (t.contains('passport')) return 'passport';
    if (t.contains('pwd') || t.contains('disability')) return 'pwd';
    if (t.contains('postal') && t.contains('id')) return 'postal_id';
    if (t.contains('voter') || t.contains('comelec')) return 'voters_id';
    if (t.contains('philhealth')) return 'philhealth';
    if (t.contains('pag-ibig') || t.contains('pagibig')) return 'pagibig';
    return null;
  }

  // --- Document Validation ---

  bool _isValidIdDocument(String text) {
    final t = text.toLowerCase();
    const keywords = [
      'republic', 'philippines', 'pilipinas', 'name', 'pangalan',
      'date', 'birth', 'kapanganakan', 'address', 'tirahan',
      'sex', 'kasarian', 'nationality', 'valid', 'expiry',
      'id', 'no.', 'number', 'issued', 'signature',
    ];
    int matches = 0;
    for (final kw in keywords) {
      if (t.contains(kw)) matches++;
    }
    return matches >= 3;
  }

  // --- DOB Near Label Extraction (Filipino + English) ---

  DateTime? _extractDobNearLabel(String text) {
    const labels = [
      'petsa ng kapanganakan', 'araw ng kapanganakan', 'kapanganakan',
      'kaarawan', 'date of birth', 'birthdate', 'birth date',
      'date birth', 'birthday', 'born', 'd.o.b', 'dob',
    ];
    final lower = text.toLowerCase();
    for (final label in labels) {
      final idx = lower.indexOf(label);
      if (idx < 0) continue;
      final start = idx + label.length;
      final end = (start + 60).clamp(0, text.length);
      final nearby = text.substring(start, end);
      final date = _findFirstDate(nearby);
      if (date != null && _isReasonableBirthDate(date)) return date;
    }
    return null;
  }

  // --- Expiration Date Extraction ---

  DateTime? _parseExpiration(String text) {
    const labels = [
      'expiry', 'exp date', 'exp.', 'valid until', 'valid thru',
      'good until', 'validity', 'expiration', 'valid through',
    ];
    final lower = text.toLowerCase();
    for (final label in labels) {
      final idx = lower.indexOf(label);
      if (idx < 0) continue;
      final start = idx + label.length;
      final end = (start + 40).clamp(0, text.length);
      final nearby = text.substring(start, end);
      final date = _findFirstDate(nearby);
      if (date != null && date.isAfter(DateTime(2000))) return date;
    }
    return null;
  }

  // --- DOB Extraction (general patterns) ---

  DateTime? _parseDateOfBirth(String text) {
    final normalized = text
        .replaceAll(RegExp(r'[Oo](?=\d)'), '0')
        .replaceAll(RegExp(r'(?<=\d)[Oo]'), '0')
        .replaceAll(RegExp(r'[Il](?=\d)'), '1')
        .replaceAll(RegExp(r'(?<=\d)[Il]'), '1');

    for (final t in [text, normalized]) {
      final date = _findFirstDate(t);
      if (date != null && _isReasonableBirthDate(date)) return date;
    }
    return null;
  }

  // --- Core Date Finder (no validation filter) ---

  static final _datePatterns = [
    // MM/DD/YYYY or DD/MM/YYYY (4-digit year, various separators)
    RegExp(r'(\d{1,2})[/\-.\s:](\d{1,2})[/\-.\s:](\d{4})'),
    // YYYY-MM-DD (ISO)
    RegExp(r'(\d{4})[/\-.\s:](\d{1,2})[/\-.\s:](\d{1,2})'),
    // Month DD, YYYY
    RegExp(
      r'(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|'
      r'Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|'
      r'Dec(?:ember)?)\s+(\d{1,2}),?\s+(\d{4})',
      caseSensitive: false,
    ),
    // DD Month YYYY
    RegExp(
      r'(\d{1,2})\s+(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|'
      r'Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|'
      r'Nov(?:ember)?|Dec(?:ember)?)\s+(\d{4})',
      caseSensitive: false,
    ),
    // MM/DD/YY (2-digit year)
    RegExp(r'(\d{1,2})[/\-.\s:](\d{1,2})[/\-.\s:](\d{2})(?!\d)'),
  ];

  DateTime? _findFirstDate(String text) {
    for (int i = 0; i < _datePatterns.length; i++) {
      final match = _datePatterns[i].firstMatch(text);
      if (match == null) continue;

      try {
        final g = match.groups([1, 2, 3]);
        if (g.contains(null)) continue;

        DateTime? date;
        if (i == 0) {
          // MM/DD/YYYY — try both MM/DD and DD/MM
          date =
              _numeric(int.parse(g[0]!), int.parse(g[1]!), int.parse(g[2]!));
          date ??=
              _numeric(int.parse(g[1]!), int.parse(g[0]!), int.parse(g[2]!));
        } else if (i == 1) {
          date =
              _numeric(int.parse(g[1]!), int.parse(g[2]!), int.parse(g[0]!));
        } else if (i == 2) {
          final m = _monthFromName(g[0]!);
          if (m != null) {
            date = _numeric(m, int.parse(g[1]!), int.parse(g[2]!));
          }
        } else if (i == 3) {
          final m = _monthFromName(g[1]!);
          if (m != null) {
            date = _numeric(m, int.parse(g[0]!), int.parse(g[2]!));
          }
        } else if (i == 4) {
          final yr = _expandYear(int.parse(g[2]!));
          date = _numeric(int.parse(g[0]!), int.parse(g[1]!), yr);
          date ??= _numeric(int.parse(g[1]!), int.parse(g[0]!), yr);
        }

        if (date != null) return date;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  // --- Date Helpers ---

  int _expandYear(int yr) => yr <= 30 ? 2000 + yr : 1900 + yr;

  DateTime? _numeric(int month, int day, int year) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 1900 || year > 2100) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  int? _monthFromName(String name) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[name.substring(0, 3).toLowerCase()];
  }

  bool _isReasonableBirthDate(DateTime date) {
    final now = DateTime.now();
    final age = _calculateAge(date);
    return age >= 10 && age <= 120 && date.isBefore(now);
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
