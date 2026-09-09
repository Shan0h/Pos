import 'package:pos/controller/auth_controller.dart';
import 'package:pos/controller/theme_controller.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:pos/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos/pages/pos_modern/owner_pin_dialog.dart';

final isOwnerUnlocked = signal(false);

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = Supabase.instance.client.auth.currentUser;
    final auth = authController.customer.watch(context);
    final themeMode = themeController.mode.watch(context);
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF3E2723)
                      : const Color(0xFF8B5E3C)),
              accountName: Text(
                  '${auth.value?.user.value?.nama ?? "Cashier"} - ${auth.value?.user.value?.keterangan ?? "Role"}',
                  style: ShadTheme.of(context).textTheme.h3),
              accountEmail: Text(user?.email ?? '',
                  style: ShadTheme.of(context).textTheme.muted),
              currentAccountPictureSize: const Size(200, 80),
              currentAccountPicture: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POS',
                    style: ShadTheme.of(context).textTheme.h1,
                  ),
                  Text(
                    dateWithTime.format(DateTime.now()),
                    style: ShadTheme.of(context).textTheme.small,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Point of Sale (POS)'),
              leading: const Icon(Icons.point_of_sale),
              onTap: () => context.go('/'),
            ),
            const Divider(),
            if (!isOwnerUnlocked.watch(context))
              ListTile(
                title: const Text('Owner Management'),
                leading: const Icon(Icons.admin_panel_settings),
                onTap: () async {
                  final success = await OwnerPinDialog.show(context);
                  if (success) {
                    isOwnerUnlocked.value = true;
                  }
                },
              )
            else ...[
              ListTile(
                title: const Text('Lock Owner Mode'),
                leading: const Icon(Icons.lock),
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () {
                  isOwnerUnlocked.value = false;
                },
              ),
              ListTile(
                title: const Text('Theme Mode'),
                subtitle: Text(themeController.labelFor(themeMode)),
                leading: const Icon(Icons.dark_mode),
                trailing: PopupMenuButton<ThemeMode>(
                  initialValue: themeMode,
                  onSelected: themeController.setMode,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Report'),
                leading: const Icon(Icons.home_repair_service_outlined),
                onTap: () => context.push('/report'),
              ),
              ListTile(
                title: const Text('Inventory'),
                leading: const Icon(Icons.inventory),
                onTap: () => context.push('/inventory'),
              ),
              ListTile(
                title: const Text('Expenses'),
                leading: const Icon(Icons.monetization_on),
                onTap: () {
                  context.push('/expenses');
                },
              ),
              ListTile(
                title: const Text('Users'),
                leading: const Icon(Icons.person_2),
                onTap: () => context.push('/users'),
              ),
              ListTile(
                title: const Text('Customer'),
                leading: const Icon(Icons.people),
                onTap: () {
                  context.push('/customer');
                },
              ),
              ListTile(
                title: const Text('Salaries'),
                leading: const Icon(Icons.account_balance),
                onTap: () {
                  context.push('/salaries');
                },
              ),
              ListTile(
                title: const Text('Account'),
                leading: const Icon(Icons.account_circle),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (item) async {
                    if (item == 'restore') {
                      ShadToaster.of(context).show(
                        ShadToast(
                          title: const Text('Restore Backup?'),
                          description:
                              const Text('Please pick isar file to restore'),
                           action: ShadButton.outline(
                             child: const Text('Select'),
                             onPressed: () async {
                               final toaster = ShadToaster.of(context);
                               bool success = await database.restoreDB();
                               if (success) {
                                toaster.show(
                                  const ShadToast(
                                    title: Text('Restore Database Success!'),
                                    description: Text('Please make sure all data is imported'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    } else if (item == 'login') {
                      context.pop();
                      context.push('/login');
                    } else if (item == 'backup') {
                      final toaster = ShadToaster.of(context);
                      context.pop();
                      
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Backing up database...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      
                      bool success = await database.createBackUp();
                      
                      if (context.mounted) Navigator.pop(context); // close dialog
                      
                      if (success) {
                        toaster.show(
                          const ShadToast(
                            title: Text('Backup Database Success!'),
                            description: Text('All your data on selected folder'),
                          ),
                        );
                      }
                    } else if (item == 'clear') {
                      context.pop();
                      showShadDialog(
                        context: context,
                        builder: (context) => ShadDialog.alert(
                          title: const Text('Are you absolutely sure?'),
                          description: const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'This action cannot be undone. This will permanently delete your data.',
                            ),
                          ),
                          actions: [
                            ShadButton.outline(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            ShadButton(
                              child: const Text('Continue'),
                              onPressed: () async {
                                await database.clearAllData().whenComplete(() {
                                  if (context.mounted) {
                                    Navigator.of(context).pop(true);
                                    context.go('/');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    } else if (item == 'logout') {
                      context.pop();
                      await Supabase.instance.client.auth.signOut();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'restore',
                      child: Text('Restore'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'backup',
                      child: Text('Backup'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'clear',
                      child: Text('Clear/Reset'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'store',
                      child: Text('Store'),
                    ),
                    if (user == null)
                      const PopupMenuItem<String>(
                        value: 'login',
                        child: Text('Login'),
                      )
                    else ...[
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ]
                  ],
                ),
                onTap: () => context.go('/home'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
