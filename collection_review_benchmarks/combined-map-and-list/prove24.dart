import 'base/pkgs/collection/lib/src/iterable_extensions.dart' as before;
import 'pr24/pkgs/collection/lib/src/iterable_extensions.dart' as after;

void main() {
  var visits = 0;
  final mapped = List<int>.generate(100000, (i) => i).map((i) {
    visits++;
    return i;
  });
  final oldValue = before.IterableExtension(mapped).lastOrNull;
  final oldVisits = visits;
  visits = 0;
  final newValue = after.IterableExtension(mapped).lastOrNull;
  if (oldValue != newValue || oldVisits != 1 || visits != 100000) {
    throw StateError('unexpected results');
  }
  print(
    'result=$newValue baselineTransforms=$oldVisits candidateTransforms=$visits',
  );
}
