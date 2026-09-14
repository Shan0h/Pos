import 'package:flutter/material.dart';
import 'package:pos/controller/auth_controller.dart';
import 'package:pos/controller/user_controller.dart';
import 'package:pos/model/auth_model.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/pages/pos_modern/owner_dashboard_page.dart';
import 'package:pos/pages/pos_modern/owner_pin_dialog.dart';
import 'package:pos/pages/pos_modern/staff_pin_dialog.dart';
import 'package:pos/pages/pos_modern/staff_profile_card.dart';
import 'package:pos/service/app_services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

/// Signs [staff] into the register. Writes the single auth row (update when
/// it exists, insert on first run) and refreshes the auth signal.
Future<void> signInStaff(BuildContext context, UserModel staff) async {
  final auth = authController.customer.peek();
  if (auth.hasValue && auth.value != null) {
    final user = AuthModel()
      ..id = auth.value!.id
      ..user.value = staff;
    await database.changeUser(user);
  } else {
    final user = AuthModel()
      ..user.value = staff
      ..createdAt = DateTime.now();
    await database.loginUser(user);
  }
  authController.customer.refresh();
}

/// Handles the tap on a staff profile: PIN dialog when a passcode is set
/// (max 3 attempts), one-tap sign-in when it isn't, blocked message for
/// inactive profiles. Returns true when the profile was signed in.
Future<bool> handleStaffTap(BuildContext context, UserModel staff) async {
  if (!staff.status || staff.isDeleted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This profile is inactive — ask the owner.'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  final hasPin = staff.pin != null && staff.pin!.trim().isNotEmpty;
  if (hasPin) {
    final ok = await StaffPinDialog.show(
      context,
      title: "Enter ${staff.nama}'s passcode",
      staffName: staff.nama,
      correctPin: staff.pin!.trim(),
    );
    if (!ok) return false;
  }

  await signInStaff(context, staff);
  return true;
}

class StaffPickerPage extends StatefulWidget {
  const StaffPickerPage({super.key});

  @override
  State<StaffPickerPage> createState() => _StaffPickerPageState();
}

class _StaffPickerPageState extends State<StaffPickerPage> {
  bool _refreshed = false;

  @override
  void initState() {
    super.initState();
    // Pick up staff created/edited since the last visit (once).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_refreshed) {
        _refreshed = true;
        userController.users.refresh();
      }
    });
  }

  Future<void> _openOwnerFlow() async {
    final ok = await OwnerPinDialog.show(context);
    // /owner-dashboard is not a go_router route — the rest of the app
    // opens it with a MaterialPageRoute (see POS app-bar Owner button).
    if (ok && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const OwnerDashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersState = userController.users.watch(context);
    final staff =
        (usersState.value ?? const <UserModel>[])..sort((a, b) => a.nama.compareTo(b.nama));
    final activeCount = staff.where((s) => s.status && !s.isDeleted).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3E2723), Color(0xFF1A1410)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, size: 56, color: Color(0xFFD7A86E)),
                  const SizedBox(height: 16),
                  Text(
                    "Who's working?",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your profile to start the register',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  if (usersState.isLoading)
                    const CircularProgressIndicator(color: Color(0xFFD7A86E))
                  else if (activeCount == 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'No staff profiles yet.\nOwner → Users → add staff and set passcodes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Wrap(
                        spacing: 28,
                        runSpacing: 28,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final s in staff)
                            StaffProfileCard(
                              staff: s,
                              large: true,
                              onTap: () async {
                                final signedIn = await handleStaffTap(context, s);
                                if (signedIn && context.mounted) {
                                  context.go('/');
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 48),
                  // Owner tile
                  InkWell(
                    onTap: _openOwnerFlow,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD7A86E),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.key,
                              size: 20, color: Color(0xFFD7A86E)),
                          const SizedBox(width: 10),
                          Text(
                            'Owner',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
