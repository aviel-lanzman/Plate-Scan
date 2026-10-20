String _two(int n) => n.toString().padLeft(2, '0');

/// 20/10/2026 09:05
String formatDateTime(DateTime t) =>
    '${_two(t.day)}/${_two(t.month)}/${t.year} ${_two(t.hour)}:${_two(t.minute)}';

/// 09:05:30
String formatTime(DateTime t) =>
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

/// "2026-10-15" -> "15/10/2026"; returns the input unchanged if unparseable.
String formatIsoDate(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : '${_two(d.day)}/${_two(d.month)}/${d.year}';
}
