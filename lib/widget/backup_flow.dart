import 'package:flutter/material.dart';
import 'package:pos/service/app_refresh_service.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/service/backup_service.dart';

/// Shared Backup / Restore flows used by both entry points (drawer "Account"
/// menu and the Owner Dashboard settings menu).
///
/// Design notes:
/// - Restore shows a real modal dialog (the old drawer showed a transient
///   toast with a small "Select" button that auto-dismissed after seconds —
///   on a phone that looked like "nothing happens").
/// - Every step reports back to the user: progress overlay while working,
///   success summary, or the concrete failure reason.
/// - After a successful restore all screen-driving signals are reloaded so
///   the restored data shows up without an app restart.
class BackupFlow {
  BackupFlow._();

  static final BackupService _backupService = BackupService();

  // ---------------------------------------------------------------------------
  // BACKUP (export JSON)
  // ---------------------------------------------------------------------------

  static Future<void> exportBackup(BuildContext context) async {
    // Capture before any await (use_build_context_synchronously).
    final messenger = ScaffoldMessenger.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    final isar = database.isar;

    final loading = _makeLoading('Backing up database...');
    overlay.insert(loading);
    BackupOpResult result;
    try {
      result = await _backupService.createJsonBackup(isar);
    } finally {
      if (loading.mounted) loading.remove();
    }

    if (result.cancelled) return; // user dismissed the save dialog

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.success
            ? (result.message ?? 'Backup saved!')
            : (result.message ?? 'Backup failed')),
        backgroundColor: result.success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RESTORE (import JSON — primary, validated & atomic)
  // ---------------------------------------------------------------------------

  static Future<void> restoreBackup(BuildContext context) async {
    final confirmed = await _confirmRestore(context, isLegacy: false);
    if (confirmed != true || !context.mounted) return;

    // Capture before any await (use_build_context_synchronously).
    final messenger = ScaffoldMessenger.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    final isar = database.isar;

    final loading = _makeLoading('Restoring backup...');
    overlay.insert(loading);
    BackupOpResult result;
    try {
      result = await _backupService.restoreJsonBackup(isar);
    } finally {
      if (loading.mounted) loading.remove();
    }

    if (result.cancelled) return; // user dismissed the pick dialog

    if (result.success) {
      // Every screen renders from in-memory signals — reload them all so the
      // restored data (menus, accounts, orders, reports) shows up without an
      // app restart.
      await appRefreshService.reloadAll();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Restore success! ${result.message ?? ''}'
            : (result.message ?? 'Restore failed')),
        backgroundColor: result.success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RESTORE (legacy .isar file swap — kept for old backups)
  // ---------------------------------------------------------------------------

  static Future<void> restoreLegacyIsar(BuildContext context) async {
    final confirmed = await _confirmRestore(context, isLegacy: true);
    if (confirmed != true || !context.mounted) return;

    // Capture before any await (use_build_context_synchronously).
    final messenger = ScaffoldMessenger.of(context);

    bool success = false;
    String? restoreError;
    try {
      success = await database.restoreDB();
    } catch (e) {
      restoreError = e.toString();
    }

    if (success) {
      await appRefreshService.reloadAll();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Restore success! Data from the backup file is now '
              'active. If anything looks stale, restart the app once.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (restoreError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Restore failed: $restoreError'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Modal confirmation for restore — restores REPLACE ALL local data, so
  /// the user must confirm explicitly. Returns true when approved.
  static Future<bool?> _confirmRestore(
    BuildContext context, {
    required bool isLegacy,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isLegacy
            ? 'Restore legacy Isar backup?'
            : 'Restore from backup?'),
        content: Text(isLegacy
            ? 'This replaces ALL data on this device with an older-style '
                '.isar backup file. Use this only for backups made before '
                'the app update.'
            : 'This replaces ALL data on this device with the data from the '
                'backup file (menus, sales, staff, customers, expenses, '
                'salaries and store settings).\n\nPick a .posbackup file '
                'that was created by the Backup feature on your other '
                'device.\n\nTip: if the file was sent via WhatsApp/Telegram, '
                'send/receive it as a Document (file), not as a photo/video.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pick backup file'),
          ),
        ],
      ),
    );
  }

  /// Non-dismissible progress overlay. Caller must [remove] it when done.
  static _LoadingOverlay _makeLoading(String label) => _LoadingOverlay(label);
}

/// Full-screen modal barrier + spinner shown during backup/restore file IO.
class _LoadingOverlay extends OverlayEntry {
  _LoadingOverlay(String label)
      : super(
          builder: (context) => PopScope(
            canPop: false,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(label),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
}
