import 'package:flutter/material.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/utils/extension.dart';

/// Netflix-style profile card for a staff member. Shared by the startup
/// "Who's working?" picker and the mid-session switch-account sheet.
class StaffProfileCard extends StatelessWidget {
  final UserModel staff;
  final VoidCallback onTap;

  /// Slightly larger tiles on the startup picker.
  final bool large;

  const StaffProfileCard({
    super.key,
    required this.staff,
    required this.onTap,
    this.large = false,
  });

  bool get _isActive => staff.status && !staff.isDeleted;

  @override
  Widget build(BuildContext context) {
    final size = large ? 88.0 : 72.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: _isActive ? 1.0 : 0.45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5E3C).withValues(alpha: 0.15),
                    border: Border.all(
                      color: const Color(0xFF8B5E3C),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      staff.nama.isNotEmpty ? staff.nama[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5E3C),
                      ),
                    ),
                  ),
                ),
                // Badges
                if (!_isActive)
                  Positioned(
                    bottom: -4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (!_hasPin)
                  Positioned(
                    bottom: -4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7A86E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'No passcode',
                          style: TextStyle(
                            color: context.isDarkMode
                                ? const Color(0xFF1A1410)
                                : const Color(0xFF5D3A1A),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: large ? 128 : 112,
              child: Text(
                staff.nama,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: large ? 15 : 13,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              staff.keterangan ?? 'Staff',
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasPin => staff.pin != null && staff.pin!.trim().isNotEmpty;
}
