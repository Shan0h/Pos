import 'package:pos/controller/store_controller.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/pages/drawer.dart';
import 'package:pos/service/database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class Store extends StatefulWidget {
  const Store({super.key});

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> {
  final _storeFormKey = GlobalKey<FormState>();
  TextEditingController title = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController footer = TextEditingController();
  TextEditingController subFooter = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = storeController.store.value.value;
    title.text = t?.title ?? '';
    description.text = t?.description ?? '';
    phone.text = t?.phone ?? '';
    footer.text = t?.footer ?? '';
    subFooter.text = t?.subFooter ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final store = storeController.store.watch(context);
    final theme = ShadTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Information'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (item) async {
              if (item == 'sync') {
                Database().syncStore();
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
      body: Form(
        key: _storeFormKey,
        child: store.map(
          data: (t) {


            return SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      ShadCard(
                      width: 500,
                      title: Text('Store Settings', style: theme.textTheme.h4),
                      description: const Text(
                          'Configure your store receipt details and contact info'),
                      footer: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ShadButton(
                            child: const Text('Save'),
                            onPressed: () {
                              if (_storeFormKey.currentState!.validate()) {
                                if (store.value != null) {
                                  final val = StoreModel(
                                    id: store.value!.id,
                                    title: title.text,
                                    description: description.text,
                                    phone: phone.text,
                                    footer: footer.text,
                                    subFooter: subFooter.text,
                                  );
                                  Database().addStore(val).whenComplete(
                                    () {
                                      storeController.store.refresh();
                                      if (context.mounted) {
                                        context.pop();
                                        ShadToaster.of(context).show(
                                          const ShadToast(
                                            backgroundColor: Colors.green,
                                            description: Text(
                                              'Store Success Updated',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                } else {
                                  final val = StoreModel(
                                    id: DateTime.now().microsecondsSinceEpoch,
                                    title: title.text,
                                    description: description.text,
                                    phone: phone.text,
                                    footer: footer.text,
                                    subFooter: subFooter.text,
                                  );
                                  Database().addStore(val).whenComplete(
                                    () {
                                      storeController.store.refresh();
                                      if (context.mounted) {
                                        context.pop();
                                        ShadToaster.of(context).show(
                                          const ShadToast(
                                            backgroundColor: Colors.green,
                                            description: Text(
                                              'Store Success Saved',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ShadInputFormField(
                              label: const Text('Title Store'),
                              placeholder: const Text('Store'),
                              controller: title,
                              validator: (v) {
                                if (v.length < 2) {
                                  return 'Title must be at least 2 characters.';
                                }
                                return null;
                              },
                            ),
                            ShadInputFormField(
                              label: const Text('Description/Location'),
                              placeholder: const Text('Batu Pahat, Johor'),
                              controller: description,
                              maxLines: 2,
                              validator: (v) {
                                if (v.length < 2) {
                                  return 'Description must be at least 2 characters.';
                                }
                                return null;
                              },
                            ),
                            ShadInputFormField(
                              label: const Text('Phone'),
                              placeholder:
                                  const Text('Whatsapp/Phone: +60123456789'),
                              controller: phone,
                              validator: (v) {
                                if (v.length < 2) {
                                  return 'Phone must be at least 2 characters.';
                                }
                                return null;
                              },
                            ),
                            ShadInputFormField(
                              label: const Text('Footer'),
                              placeholder:
                                  const Text('Thanks for visiting us!'),
                              controller: footer,
                            ),
                            ShadInputFormField(
                              label: const Text('Sub Footer'),
                              placeholder:
                                  const Text('Follow us on social media'),
                              controller: subFooter,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          error: (error, st) => Text('$error'),
          loading: () => const Center(
            child: Text('Loading...'),
          ),
        ),
      ),
    );
  }
}
