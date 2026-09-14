/// Short human-friendly order reference from the epoch-microsecond id,
/// e.g. "1789-0341". Used on snackbars and the Awaiting Orders list.
String orderRef(int? id) {
  if (id == null) return '?';
  final s = id.toString();
  final tail = s.length <= 4 ? s : s.substring(s.length - 4);
  final head = s.length <= 8 ? '' : s.substring(0, 4);
  return head.isEmpty ? '#$tail' : '$head-$tail';
}
