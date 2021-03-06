// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that when a deferred import fails to load, it is possible to retry.

import "../libs/deferred_fail_and_retry_lib.dart" deferred as lib;
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:js" as js;

/*element: main:OutputUnit(main, {})*/
main() {
  // We patch document.body.appendChild to change the script src on first
  // invocation.
  js.context.callMethod("eval", [
    """
    if (self.document) {
      oldAppendChild = document.body.appendChild;
      document.body.appendChild = function(element) {
        element.src = "non_existing.js";
        document.body.appendChild = oldAppendChild;
        document.body.appendChild(element);
      }
    }
    if (self.load) {
      oldLoad = load;
      load = function(uri) {
        load = oldLoad;
        load("non_existing.js");
      }
    }
  """
  ]);

  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.fail("Library should not have loaded");
  }, onError: (error) {
    lib.loadLibrary().then((_) {
      Expect.equals("loaded", lib.foo());
    }, onError: (error) {
      Expect.fail("Library should have loaded this time");
    }).whenComplete(() {
      asyncEnd();
    });
  });
}
