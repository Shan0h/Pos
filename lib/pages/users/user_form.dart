import 'package:pos/controller/user_controller.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class UserForm extends HookWidget {
  UserForm({super.key});

  final statusData = {true: 'Active', false: 'Non Active'};

  final roleData = {
    'User': 'User',
    'Admin': 'Admin',
    'Super Admin': 'Super Admin'
  };

  @override
  Widget build(BuildContext context) {
    final user = userController.userSelected.watch(context);
    final editingName = useTextEditingController(text: user?.nama ?? '');
    final editingPin = useTextEditingController(text: user?.pin ?? '');
    final lahirTemp = useTextEditingController(
        text: user?.dob != null ? dateWithoutTime.format(user!.dob!) : '');
    final lahir = useState(user?.dob ?? DateTime.now());
    final status = useState(user?.status ?? true);
    final role = useState(user?.keterangan ?? 'User');
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8))),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadButton.ghost(
                    child: const Text('Close'),
                    onPressed: () => context.pop(),
                  ),
                ),
                ShadInputFormField(
                  controller: editingName,
                  validator: (val) =>
                      val.isEmpty == true ? 'Name is required' : null,
                  label: const Text('Name'),
                  placeholder: const Text('Jhon Doe'),
                ),
                ShadInputFormField(
                  controller: editingPin,
                  label: const Text('Passcode (4 digits)'),
                  placeholder: const Text('1234'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  description: const Text(
                      'Used on the "Who\'s working?" screen. Leave empty to allow one-tap sign-in.'),
                  validator: (val) {
                    final v = val.trim();
                    if (v.isEmpty) return null;
                    if (v.length != 4) return 'Passcode must be exactly 4 digits';
                    if (int.tryParse(v) == null) return 'Digits only';
                    return null;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: user?.dob ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              //DateTime.now() - not to allow to choose before today.
                              lastDate: DateTime(2100));

                          if (pickedDate != null) {
                            lahirTemp.text =
                                dateWithoutTime.format(lahir.value);
                            lahir.value = pickedDate;
                          }
                        },
                        child: ShadInputFormField(
                          controller: lahirTemp,
                          label: const Text('Date of Birth'),
                          placeholder: const Text('24-5-2003'),
                          readOnly: true,
                          enabled: false,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        ShadSelect<bool>(
                          initialValue: user?.status,
                          placeholder: const Text('Select a Status'),
                          options: [
                            ...statusData.entries.map(
                              (e) => ShadOption(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            ),
                          ],
                          onChanged: (bool? value) => status.value = value!,
                          selectedOptionBuilder: (context, value) =>
                              Text(statusData[value]!),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                    Column(
                      children: [
                        ShadSelect<String>(
                          initialValue: user?.keterangan,
                          placeholder: const Text('Select a Role'),
                          options: [
                            ...roleData.entries.map(
                              (e) => ShadOption(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            ),
                          ],
                          onChanged: (String? value) => role.value = value!,
                          selectedOptionBuilder: (context, value) =>
                              Text(roleData[value]!),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user != null)
                          ShadButton.destructive(
                            child: const Text('Delete'),
                            onPressed: () {
                            userService.deleteUser(user.id!).whenComplete(() {
                              userController.users.refresh();
                              if (context.mounted) Navigator.pop(context);
                            });
                          },
                        ),
                      ShadButton(
                        child: const Text('Save changes'),
                        onPressed: () {
                          final pinValue = editingPin.text.trim();
                          final pinInvalid =
                              pinValue.isNotEmpty && (pinValue.length != 4 || int.tryParse(pinValue) == null);
                          if (editingName.text.isEmpty || pinInvalid) {
                            if (pinInvalid && context.mounted) {
                              ShadToaster.of(context).show(
                                const ShadToast(
                                  backgroundColor: Colors.red,
                                  description: Text(
                                      'Passcode must be exactly 4 digits (or left empty).'),
                                ),
                              );
                            }
                            return;
                          } else {
                            if (user != null) {
                              final updateUser = UserModel(
                                id: user.id,
                                nama: editingName.text,
                                dob: lahir.value,
                                status: status.value,
                                keterangan: role.value,
                                masuk: DateTime.now(),
                                createdAt: user.createdAt,
                                updatedAt: user.updatedAt,
                                isDeleted: user.isDeleted,
                                isSynced: user.isSynced,
                                pin: editingPin.text.trim().isEmpty
                                    ? null
                                    : editingPin.text.trim(),
                              );
                              userService
                                  .updateUser(updateUser)
                                  .whenComplete(() {
                                Future.delayed(Durations.short1).then((_) {
                                  userController.users.refresh();
                                  if (context.mounted) context.pop();
                                });
                              });
                            } else {
                              final newUser = UserModel(
                                id: DateTime.now().microsecondsSinceEpoch,
                                nama: editingName.text,
                                dob: lahir.value,
                                status: status.value,
                                keterangan: role.value,
                                masuk: DateTime.now(),
                                createdAt: DateTime.now(),
                                pin: editingPin.text.trim().isEmpty
                                    ? null
                                    : editingPin.text.trim(),
                              );

                              userService.addNewUser(newUser).whenComplete(() {
                                userController.users.refresh();
                                if (context.mounted) context.pop();
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
