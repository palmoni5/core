// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('the first map wins when its value is null', () {
    final view = CombinedMapView<String, int?>([
      {'key': null},
      {'key': 42},
    ]);

    expect(view.containsKey('key'), isTrue);
    expect(view['key'], isNull);
  });

  test('a null key does not shadow keys in later maps', () {
    final view = CombinedMapView<String?, int?>([
      {null: null},
      {'key': 42},
    ]);

    expect(view['key'], 42);
    expect(view[null], isNull);
  });
}
