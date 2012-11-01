// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test("doesn't update a locked Git package with a new compatible "
      "constraint", () {
    ensureGit();

    git('foo.git', [
      libDir('foo', 'foo 1.0.0'),
      libPubspec("foo", "1.0.0")
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1.0.0";')
      ])
    ]).scheduleValidate();

    git('foo.git', [
      libDir('foo', 'foo 1.0.1'),
      libPubspec("foo", "1.0.1")
    ]).scheduleCommit();

    appDir([{"git": "../foo.git", "version": ">=1.0.0"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1.0.0";')
      ])
    ]).scheduleValidate();

    run();
  });
}
