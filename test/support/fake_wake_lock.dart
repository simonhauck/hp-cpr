import 'package:flutter_test/flutter_test.dart';

import 'package:hp_cpr/core/wake_lock.dart';

class FakeWakeLock implements WakeLock {
  bool enabled = false;
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enabled = true;
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    enabled = false;
    disableCalls++;
  }
}
