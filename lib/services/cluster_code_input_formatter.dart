import 'package:flutter/services.dart';

class ClusterCodeInputFormatter extends TextInputFormatter {
  const ClusterCodeInputFormatter();

  static String normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cursor = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final normalized = normalize(newValue.text);
    final normalizedBeforeCursor = normalize(
      newValue.text.substring(0, cursor),
    );
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalizedBeforeCursor.length),
    );
  }
}
