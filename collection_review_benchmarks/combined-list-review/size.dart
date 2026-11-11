import 'source/combined_list.dart';
void main() {
  final n = DateTime.now().millisecondsSinceEpoch % 7 + 2;
  final list = CombinedListView<int>(List.generate(n, (i) => List.generate(n, (j) => i * n + j)));
  print([list.isEmpty, list.isNotEmpty, list.first, list.last, list.indexOf(n), list.lastIndexOf(n), list.lastIndexOf(n, n)]);
}