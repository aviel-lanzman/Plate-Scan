import 'dart:collection';

/// Extracts Israeli licence plate numbers (7 or 8 digits) from OCR text lines.
class PlateParser {
  const PlateParser._();

  // Letters OCR commonly returns instead of digits on a plate.
  static const _ocrFixes = {
    'O': '0', 'o': '0', 'D': '0', 'Q': '0', //
    'I': '1', 'i': '1', 'l': '1', '|': '1', '!': '1',
    'S': '5', 's': '5',
    'B': '8',
    'Z': '2', 'z': '2',
  };

  /// Allow at most this many substituted characters per candidate, so random
  /// words are not turned into numbers.
  static const _maxFixes = 2;

  static final _separators = RegExp(r'[\s\-–—_.·:,]');
  static final _countryTokens = RegExp(
    r'^(IL|ISRAEL|ישראל)$',
    caseSensitive: false,
  );
  // The blue "IL" strip is sometimes read as part of the number ("IL12-345-67").
  static final _countryPrefix = RegExp(r'^[Il1|]L', caseSensitive: false);
  static final _countrySuffix = RegExp(r'IL$', caseSensitive: false);
  static final _plate = RegExp(r'^\d{7,8}$');

  /// Returns the distinct plate numbers (digits only) found in [lines].
  static List<String> extract(Iterable<String> lines) {
    final found = <String>{};
    for (final line in lines) {
      final plate = parseLine(line);
      if (plate != null) found.add(plate);
    }
    return found.toList();
  }

  /// Parses one OCR line, returning the plate digits or null.
  static String? parseLine(String line) {
    final tokens = line
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_countryTokens.hasMatch(t))
        .toList();
    String join(List<String> t) => t.join().replaceAll(_separators, '');
    final joined = join(tokens);
    if (joined.isEmpty) return null;

    // A lone "I" next to the number is usually the "IL" strip, not a digit,
    // so also try without it.
    final hasLeadingStray = tokens.length > 1 && _isStray(tokens.first);
    final hasTrailingStray = tokens.length > 1 && _isStray(tokens.last);
    final candidates = {
      joined,
      joined.replaceFirst(_countryPrefix, ''),
      joined.replaceFirst(_countrySuffix, ''),
      if (hasLeadingStray) join(tokens.sublist(1)),
      if (hasTrailingStray) join(tokens.sublist(0, tokens.length - 1)),
      if (hasLeadingStray && hasTrailingStray && tokens.length > 2)
        join(tokens.sublist(1, tokens.length - 1)),
    };

    // The reading that needs the fewest letter-to-digit fixes wins; ties keep
    // the order above.
    String? best;
    var bestFixes = _maxFixes + 1;
    for (final candidate in candidates) {
      final fixed = _fixDigits(candidate);
      if (fixed == null || !_plate.hasMatch(fixed.digits)) continue;
      if (fixed.fixes < bestFixes) {
        best = fixed.digits;
        bestFixes = fixed.fixes;
      }
    }
    return best;
  }

  static bool _isStray(String token) =>
      token.length == 1 && const {'I', 'i', 'l', '|', '!'}.contains(token);

  static ({String digits, int fixes})? _fixDigits(String s) {
    var fixes = 0;
    final out = StringBuffer();
    for (final ch in s.split('')) {
      if (_isDigit(ch)) {
        out.write(ch);
      } else if (_ocrFixes.containsKey(ch) && ++fixes <= _maxFixes) {
        out.write(_ocrFixes[ch]);
      } else {
        return null;
      }
    }
    return (digits: out.toString(), fixes: fixes);
  }

  static bool _isDigit(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39;
  }
}

/// Keeps only the digits of user input, e.g. "12-345-67" -> "1234567".
String normalizePlate(String input) => input.replaceAll(RegExp(r'\D'), '');

/// Manually typed plates may be older, shorter formats.
bool isValidPlate(String digits) => RegExp(r'^\d{4,8}$').hasMatch(digits);

/// Formats digits the way they appear on Israeli plates:
/// 7 digits -> 12-345-67, 8 digits -> 123-45-678.
String formatPlate(String digits) {
  if (digits.length == 7) {
    return '${digits.substring(0, 2)}-${digits.substring(2, 5)}-${digits.substring(5)}';
  }
  if (digits.length == 8) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 5)}-${digits.substring(5)}';
  }
  return digits;
}

/// Confirms a plate only after it is read in [threshold] of the last [window]
/// frames, which filters out one-off OCR misreads.
class PlateVoter {
  PlateVoter({this.window = 6, this.threshold = 3})
    : assert(threshold <= window);

  final int window;
  final int threshold;
  final _frames = Queue<Set<String>>();
  String? _leader;

  /// The plate read most often in the window (the most recent one on a
  /// tie), even if not confirmed yet; null when the window has none.
  String? get leader => _leader;

  /// Records one frame's candidates and returns the plates now confirmed,
  /// most-seen first.
  List<String> add(Iterable<String> candidates) {
    _frames.addLast(candidates.toSet());
    if (_frames.length > window) _frames.removeFirst();

    final counts = <String, int>{};
    final lastSeen = <String, int>{};
    for (final (i, frame) in _frames.indexed) {
      for (final plate in frame) {
        counts[plate] = (counts[plate] ?? 0) + 1;
        lastSeen[plate] = i;
      }
    }
    final ranked = counts.entries.toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : lastSeen[b.key]!.compareTo(lastSeen[a.key]!),
      );
    _leader = ranked.firstOrNull?.key;
    return [
      for (final e in ranked)
        if (e.value >= threshold) e.key,
    ];
  }

  void reset() {
    _frames.clear();
    _leader = null;
  }
}
