import 'dart:collection';
import 'dart:math';

import 'base/pkgs/collection/lib/src/combined_wrappers/combined_list.dart'
    as bl;
import 'base/pkgs/collection/lib/src/equality.dart' as bm;
import 'pr18/pkgs/collection/lib/src/combined_wrappers/combined_list.dart'
    as cl;
import 'pr21/pkgs/collection/lib/src/equality.dart' as cm;

var sink = 0;

class Wrapper extends MapBase<int, int> {
  final Map<int, int> data;
  Wrapper(this.data);
  @override
  int? operator [](Object? key) => data[key];
  @override
  void operator []=(int key, int value) => data[key] = value;
  @override
  void clear() => data.clear();
  @override
  Iterable<int> get keys => data.keys;
  @override
  int? remove(Object? key) => data.remove(key);
}

typedef Case = (String, int Function(), int Function(), int);
double measure(int Function() f, int iterations) {
  var checksum = 0;
  final timer = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    checksum = (checksum + f()) & 0x3fffffff;
  }
  timer.stop();
  sink ^= checksum;
  return timer.elapsedTicks * 1e9 / timer.frequency / iterations;
}

void main(List<String> args) {
  final rng = Random(int.parse(args[0]));
  final mode = args[1];
  final cases = <Case>[];
  if (mode == 'list') {
    for (final count in [1, 8, 128]) {
      final lists = List.generate(
        count,
        (i) => List.generate(8, (j) => i * 8 + j),
      );
      final a = bl.CombinedListView<int>(lists);
      final b = cl.CombinedListView<int>(lists);
      cases.addAll([
        (
          'list/$count/index/early',
          () => a.indexOf(0),
          () => b.indexOf(0),
          60000,
        ),
        (
          'list/$count/index/miss',
          () => a.indexOf(-1),
          () => b.indexOf(-1),
          count == 128 ? 800 : 30000,
        ),
        (
          'list/$count/last/front-start',
          () => a.lastIndexOf(0, 0),
          () => b.lastIndexOf(0, 0),
          30000,
        ),
        (
          'list/$count/last/late',
          () => a.lastIndexOf(count * 8 - 1),
          () => b.lastIndexOf(count * 8 - 1),
          30000,
        ),
        ('list/$count/first', () => a.first, () => b.first, 60000),
        ('list/$count/last', () => a.last, () => b.last, 60000),
        (
          'list/$count/empty',
          () => a.isEmpty ? 1 : 0,
          () => b.isEmpty ? 1 : 0,
          60000,
        ),
      ]);
    }
  } else {
    const a = bm.MapEquality<int, int>();
    const b = cm.MapEquality<int, int>();
    for (final count in [0, 1, 8, 64, 1024]) {
      final source = {for (var i = 0; i < count; i++) i: i + 1};
      final maps = {
        'linked': source,
        'hash': HashMap<int, int>.of(source),
        'tree': SplayTreeMap<int, int>.of(source),
        'unmodifiable': Map<int, int>.unmodifiable(source),
        'base': Wrapper(source),
      };
      for (final entry in maps.entries) {
        final map = entry.value;
        cases.add((
          'map/${entry.key}/$count',
          () => a.hash(map),
          () => b.hash(map),
          max(1000, 90000 ~/ max(1, count)),
        ));
      }
    }
  }
  for (final (_, a, b, n) in cases) {
    if (a() != b()) throw StateError('result mismatch');
    measure(a, n);
    measure(b, n);
  }
  print('case,round,first,baseline_ns,changed_ns');
  for (var round = 0; round < 11; round++) {
    cases.shuffle(rng);
    for (final (name, a, b, n) in cases) {
      final forward = rng.nextBool();
      final first = measure(forward ? a : b, n);
      final second = measure(forward ? b : a, n);
      print(
        '$name,$round,${forward ? "base" : "changed"},${forward ? first : second},${forward ? second : first}',
      );
    }
  }
  if (sink != 0) throw StateError('unequal accumulated checksums: $sink');
}
