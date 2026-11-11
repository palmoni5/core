// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('setRange writes relative to the slice, not the backing list', () {
    final values = [9, 8, 7, 6, 5, 4];
    final slice = values.slice(2, 5);

    slice.setRange(1, 3, [100, 101]);

    expect(values, [9, 8, 7, 100, 101, 4]);
    expect(slice, [7, 100, 101]);
  });

  test('sortRange sorts only the requested range within the slice', () {
    final values = [9, 8, 7, 6, 5, 4];
    final slice = values.slice(2, 5);

    slice.sortRange(0, 2, (a, b) => a.compareTo(b));

    expect(values, [9, 8, 6, 7, 5, 4]);
  });

  test('sortRange rejects a range beyond the slice boundary', () {
    final values = [9, 8, 7, 6, 5, 4];
    final slice = values.slice(2, 5);

    expect(() => slice.sortRange(0, 4, (a, b) => a.compareTo(b)),
        throwsRangeError);
    expect(values, [9, 8, 7, 6, 5, 4]);
  });
}
