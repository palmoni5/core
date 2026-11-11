import 'dart:math';
import 'base/combined_list.dart' as base;
import 'full/combined_list.dart' as full;
import 'delegate/combined_list.dart' as delegate;

int sink = 0;
double measure(int Function() call, int n) {
  var sum = 0;
  final timer = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    sum = (sum + call()) & 0x3fffffff;
  }
  timer.stop();
  sink += sum;
  return timer.elapsedTicks * 1e9 / timer.frequency / n;
}

void main(List<String> args) {
  final rng = Random(int.parse(args.single));
  final cases = <(String, List<int Function()>, int)>[];
  for (final n in [1, 2, 3, 8, 128]) {
    final input = List.generate(n, (i) => List.generate(8, (j) => i * 8 + j));
    final lists = <List<int>>[base.CombinedListView(input), full.CombinedListView(input), delegate.CombinedListView(input)];
    cases.add(('$n/miss', [for (final list in lists) () => list.indexOf(-1)], n == 128 ? 800 : 50000));
    cases.add(('$n/first-hit', [for (final list in lists) () => list.indexOf(0)], 80000));
    cases.add(('$n/last-hit-from-middle', [for (final list in lists) () => list.indexOf(n * 8 - 1, n * 4)], n == 128 ? 800 : 50000));
  }
  print('case,round,first,base_ns,full_ns,delegate_ns');
  for (final (_, calls, n) in cases) {
    if (calls.map((f) => f()).toSet().length != 1) throw StateError('result mismatch');
    for (final f in calls) { measure(f,n); }
  }
  for (var round = 0; round < 11; round++) {
    cases.shuffle(rng);
    for (final (name,calls,n) in cases) {
      final order = [0, 1, 2]..shuffle(rng);
      final times = List<double>.filled(3, 0);
      for (final v in order) { times[v] = measure(calls[v], n); }
      print('$name,$round,${order.join()},${times.join(',')}');
    }
  }
  if (sink < 0) throw StateError('invalid checksum');
}