import 'package:pos/controller/user_controller.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/pages/pos_modern/owner_dashboard_page.dart';
import 'package:pos/pages/pos_modern/owner_pin_dialog.dart';
import 'package:pos/pages/pos_modern/staff_picker_page.dart'
    show handleStaffTap;
import 'package:pos/pages/pos_modern/staff_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

/// "Switch staff" sheet — same Netflix-style grid as the startup picker.
/// Signing in as another staff member keeps the current cart (shift
/// handover) and simply closes the sheet.
class UsersSheet extends StatelessWidget {
  const UsersSheet({super.key, this.side});

  final ShadSheetSide? side;

  @override
  Widget build(BuildContext context) {
    final users = userController.users.watch(context);
    final staff = (users.value ?? const <UserModel>[])
      ..sort((a, b) => a.nama.compareTo(b.nama));

    return SafeArea(
      child: ShadSheet(
        title: const Text('Switch Staff'),
        description: const Text(
            'Pick a profile to continue as. The current order stays in the cart.'),
        child: SizedBox(
          width: side == ShadSheetSide.bottom || side == ShadSheetSide.top
              ? MediaQuery.sizeOf(context).width
              : null,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: users.value == null
                  ? const Text('Loading profiles...')
                  : Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final s in staff)
                          StaffProfileCard(
                            staff: s,
                            onTap: () async {
                              final signedIn =
                                  await handleStaffTap(context, s);
                              if (signedIn && context.mounted) {
                                context.pop();
                              }
                            },
                          ),
                        // Owner tile (same as startup picker)
                        InkWell(
                          onTap: () async {
                            final ok = await OwnerPinDialog.show(context);
                            if (ok && context.mounted) {
                              Navigator.pop(context); // close the sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const OwnerDashboardPage()),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD7A86E),
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.key,
                                    size: 18, color: Color(0xFFD7A86E)),
                                SizedBox(width: 8),
                                Text(
                                  'Owner',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFFD7A86E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
