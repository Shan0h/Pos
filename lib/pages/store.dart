import 'package:pos/controller/store_controller.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/extension.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  TextEditingController ownerPin = TextEditingController();
  String? qrDuitNow1;
  String? qrDuitNow2;

  /// Guard so controllers are seeded exactly once, from the first loaded
  /// store value (never from the cold-start null state).
  bool _controllersSeeded = false;

  void _seedControllers(StoreModel? t) {
    if (_controllersSeeded) return;
    _controllersSeeded = true;
    title.text = t?.title ?? '';
    description.text = t?.description ?? '';
    phone.text = t?.phone ?? '';
    footer.text = t?.footer ?? '';
    subFooter.text = t?.subFooter ?? '';
    ownerPin.text = t?.ownerPin ?? '1234';
    qrDuitNow1 = t?.qrDuitNow1;
    qrDuitNow2 = t?.qrDuitNow2;
  }

  @override
  void initState() {
    super.initState();
    // Seed immediately when the signal already resolved (fast path);
    // otherwise the data: branch seeds it once the signal resolves.
    // (Never seed from the cold-start loading state.)
    final state = storeController.store.peek();
    if (state is AsyncData<StoreModel?>) {
      _seedControllers(state.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = storeController.store.watch(context);
    final theme = ShadTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        backgroundColor: context.panelBackground,
        foregroundColor: context.appTextColor,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (item) async {
              if (item == 'sync') {
                storeService.syncStore();
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
            // Seed controllers once real data arrives (covers the
            // cold-open case where initState read a loading signal).
            _seedControllers(t);

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
                            onPressed: () async {
                              if (_storeFormKey.currentState!.validate()) {
                                if (store.value != null) {
                                  final val = StoreModel(
                                    id: store.value!.id,
                                    title: title.text,
                                    description: description.text,
                                    phone: phone.text,
                                    footer: footer.text,
                                    subFooter: subFooter.text,
                                    ownerPin: ownerPin.text,
                                     qrDuitNow1: qrDuitNow1,
                                     qrDuitNow2: qrDuitNow2,
                                   );
                                   await storeService.addStore(val);
                                   await storeService.syncStore();
                                   await storeController.store.refresh();
                                   if (context.mounted) {
                                     ShadToaster.of(context).show(
                                       const ShadToast(
                                         backgroundColor: Colors.green,
                                         description: Text(
                                           'Store Success Updated',
                                           style: TextStyle(color: Colors.white),
                                         ),
                                       ),
                                     );
                                   }
                                 } else {
                                   final val = StoreModel(
                                     id: DateTime.now().microsecondsSinceEpoch,
                                     title: title.text,
                                     description: description.text,
                                     phone: phone.text,
                                     footer: footer.text,
                                     subFooter: subFooter.text,
                                     ownerPin: ownerPin.text,
                                     qrDuitNow1: qrDuitNow1,
                                     qrDuitNow2: qrDuitNow2,
                                   );
                                   await storeService.addStore(val);
                                   await storeService.syncStore();
                                  await storeController.store.refresh();
                                  if (context.mounted) {
                                    ShadToaster.of(context).show(
                                      const ShadToast(
                                        backgroundColor: Colors.green,
                                        description: Text(
                                          'Store Success Saved',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  }
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
                            ShadInputFormField(
                              label: const Text('Owner Dashboard PIN (4 Digits)'),
                              placeholder: const Text('1234'),
                              controller: ownerPin,
                              maxLength: 4,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v.length != 4) {
                                  return 'PIN must be exactly 4 digits.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text('QR DuitNow (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildQrUploader(1, qrDuitNow1)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildQrUploader(2, qrDuitNow2)),
                              ],
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

  Widget _buildQrUploader(int index, String? currentBase64) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFFF5EDE4),
            border: Border.all(color: const Color(0xFFD7CCC8)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: currentBase64 != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(base64Decode(currentBase64), fit: BoxFit.contain),
                )
              : const Center(
                  child: Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
                ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload),
          label: Text(currentBase64 == null ? 'Upload QR $index' : 'Ganti QR $index'),
          onPressed: () => _pickQrImage(index),
        ),
        if (currentBase64 != null)
          TextButton(
            onPressed: () {
              setState(() {
                if (index == 1) qrDuitNow1 = null;
                if (index == 2) qrDuitNow2 = null;
              });
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Future<void> _pickQrImage(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        // Simple size check (limit to ~5MB)
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image is too large!')),
            );
          }
          return;
        }

        final base64String = base64Encode(bytes);
        setState(() {
          if (index == 1) qrDuitNow1 = base64String;
          if (index == 2) qrDuitNow2 = base64String;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
}
