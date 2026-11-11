// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('lookup continues past a nullable set without the requested key', () {
    final union = UnionSet<String?>.from([
      <String?>{null},
      <String?>{'target'},
    ]);

    expect(union.contains('target'), isTrue);
    expect(union.lookup('target'), 'target');
    expect(union.lookup(null), isNull);
  });

  test('lookup retains the first matching object after a null set', () {
    final value = Object();
    final union = UnionSet<Object?>.from([
      <Object?>{null},
      <Object?>{value},
    ]);

    expect(union.lookup(value), same(value));
  });
}
