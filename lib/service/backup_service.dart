import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:pos/service/backup_codec.dart';

/// Result of a backup or restore operation, ready for UI feedback.
class BackupOpResult {
  /// true = operation completed; false = it failed ([error] is set).
  final bool success;

  /// true = the user dismissed the file dialog, nothing was done. The UI
  /// should stay silent (this is NOT an error).
  final bool cancelled;

  /// Short human-readable description of what happened (counts summary on
  /// success, error explanation on failure).
  final String? message;

  const BackupOpResult({
    required this.success,
    this.cancelled = false,
    this.message,
  });
}

/// Orchestrates JSON backup/restore: file dialogs + decoding + calling
/// [BackupCodec]. All DB work goes through [BackupCodec.parse]/[apply] so it
/// is validated BEFORE any data is touched.
class BackupService {
  static const String backupExtension = 'posbackup';

  /// Serializes the whole DB and hands it to the system save dialog.
  ///
  /// Mobile (SAF): the file content is passed as [bytes] and the plugin
  /// writes it — the returned path is a virtual URI that dart:io cannot
  /// touch, same pattern as the PDF export.
  Future<BackupOpResult> createJsonBackup(Isar isar) async {
    try {
      final envelope = await BackupCodec.serialize(isar);
      final json = const JsonEncoder.withIndent('  ').convert(envelope);
      final bytes = utf8.encode(json);

      final stamp = _fileStamp(DateTime.now());
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: 'pos_backup_$stamp.$backupExtension',
        type: FileType.any,
        bytes: bytes,
        lockParentWindow: true,
      );

      if (outputFile == null) {
        return const BackupOpResult(success: false, cancelled: true);
      }

      // Desktop: the plugin only returns a path — verify it actually wrote
      // the bytes and fall back to a plain write for safety.
      if (!Platform.isAndroid && !Platform.isIOS) {
        final target = File(outputFile);
        if (!await target.exists() || await target.length() == 0) {
          await target.writeAsBytes(bytes, flush: true);
        }
      }

      final count = envelope['data'] is Map
          ? (envelope['data'] as Map).values
              .whereType<List>()
              .fold<int>(0, (sum, list) => sum + list.length)
          : 0;
      return BackupOpResult(
        success: true,
        message: 'Backup saved ($count records). Send it to your other '
            'device as a DOCUMENT (not as photo/video) via WhatsApp/Telegram.',
      );
    } catch (e) {
      log('JSON backup failed: $e');
      return BackupOpResult(
        success: false,
        message: 'Backup failed: $e',
      );
    }
  }

  /// Opens the pick dialog, validates the file, and replaces the local DB
  /// with its content — all in one atomic transaction AFTER validation, so a
  /// wrong/corrupt file can never destroy the existing data.
  Future<BackupOpResult> restoreJsonBackup(Isar isar) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select backup file (.posbackup)',
        type: FileType.any,
        // withData is REQUIRED on Android: files picked through SAF (chat
        // apps, cloud providers) often have no readable file path — the
        // content arrives via bytes instead. Backup files are small
        // (KB–MB scale) so loading them into memory is fine.
        withData: true,
        lockParentWindow: true,
      );

      if (result == null || result.files.isEmpty) {
        return const BackupOpResult(success: false, cancelled: true);
      }

      final file = result.files.single;

      // Resolve content: prefer bytes (works for SAF/cloud files), fall
      // back to reading the path when one was provided.
      List<int>? content;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        content = file.bytes!;
      } else if (file.path != null) {
        final f = File(file.path!);
        if (await f.exists()) {
          content = await f.readAsBytes();
        }
      }
      if (content == null) {
        return const BackupOpResult(
          success: false,
          message: 'Could not read the selected file. If it came from '
              'WhatsApp/Telegram, make sure it finished downloading before '
              'selecting it.',
        );
      }

      Map<String, dynamic>? decoded;
      try {
        final text = utf8.decode(content, allowMalformed: false);
        decoded = jsonDecode(text) as Map<String, dynamic>?;
      } on FormatException catch (e) {
        log('Backup file is not valid JSON: $e');
        return const BackupOpResult(
          success: false,
          message: 'This file is not a valid backup. If you sent it via '
              'WhatsApp/Telegram, resend it using Document (file) mode — '
              'sending as photo/video corrupts it.',
        );
      }

      // Full validation + model construction. Throws BackupFormatException
      // with a user-presentable message; nothing has been written yet.
      final backup = BackupCodec.parse(decoded);

      // Single atomic transaction: clear + reinsert + relink.
      await BackupCodec.apply(isar, backup);

      return BackupOpResult(
        success: true,
        message: 'Restored backup${backup.createdAt != null ? ' from '
            '${_dateLabel(backup.createdAt!)}' : ''}: ${backup.summary}.',
      );
    } on BackupFormatException catch (e) {
      return BackupOpResult(success: false, message: e.message);
    } catch (e) {
      log('JSON restore failed: $e');
      return BackupOpResult(
        success: false,
        message: 'Restore failed: $e',
      );
    }
  }

  static String _fileStamp(DateTime time) {
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '${time.year}$m$d-$hh$mm';
  }

  static String _dateLabel(DateTime time) {
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    return '${time.year}-$m-$d';
  }
}
