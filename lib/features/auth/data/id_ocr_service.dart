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
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? sex;
  final String? documentNumber;
  final String? rawTextSnippet;

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
    this.firstName,
    this.lastName,
    this.middleName,
    this.sex,
    this.documentNumber,
    this.rawTextSnippet,
  });

  /// Maps the on-device OCR result to the multipart field shape the backend's
  /// `IdVerificationService.parseOcrJson` expects. Keys must stay in
  /// sync with the server-side parser — backend reads `firstName`,
  /// `lastName`, `middleName`, `dob`, `documentNumber`,
  /// `sex`. Anything else is metadata for diagnostics.
  Map<String, dynamic> toFrontendOcrData() => {
    // Fields the backend parses for prefill.
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (middleName != null) 'middleName': middleName,
    if (dateOfBirth != null)
      'dob':
          '${dateOfBirth!.year.toString().padLeft(4, '0')}-'
          '${dateOfBirth!.month.toString().padLeft(2, '0')}-'
          '${dateOfBirth!.day.toString().padLeft(2, '0')}',
    if (documentNumber != null) 'documentNumber': documentNumber,
    if (sex != null) 'sex': sex,
    // Metadata for backend diagnostics + audit (currently unused but kept
    // so a future server-side consumer can lean on quality scoring).
    'extractedAge': age,
    'idType': idType ?? 'unknown',
    'meetsAgeRequirement': meetsAgeRequirement,
    'rawTextLength': rawTextLength,
    'qualityScore': qualityScore,
    'expirationDate': expirationDate?.toIso8601String(),
    'ocrEngine': 'google_mlkit_text_recognition',
    'extractionTimestamp': DateTime.now().toIso8601String(),
    // Raw text snippet — diagnostic only. Sent so backend logs can show
    // what ML Kit actually saw when prefill misses fields. Drop this
    // once OCR coverage is solid.
    if (rawTextSnippet != null) 'debugRawText': rawTextSnippet,
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
      final recognized = await _recognizer
          .processImage(inputImage)
          .timeout(
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
      debugPrint(
        '[OCR] raw text length=${rawText.length}, quality=${quality.toStringAsFixed(2)}',
      );
      // Truncated dump for diagnosing label-mismatch on senior IDs.
      // Strip newlines so logcat keeps it on a single line.
      debugPrint(
        '[OCR] raw="${rawText.replaceAll('\n', ' | ').substring(0, rawText.length.clamp(0, 800))}"',
      );

      if (quality < 0.15 || rawText.length < 15) {
        return OcrResult(
          success: false,
          errorMessage: 'Could not read text clearly. Try better lighting.',
          rawTextLength: rawText.length,
          qualityScore: quality,
        );
      }

      final idType = _detectIdType(rawText);

      final rawSnippet = _truncateForLog(rawText);

      // Senior Citizen ID / OSCA auto-passes (Philippine law requires 60+)
      if (idType == 'senior_citizen') {
        final names = _extractNames(rawText);
        return OcrResult(
          success: true,
          age: 60,
          idType: idType,
          meetsAgeRequirement: minimumAge <= 60,
          rawTextLength: rawText.length,
          qualityScore: quality,
          expirationDate: _parseExpiration(rawText),
          firstName: names['firstName'],
          lastName: names['lastName'],
          middleName: names['middleName'],
          sex: _extractSex(rawText),
          documentNumber: _extractDocumentNumber(rawText),
          rawTextSnippet: rawSnippet,
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
      final names = _extractNames(rawText);
      return OcrResult(
        success: true,
        dateOfBirth: dob,
        age: age,
        idType: idType,
        meetsAgeRequirement: age >= minimumAge,
        rawTextLength: rawText.length,
        qualityScore: quality,
        expirationDate: _parseExpiration(rawText),
        firstName: names['firstName'],
        lastName: names['lastName'],
        middleName: names['middleName'],
        sex: _extractSex(rawText),
        documentNumber: _extractDocumentNumber(rawText),
        rawTextSnippet: rawSnippet,
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

  /// Newline-flattened, length-capped raw OCR text suitable for log lines.
  /// Used as the diagnostic {@code debugRawText} field in the upload payload
  /// so backend logs can show what ML Kit actually saw.
  String _truncateForLog(String text) {
    final flattened = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flattened.length <= 600 ? flattened : flattened.substring(0, 600);
  }

  // --- Image Quality Scoring (5-factor) ---

  double _calculateQuality(String text) {
    if (text.isEmpty) return 0.0;
    final words = text.split(RegExp(r'\s+'));
    if (words.length < 3) return 0.1;

    final avgLen =
        words.map((w) => w.length).reduce((a, b) => a + b) / words.length;
    final singleRatio = words.where((w) => w.length == 1).length / words.length;
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
      'republic',
      'philippines',
      'pilipinas',
      'name',
      'pangalan',
      'date',
      'birth',
      'kapanganakan',
      'address',
      'tirahan',
      'sex',
      'kasarian',
      'nationality',
      'valid',
      'expiry',
      'id',
      'no.',
      'number',
      'issued',
      'signature',
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
      'petsa ng kapanganakan',
      'araw ng kapanganakan',
      'kapanganakan',
      'kaarawan',
      'date of birth',
      'birthdate',
      'birth date',
      'date birth',
      'birthday',
      'born',
      'd.o.b',
      'dob',
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
      'expiry',
      'exp date',
      'exp.',
      'valid until',
      'valid thru',
      'good until',
      'validity',
      'expiration',
      'valid through',
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
          date = _numeric(int.parse(g[0]!), int.parse(g[1]!), int.parse(g[2]!));
          date ??= _numeric(
            int.parse(g[1]!),
            int.parse(g[0]!),
            int.parse(g[2]!),
          );
        } else if (i == 1) {
          date = _numeric(int.parse(g[1]!), int.parse(g[2]!), int.parse(g[0]!));
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
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return months[name.substring(0, 3).toLowerCase()];
  }

  bool _isReasonableBirthDate(DateTime date) {
    final now = DateTime.now();
    final age = _calculateAge(date);
    return age >= 10 && age <= 120 && date.isBefore(now);
  }

  // --- Name / Sex / Document-number Extraction ---
  //
  // Filipino IDs vary widely in layout. We use label-proximity scanning
  // (find the label, take the next ALL-CAPS phrase) which works for most
  // PhilSys, UMID, driver's license, voter's, senior-citizen layouts.
  // What we don't extract here, the senior fills manually — that's the
  // documented v1 fallback.

  Map<String, String?> _extractNames(String rawText) {
    return {
      'firstName': _extractLabeledName(rawText, _firstNameLabels),
      'lastName': _extractLabeledName(rawText, _lastNameLabels),
      'middleName': _extractLabeledName(rawText, _middleNameLabels),
    };
  }

  static const _firstNameLabels = [
    'given names',
    'given name',
    'first name',
    'pangalan',
    'mga pangalan',
  ];
  static const _lastNameLabels = [
    'last name',
    'surname',
    'family name',
    'apelyido',
  ];
  static const _middleNameLabels = [
    'middle name',
    'gitnang pangalan',
    'middle',
  ];

  String? _extractLabeledName(String text, List<String> labels) {
    final lower = text.toLowerCase();
    for (final label in labels) {
      final idx = lower.indexOf(label);
      if (idx < 0) continue;
      final start = idx + label.length;
      final end = (start + 80).clamp(0, text.length);
      final nearby = text.substring(start, end);
      // Take the first uppercase line of length 2..40 after the label;
      // skips through colons, slashes, commas typical on ID layouts.
      for (final line in nearby.split(RegExp(r'[\r\n]'))) {
        final cleaned = line.replaceAll(RegExp(r'^[\s:,/]+|[\s:,/]+$'), '');
        if (cleaned.length < 2 || cleaned.length > 40) continue;
        // Heuristic: at least 50% letters, contains an uppercase letter, and
        // doesn't itself look like another label.
        final letters = RegExp(r'[A-Za-zÑñ\s.\-]').allMatches(cleaned).length;
        if (letters / cleaned.length < 0.5) continue;
        if (!RegExp(r'[A-ZÑ]').hasMatch(cleaned)) continue;
        if (_looksLikeLabel(cleaned)) continue;
        return _toTitleCase(cleaned);
      }
    }
    return null;
  }

  bool _looksLikeLabel(String s) {
    final low = s.toLowerCase();
    const noisyTokens = [
      'name',
      'pangalan',
      'birth',
      'kapanganakan',
      'sex',
      'kasarian',
      'address',
      'tirahan',
      'nationality',
      'date',
      'expiry',
      'valid',
      'signature',
      'id',
      'no.',
      'number',
    ];
    return noisyTokens.any(low.contains);
  }

  String _toTitleCase(String s) {
    return s
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.isEmpty
              ? w
              : w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''),
        )
        .join(' ')
        .trim();
  }

  String? _extractSex(String text) {
    final lower = text.toLowerCase();
    for (final label in const ['sex', 'kasarian', 'gender']) {
      final idx = lower.indexOf(label);
      if (idx < 0) continue;
      final after = text.substring(
        idx + label.length,
        (idx + label.length + 30).clamp(0, text.length),
      );
      final m = RegExp(
        r'\b([MF]|MALE|FEMALE|LALAKI|BABAE)\b',
        caseSensitive: false,
      ).firstMatch(after);
      if (m != null) {
        final v = m.group(1)!.toUpperCase();
        if (v == 'M' || v == 'MALE' || v == 'LALAKI') return 'M';
        if (v == 'F' || v == 'FEMALE' || v == 'BABAE') return 'F';
      }
    }
    return null;
  }

  String? _extractDocumentNumber(String text) {
    // PhilSys CRN (current physical card layout) is 16 digits in 4-4-4-4
    // groups, e.g. "3849-7095-8312-7985". The older PSN format is 12 digits
    // in 4-7-1 groups. Try the longer pattern FIRST so a card showing both
    // doesn't get matched on the shorter one as a substring.
    final philsysCrn = RegExp(
      r'\b(\d{4}[\s\-]\d{4}[\s\-]\d{4}[\s\-]\d{4})\b',
    ).firstMatch(text);
    if (philsysCrn != null) {
      return philsysCrn.group(1)!.replaceAll(RegExp(r'\s+'), '-');
    }
    final philsysPsn = RegExp(
      r'\b(\d{4}[\s\-]\d{7}[\s\-]\d{1})\b',
    ).firstMatch(text);
    if (philsysPsn != null) {
      return philsysPsn.group(1)!.replaceAll(RegExp(r'\s+'), '-');
    }

    for (final label in const [
      'id no',
      'id number',
      'no.',
      'card no',
      'crn',
      'philsys',
    ]) {
      final idx = text.toLowerCase().indexOf(label);
      if (idx < 0) continue;
      final after = text.substring(
        idx + label.length,
        (idx + label.length + 40).clamp(0, text.length),
      );
      final m = RegExp(r'([A-Z0-9][A-Z0-9\-\s]{6,30})').firstMatch(after);
      if (m != null) {
        return m.group(1)!.trim().replaceAll(RegExp(r'\s+'), '-');
      }
    }
    return null;
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
