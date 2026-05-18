import 'dart:convert';
import 'dart:io';

void appendDebugLog(Map<String, dynamic> payload) {
  File(r'd:\VSSSCODESS\LEE\travelpick\debug-cbf8a0.log').writeAsStringSync(
    '${jsonEncode(payload)}\n',
    mode: FileMode.append,
  );
}
