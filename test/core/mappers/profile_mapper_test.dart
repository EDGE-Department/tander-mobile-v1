import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/core/mappers/profile_mapper.dart';

void main() {
  group('ProfileMapper.parseJsonStringArray', () {
    test('returns empty for null, empty, and whitespace-only input', () {
      expect(ProfileMapper.parseJsonStringArray(null), isEmpty);
      expect(ProfileMapper.parseJsonStringArray(''), isEmpty);
      expect(ProfileMapper.parseJsonStringArray('   '), isEmpty);
    });

    test('decodes a valid JSON string array', () {
      expect(
        ProfileMapper.parseJsonStringArray('["reading", "gardening"]'),
        ['reading', 'gardening'],
      );
    });

    test('valid JSON array with no strings filters down to empty', () {
      // jsonDecode succeeds → whereType<String> removes every numeric element.
      expect(ProfileMapper.parseJsonStringArray('[1, 2, 3]'), isEmpty);
    });

    test('comma-separated input is split and trimmed', () {
      expect(
        ProfileMapper.parseJsonStringArray('reading, gardening , chess'),
        ['reading', 'gardening', 'chess'],
      );
    });

    test('drops empty segments in comma-separated input', () {
      expect(
        ProfileMapper.parseJsonStringArray('a,, b,'),
        ['a', 'b'],
      );
    });

    test('a "[" prefix that is not valid JSON falls through to comma-split', () {
      // "[reading,chess]" is not valid JSON (unquoted) → FormatException →
      // comma-split keeps the literal brackets. Documents the edge behavior.
      expect(
        ProfileMapper.parseJsonStringArray('[reading,chess]'),
        ['[reading', 'chess]'],
      );
    });
  });
}
