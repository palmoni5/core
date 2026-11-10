// Use run.py to prepare the exact source copies and compile this benchmark.
// Compare base fa0c6b77, original a58e083e, and a table-category experiment.
// Three independent package implementations must coexist in this process.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:io';
import 'dart:math';
import 'worktrees/baseline/pkgs/characters/lib/characters.dart' as base;
import 'worktrees/original/pkgs/characters/lib/characters.dart' as original;
import 'worktrees/generic/pkgs/characters/lib/characters.dart' as generic;

typedef Runner = int Function(String, int, String);
int baseline(String s, int n, String mode) {
  var checksum = 0;
  final c = base.Characters(s);
  for (var i = 0; i < n; i++) {
    if (mode == 'length') {
      checksum += c.length;
      continue;
    }
    if (mode == 'forward') {
      final it = c.iterator;
      while (it.moveNext()) {
        checksum++;
      }
    } else {
      final it = c.iteratorAtEnd;
      while (it.moveBack()) {
        checksum++;
      }
    }
  }
  return checksum;
}

int proposed(String s, int n, String mode) {
  var checksum = 0;
  final c = original.Characters(s);
  for (var i = 0; i < n; i++) {
    if (mode == 'length') {
      checksum += c.length;
      continue;
    }
    if (mode == 'forward') {
      final it = c.iterator;
      while (it.moveNext()) {
        checksum++;
      }
    } else {
      final it = c.iteratorAtEnd;
      while (it.moveBack()) {
        checksum++;
      }
    }
  }
  return checksum;
}

int experiment(String s, int n, String mode) {
  var checksum = 0;
  final c = generic.Characters(s);
  for (var i = 0; i < n; i++) {
    if (mode == 'length') {
      checksum += c.length;
      continue;
    }
    if (mode == 'forward') {
      final it = c.iterator;
      while (it.moveNext()) {
        checksum++;
      }
    } else {
      final it = c.iteratorAtEnd;
      while (it.moveBack()) {
        checksum++;
      }
    }
  }
  return checksum;
}

void main(List<String> args) {
  if (args.length > 1) {
    while (!File(args[1]).existsSync()) {
      sleep(const Duration(milliseconds: 1));
    }
  }
  final out = File(
    args.isEmpty ? 'core-pr1045-results.csv' : args.first,
  ).openSync(mode: FileMode.write);
  out.writeStringSync(
    'language,size,mode,round,order,variant,utf16_units,graphemes,iterations,elapsed_us,checksum,clusters_per_second\n',
  );
  final samples = <String, String>{
    'ASCII': 'A simple English sentence to measure. ',
    'Hebrew':
        '\u05d1\u05e8\u05d0\u05e9\u05d9\u05ea \u05d1\u05e8\u05d0 \u05d0\u05dc\u05d4\u05d9\u05dd \u05d0\u05ea \u05d4\u05e9\u05de\u05d9\u05dd. ',
    'niqqud':
        '\u05d1\u05b0\u05bc\u05e8\u05b5\u05d0\u05e9\u05b4\u05c1\u05d9\u05ea \u05d1\u05b8\u05bc\u05e8\u05b8\u05d0 \u05d0\u05b1\u05dc\u05b9\u05d4\u05b4\u05d9\u05dd. ',
    'Arabic':
        '\u0627\u0644\u0639\u0631\u0628\u064a\u0629 \u0644\u063a\u0629 \u062c\u0645\u064a\u0644\u0629 \u0648\u0645\u062a\u0646\u0648\u0639\u0629. ',
    'LatinExtended':
        '\u0100\u0101\u0102\u0103\u0104\u0105\u0112\u0113\u0114\u0115 \u014c\u014d\u014e\u014f\u0150\u0151\u0178\u0179\u017a\u017b\u017c\u017d\u017e. ',
    'Hangul':
        '\uac00\ub098\ub2e4\ub77c\ub9c8\ubc14\uc0ac\uc544\uc790\ucc28\uce74\ud0c0\ud30c\ud558 \ud55c\uad6d\uc5b4 \ubb38\uc7a5. ',
    'emojiMixed':
        '\u{1f469}\u200d\u{1f4bb}\u{1f1ee}\u{1f1f1} ABC \u05e9\u05dc\u05d5\u05dd \u{1f600}\ufe0f\u{1f44d}\u{1f3fd} \u0627\u0644\u0639\u0631\u0628\u064a\u0629 ',
  };
  final variants = <String, Runner>{
    'baseline': baseline,
    'original': proposed,
    'generic': experiment,
  };
  final rng = Random(1045);
  for (final e in samples.entries) {
    for (final repeats in [1, 1024]) {
      final s = List.filled(repeats, e.value).join();
      final size = repeats == 1 ? 'short' : 'long';
      final count = base.Characters(s).length;
      for (final mode in ['forward', 'length', 'reverse']) {
        for (final fn in variants.values) {
          if (fn(s, 3, mode) != count * 3) throw StateError('warmup checksum');
        }
        var n = max(1, 100000 ~/ s.length);
        final cal = Stopwatch()..start();
        baseline(s, n, mode);
        cal.stop();
        n = max(
          2,
          min(10000000, (n * 30000 / max(1, cal.elapsedMicroseconds)).ceil()),
        );
        for (var round = 0; round < 7; round++) {
          final order = variants.keys.toList()..shuffle(rng);
          for (var j = 0; j < order.length; j++) {
            final name = order[j];
            final watch = Stopwatch()..start();
            final sum = variants[name]!(s, n, mode);
            watch.stop();
            if (sum != count * n) {
              throw StateError('$name $mode checksum: $sum != ${count * n}');
            }
            out.writeStringSync(
              '${e.key},$size,$mode,$round,$j,$name,${s.length},$count,$n,${watch.elapsedMicroseconds},$sum,${sum * 1e6 / watch.elapsedMicroseconds}\n',
            );
          }
        }
        stdout.writeln('${e.key} $size $mode done');
      }
    }
  }
  out.closeSync();
}
