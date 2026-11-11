import 'dart:math';

import '../lib/src/review_bool_before.dart' as bool_before;
import '../lib/src/review_bool_original.dart' as bool_original;
import '../lib/src/review_bool_reviewed.dart' as bool_reviewed;
import '../lib/src/review_queue_before.dart' as queue_before;
import '../lib/src/review_queue_proposed.dart' as queue_proposed;

var checksum = 0;

Iterable<bool> lazy(List<bool> values) sync* {
  yield* values;
}

@pragma('vm:never-inline')
double timeBool(
  List<bool> Function(Iterable<bool>) make,
  Iterable<bool> input,
  int operations,
) {
  var sum = 0;
  final watch = Stopwatch()..start();
  for (var i = 0; i < operations; i++) {
    final result = make(input);
    sum += result[i % result.length] ? result.length : -1;
  }
  watch.stop();
  checksum += sum;
  return watch.elapsedTicks * 1e9 / watch.frequency / operations;
}

@pragma('vm:never-inline')
List<int> makeQueueBefore(List<int> input, bool append) {
  final result = queue_before.QueueList<int>.from(input);
  if (append) result.add(17);
  return result;
}

@pragma('vm:never-inline')
List<int> makeQueueProposed(List<int> input, bool append) {
  final result = queue_proposed.QueueList<int>.from(input);
  if (append) result.add(17);
  return result;
}

@pragma('vm:never-inline')
double timeQueue(
  List<int> Function(List<int>, bool) make,
  List<int> input,
  bool append,
  int operations,
) {
  var sum = 0;
  final watch = Stopwatch()..start();
  for (var i = 0; i < operations; i++) {
    final result = make(input, append);
    sum += result[i % result.length] + result.length;
  }
  watch.stop();
  checksum += sum;
  return watch.elapsedTicks * 1e9 / watch.frequency / operations;
}

void record(
  String benchmark,
  String scenario,
  int count,
  int operations,
  Random random,
  Map<String, double Function()> timings,
) {
  for (final time in timings.values) {
    time();
  }
  for (var round = 0; round < 11; round++) {
    final order = timings.keys.toList()..shuffle(random);
    for (var index = 0; index < order.length; index++) {
      final variant = order[index];
      final ns = timings[variant]!();
      print(
        '$benchmark,$scenario,$count,$round,$index,$variant,'
        '$operations,${ns.toStringAsFixed(6)}',
      );
    }
  }
}

void main(List<String> arguments) {
  final random = Random(int.parse(arguments.single));
  print('benchmark,scenario,count,round,order,variant,operations,ns_per_op');
  for (final count in [2, 31, 32, 33, 63, 64, 65, 1000, 10000]) {
    final input = List<bool>.generate(count, (_) => random.nextBool());
    final sources = {
      'list': input,
      if (count == 2) 'set': <bool>{false, true},
      'mapped-list': input.map((value) => !value),
      'sync-star': lazy(input),
    };
    final operations = max(300, 500000 ~/ count);
    for (final entry in sources.entries) {
      final source = entry.value;
      record('BoolList.of', entry.key, count, operations, random, {
        'baseline': () => timeBool(bool_before.BoolList.of, source, operations),
        'original': () =>
            timeBool(bool_original.BoolList.of, source, operations),
        'reviewed': () =>
            timeBool(bool_reviewed.BoolList.of, source, operations),
      });
    }
  }

  for (final count in [6, 7, 8, 14, 15, 16, 30, 31, 32, 62, 63, 64, 1023]) {
    final input = List<int>.generate(count, (_) => random.nextInt(256));
    final operations = max(1200, 700000 ~/ count);
    for (final append in [false, true]) {
      record(
        'QueueList.from',
        append ? 'create-add' : 'create',
        count,
        operations,
        random,
        {
          'baseline': () =>
              timeQueue(makeQueueBefore, input, append, operations),
          'proposed': () =>
              timeQueue(makeQueueProposed, input, append, operations),
        },
      );
    }
  }
  print('# checksum=$checksum');
}
