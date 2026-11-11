// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('cast exposes original keys and values, not internal map entries', () {
    final map = CanonicalizedMap<int, String, String>(int.parse)
      ..['001'] = 'first';
    final view = map.cast<Object, Object>();

    expect(view.keys, ['001']);
    expect(view.values, ['first']);
    expect(view['01'], 'first');
  });

  test('cast delegates writes and removals through canonicalization', () {
    final map = CanonicalizedMap<int, String, String>(int.parse);
    final view = map.cast<Object, Object>();

    view['002'] = 'second';
    expect(map['2'], 'second');
    expect(view.remove('02'), 'second');
    expect(map, isEmpty);
  });
}
