import '../../../../core-review/pkgs/collection/lib/collection.dart' as before;
import '../../../../collection-b-qa-15/pkgs/collection/lib/collection.dart'
    as afterEquality;
import '../lib/collection.dart' as afterBool;
import 'dart:math';

int sink = 0;

@pragma('vm:never-inline')
int shrink(List<bool> values, int from, int to) {
  values.length = to;
  values.length = from;
  return values[0] ? 1 : 0;
}

@pragma('vm:never-inline')
int oldHash(List<int> list) => const before.ListEquality<int>().hash(list);

@pragma('vm:never-inline')
int newHash(List<int> list) =>
    const afterEquality.ListEquality<int>().hash(list);

@pragma('vm:never-inline')
int oldEquals(List<int> left, List<int> right) =>
    before.ListExtensions<int>(left).equals(right) ? 1 : 0;

@pragma('vm:never-inline')
int newEquals(List<int> left, List<int> right) =>
    afterEquality.ListExtensions<int>(left).equals(right) ? 1 : 0;

double measure(int Function() body, int ms) {
  const batch = 64;
  final sw = Stopwatch()..start();
  var count = 0;
  while (sw.elapsedMicroseconds < ms * 1000) {
    for (var i = 0; i < batch; i++) {
      sink = (sink + body()) & 0x3fffffff;
    }
    count += batch;
  }
  return sw.elapsedTicks * (1000000000 / sw.frequency) / count;
}

void main() {
  final cases = <(String, int Function(), int Function())>[];
  for (final (name, capacity, from, to) in [
    ('bool-word', 32, 32, 31),
    ('bool-small', 128, 128, 121),
    ('bool-dense', 4096, 4096, 4095),
    ('bool-reallocate', 4096, 4096, 1023),
    ('bool-reserved', 1048576, 128, 127),
  ]) {
    final old = before.BoolList.empty(capacity: capacity)..length = from;
    final next = afterBool.BoolList.empty(capacity: capacity)..length = from;
    old[0] = true;
    next[0] = true;
    cases
        .add((name, () => shrink(old, from, to), () => shrink(next, from, to)));
  }
  for (final (name, parts, count) in [
    ('plain-8', 0, 8),
    ('plain-128', 0, 128),
    ('view-4x16', 4, 16),
    ('view-32x16', 32, 16),
  ]) {
    List<int> create() {
      if (parts == 0) return List<int>.generate(count, (i) => i);
      return before.CombinedListView<int>(
        List.generate(parts, (p) => List.generate(count, (i) => p * count + i)),
      );
    }

    final left = create();
    final right = create();
    cases.add(('$name-hash', () => oldHash(left), () => newHash(left)));
    cases.add((
      '$name-equals',
      () => oldEquals(left, right),
      () => newEquals(left, right)
    ));
    if (parts == 0) {
      final mismatch = create()..[0] = -1;
      cases.add((
        '$name-mismatch',
        () => oldEquals(left, mismatch),
        () => newEquals(left, mismatch)
      ));
    }
  }
  final random = Random(1738);
  for (final (_, a, b) in cases) {
    if (a() != b()) throw StateError('Different output');
    measure(a, 40);
    measure(b, 40);
  }
  print('round,case,before_ns,after_ns');
  for (var round = 0; round < 7; round++) {
    cases.shuffle(random);
    for (final (name, a, b) in cases) {
      late double old;
      late double next;
      if (random.nextBool()) {
        old = measure(a, 60);
        next = measure(b, 60);
      } else {
        next = measure(b, 60);
        old = measure(a, 60);
      }
      print('$round,$name,$old,$next');
    }
  }
  print('# checksum $sink');
}
