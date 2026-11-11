import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('packed input survives empty fill, shrink, and regrow', () {
    final input = List.generate(130, (i) => i % 3 != 0);
    for (final keep in [0, 1, 31, 32, 33, 63, 64, 65, 99]) {
      final bits = BoolList.of(input.map((value) => value), growable: true);
      bits.fillRange(128, 128, false);
      expect(bits, input);
      bits.length = keep;
      bits.fillRange(keep, keep, true);
      bits.length = input.length;
      expect(bits, [...input.take(keep), ...List.filled(130 - keep, false)]);
    }
  });
}
