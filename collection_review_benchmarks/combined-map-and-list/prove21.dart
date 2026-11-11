import 'dart:collection';

import 'base/pkgs/collection/lib/src/equality.dart' as before;
import 'pr21/pkgs/collection/lib/src/equality.dart' as after;

class InconsistentTraversal extends MapBase<int, int> {
  final Map<int, int> _map = {1: 2, 3: 4};
  @override
  int? operator [](Object? key) => _map[key];
  @override
  void operator []=(int key, int value) => _map[key] = value;
  @override
  void clear() => _map.clear();
  @override
  Iterable<int> get keys => _map.keys;
  @override
  int? remove(Object? key) => _map.remove(key);
  @override
  void forEach(void Function(int, int) action) {
    _map.forEach((key, value) => action(key, value + 1));
  }
}

void main() {
  final map = InconsistentTraversal();
  const base = before.MapEquality<int, int>();
  const candidate = after.MapEquality<int, int>();
  final a = base.hash(map);
  final b = candidate.hash(map);
  if (a == b ||
      a != base.hash({1: 2, 3: 4}) ||
      b != candidate.hash({1: 3, 3: 5})) {
    throw StateError('unexpected results');
  }
  print('inconsistent forEach changes hash: baseline=$a candidate=$b');
}
