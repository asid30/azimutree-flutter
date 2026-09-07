import 'package:azimutree/services/cluster_code_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = ClusterCodeInputFormatter();

  test('kode klaster otomatis kapital dan tidak menerima spasi', () {
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: ' cl 1\t a ',
        selection: TextSelection.collapsed(offset: 9),
      ),
    );

    expect(result.text, 'CL1A');
    expect(result.selection.baseOffset, 4);
  });
}
