import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:pos/service/database.dart';

/// Shared Isar bootstrap for tests.
///
/// The test VM blocks IsarCore's auto-download (all HTTP is mocked), so we
/// load the isar.dll straight from the pub cache — the exact same binary
/// the app ships with.
class TestIsar {
  TestIsar._();

  static bool _initialized = false;

  static Future<void> initializeCore() async {
    if (_initialized) return;
    final dll = File(
      r'C:\Users\Asus\AppData\Local\Pub\Cache\hosted\pub.dev'
      r'\isar_flutter_libs-3.1.0+1\windows\isar.dll',
    );
    await Isar.initializeIsarCore(libraries: {Abi.windowsX64: dll.path});
    _initialized = true;
  }

  /// Opens a throwaway Isar instance with the app's exact schema list.
  static Future<Isar> openTemp() async {
    await initializeCore();
    final tempDir =
        await Directory.systemTemp.createTemp('pos_test_isar');
    final isar = await Isar.open(
      Database.schemas,
      directory: tempDir.path,
      inspector: false,
    );
    return isar;
  }
}
