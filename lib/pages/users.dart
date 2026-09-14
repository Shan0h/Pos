import 'package:pos/controller/user_controller.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/pages/users/user_list.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class Users extends StatelessWidget {
  const Users({super.key});

  @override
  Widget build(BuildContext context) {
    final users = userController.users.watch(context);
    final noPinCount = (users.value ?? const <UserModel>[])
        .where((u) => u.status && !u.isDeleted)
        .where((u) => u.pin == null || u.pin!.trim().isEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: context.panelBackground,
        foregroundColor: context.appTextColor,
        centerTitle: false,
        actions: [
          ShadButton.ghost(
            onPressed: () {
              userController.users.refresh();
            },
            icon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.refresh,
                size: 16,
              ),
            ),
            child: const Text('Refresh'),
          ),
          PopupMenuButton<String>(
            onSelected: (item) async {
              if (item == 'sync') {
                userService
                    .syncUsers()
                    .whenComplete(() => userController.users.refresh());
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'sync',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Sync'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (noPinCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ShadAlert(
                iconSrc: Icons.info_outline,
                title: Text('$noPinCount staff without passcode'),
                description: const Text(
                    'Profiles without a passcode can sign in with one tap on the "Who\'s working?" screen. Edit a user to set their 4-digit passcode.'),
              ),
            ),
          const Expanded(child: UserList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.panelBackground,
        foregroundColor: context.appTextColor,
        onPressed: () => context.push('/users/form'),
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
    );
  }
}
