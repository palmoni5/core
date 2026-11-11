// Portions of ListIterator are from dart: SDK internal/iterable.dart.
// Copyright (c) 2011, the Dart project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license in LICENSE.

import 'dart:io';
import 'dart:math';

abstract class Range {
  final String source;
  int start;
  int end;
  Range(this.source, this.start, this.end);
  Iterable<int> get units;
}

class Baseline extends Range {
  Baseline(super.source, super.start, super.end);
  @override
  Iterable<int> get units => source.codeUnits.getRange(start, end);
}

class Proposal extends Range {
  Proposal(super.source, super.start, super.end);
  @override
  Iterable<int> get units => DirectView(source, start, end);
}

class DirectView extends Iterable<int> {
  final String source;
  final int start;
  @override
  final int length;
  DirectView(this.source, this.start, int end)
    : length = RangeError.checkValidRange(start, end, source.length) - start;
  @override
  int elementAt(int index) =>
      source.codeUnitAt(start + IndexError.check(index, length));
  @override
  bool get isEmpty => length == 0;
  @override
  Iterator<int> get iterator => ListIterator<int>(this);
}

class ListIterator<E> implements Iterator<E> {
  final Iterable<E> _iterable;
  final int _length;
  int _index;
  E? _current;

  @pragma("wasm:prefer-inline")
  ListIterator(Iterable<E> iterable)
    : _iterable = iterable,
      _length = iterable.length,
      _index = 0;

  @pragma("wasm:prefer-inline")
  @override
  E get current => _current as E;

  @pragma("vm:prefer-inline")
  @pragma("wasm:prefer-inline")
  @override
  bool moveNext() {
    int length = _iterable.length;
    if (_length != length) {
      throw ConcurrentModificationError(_iterable);
    }
    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable.elementAt(_index);
    _index++;
    return true;
  }
}

int checksum = 0;

@pragma('vm:never-inline')
int work(Range range, String mode, int iterations, int start, int length) {
  var sum = 0;
  for (var i = 0; i < iterations; i++) {
    range.start = start + (i & 1);
    range.end = range.start + length;
    final values = range.units;
    switch (mode) {
      case 'length':
        sum += values.length;
      case 'isEmpty':
        sum += values.isEmpty ? 1 : 2;
      case 'elementAt':
        sum += values.elementAt(i % length);
      case 'iterate':
        for (final value in values) {
          sum += value;
        }
      case 'repeat':
        for (var j = 0; j < 3; j++) {
          for (final value in values) {
            sum += value;
          }
        }
      case 'snapshot':
        range.start = 0;
        range.end = 0;
        for (final value in values) {
          sum += value;
        }
    }
  }
  return sum;
}

int timed(Range range, String mode, int count, int start, int length) {
  final timer = Stopwatch()..start();
  final result = work(range, mode, count, start, length);
  final micros = timer.elapsedMicroseconds;
  checksum ^= result;
  return micros;
}

void main(List<String> args) {
  stdin.readLineSync(); // Parent pins processor affinity before releasing work.
  final seed = int.parse(args[1]);
  final random = Random(seed);
  final short = List.filled(8, 'אָב😀גד').join();
  final long = List.filled(200000, 'אָב😀גד').join();
  final output = File(args[0]).openSync(mode: FileMode.write);
  output.writeStringSync(
    'seed,case,mode,pair,order,iterations,baseline_us,proposal_us,checksum\n',
  );
  for (final item in [
    ('empty', short, 0),
    ('short_2', short, 2),
    ('short_32', short, 32),
    ('long_2', long, 2),
    ('long_8192', long, 8192),
  ]) {
    final (name, source, length) = item;
    final start = (source.length - length) ~/ 2;
    final before = Baseline(source, start, start + length);
    final after = Proposal(source, start, start + length);
    for (final mode in [
      'length',
      'isEmpty',
      'elementAt',
      'iterate',
      'repeat',
      'snapshot',
    ]) {
      if (length == 0 && mode == 'elementAt') continue;
      final checkBefore = work(before, mode, 37, start, length);
      final checkAfter = work(after, mode, 37, start, length);
      if (checkBefore != checkAfter)
        throw StateError('checksum mismatch $name/$mode');
      var count = 32;
      while (count < 16777216) {
        final elapsed = timed(before, mode, count, start, length);
        timed(after, mode, count, start, length);
        if (elapsed >= 15000) break;
        count *= 2;
      }
      for (var pair = 0; pair < 11; pair++) {
        final flip = random.nextBool();
        final a = timed(flip ? after : before, mode, count, start, length);
        final b = timed(flip ? before : after, mode, count, start, length);
        output.writeStringSync(
          '$seed,$name,$mode,$pair,${flip ? "PB" : "BP"},$count,${flip ? b : a},${flip ? a : b},$checkBefore\n',
        );
      }
    }
  }
  output.closeSync();
  stdout.writeln('seed=$seed checksum=$checksum completed');
}
