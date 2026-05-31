String normalizeMerchantName(String? input) {
  if (input == null) return '';
  var s = input.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}

double similarityScore(String a, String b) {
  a = normalizeMerchantName(a);
  b = normalizeMerchantName(b);
  if (a == b) return 1.0;
  if (a.startsWith(b) || b.startsWith(a)) return 0.9;
  return 0.0;
}
