import 'base/pkgs/collection/lib/src/combined_wrappers/combined_list.dart'
    as baseline;
import 'pr18/pkgs/collection/lib/src/combined_wrappers/combined_list.dart'
    as candidate;

class OnCompare {
  final void Function() action;
  OnCompare(this.action);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    action();
    return false;
  }

  @override
  int get hashCode => 0;
}

int find(bool changed) {
  final child = <Object>[];
  child.add(OnCompare(() => child.add('target')));
  final children = <List<Object>>[child];
  final list = changed
      ? candidate.CombinedListView(children)
      : baseline.CombinedListView(children);
  return list.indexOf('target');
}

int findLast(bool changed) {
  final first = <Object>['target'];
  final children = <List<Object>>[
    first,
    [OnCompare(() => first.add('new'))],
  ];
  final list = changed
      ? candidate.CombinedListView(children)
      : baseline.CombinedListView(children);
  return list.lastIndexOf('target');
}

void main() {
  final results = [find(false), find(true), findLast(false), findLast(true)];
  if (results.toString() != '[1, -1, 0, -1]') {
    throw StateError('unexpected results: $results');
  }
  print('indexOf base/candidate: ${results[0]}/${results[1]}');
  print('lastIndexOf base/candidate: ${results[2]}/${results[3]}');
}
