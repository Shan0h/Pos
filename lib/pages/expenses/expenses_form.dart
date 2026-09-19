import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos/controller/expenses_controller.dart';
import 'package:pos/model/expenses_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:pos/utils/extension.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const List<String> kExpenseCategories = [
  'Ingredients & Raw Materials',
  'Packaging & Containers',
  'Utilities & Bills',
  'Equipment & Maintenance',
  'Staff Meals & Refreshments',
  'Other / Custom',
];

class ExpensesForm extends HookWidget {
  final ShadSheetSide? side;
  const ExpensesForm({super.key, this.side});

  @override
  Widget build(BuildContext context) {
    final expensesFormKey = useMemoized(GlobalKey<FormState>.new);
    final title = useTextEditingController();
    final storeName = useTextEditingController();
    final selectedCategory = useState<String>(kExpenseCategories.first);
    final customCategory = useTextEditingController();
    final note = useTextEditingController();
    final date = useState<DateTime>(DateTime.now());
    final amount = useTextEditingController();
    final imagePath = useState<String?>(null);
    final isSaving = useState<bool>(false);

    Future<void> pickImage() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.single;

        final appDir = await getApplicationDocumentsDirectory();
        final receiptsDir = Directory(p.join(appDir.path, 'expense_receipts'));
        if (!await receiptsDir.exists()) {
          await receiptsDir.create(recursive: true);
        }

        final ext = file.name.contains('.') ? p.extension(file.name) : '.jpg';
        final newFileName = 'expense_${DateTime.now().millisecondsSinceEpoch}$ext';
        final targetPath = p.join(receiptsDir.path, newFileName);

        if (file.path != null && await File(file.path!).exists()) {
          await File(file.path!).copy(targetPath);
        } else if (file.bytes != null) {
          await File(targetPath).writeAsBytes(file.bytes!);
        }

        imagePath.value = targetPath;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to attach photo: $e')),
          );
        }
      }
    }

    return SafeArea(
      child: ShadSheet(
        title: const Text('New Expense'),
        description: const Text('Record purchases, supplier costs, and shop expenses'),
        actions: [
          ShadButton(
            onPressed: isSaving.value
                ? null
                : () async {
                    if (expensesFormKey.currentState!.validate()) {
                      isSaving.value = true;
                      try {
                        final parsedAmount = double.tryParse(amount.text.trim()) ?? 0.0;
                        final categoryText = selectedCategory.value == 'Other / Custom'
                            ? (customCategory.text.trim().isEmpty
                                ? 'Other'
                                : customCategory.text.trim())
                            : selectedCategory.value;

                        final newItem = ExpensesModel(
                          id: DateTime.now().microsecondsSinceEpoch,
                          title: title.text.trim(),
                          storeName: storeName.text.trim().isEmpty ? null : storeName.text.trim(),
                          category: categoryText,
                          amount: parsedAmount.round(),
                          amountExact: parsedAmount,
                          note: note.text.trim().isEmpty ? null : note.text.trim(),
                          imagePath: imagePath.value,
                          createdAt: date.value,
                        );

                        await expensesService.addExpenses(newItem);
                        expensesController.expenses.refresh();
                        if (context.mounted) context.pop();
                      } finally {
                        isSaving.value = false;
                      }
                    }
                  },
            child: Text(isSaving.value ? 'Saving...' : 'Save Expense'),
          ),
        ],
        child: Form(
          key: expensesFormKey,
          child: SingleChildScrollView(
            child: SizedBox(
              width: side == ShadSheetSide.bottom || side == ShadSheetSide.top
                  ? MediaQuery.sizeOf(context).width
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShadInputFormField(
                    controller: title,
                    validator: (val) =>
                        val.trim().isEmpty ? 'Item or title is required' : null,
                    label: const Text('Item / Expense Title *'),
                    placeholder: const Text('ex. Cooking Oil 5kg, Paper Cups, Ice'),
                  ),
                  const SizedBox(height: 10),
                  ShadInputFormField(
                    controller: storeName,
                    label: const Text('Store / Merchant'),
                    placeholder: const Text('ex. Lotus\'s, NSK, MR DIY, Eco-Shop'),
                  ),
                  const SizedBox(height: 10),
                  Text('Category',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.secondaryTextColor,
                      )),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: kExpenseCategories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) selectedCategory.value = val;
                    },
                  ),
                  if (selectedCategory.value == 'Other / Custom') ...[
                    const SizedBox(height: 10),
                    ShadInputFormField(
                      controller: customCategory,
                      label: const Text('Custom Category Name'),
                      placeholder: const Text('ex. License Renewal, Pest Control'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: ShadInputFormField(
                          controller: amount,
                          validator: (val) {
                            if (val.trim().isEmpty) return 'Amount is required';
                            final parsed = double.tryParse(val.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter valid amount';
                            }
                            return null;
                          },
                          label: const Text('Amount (RM) *'),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 4, right: 6),
                            child: Text('RM',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          placeholder: const Text('0.00'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: ShadButton.outline(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: date.value,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              date.value = pickedDate;
                            }
                          },
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.calendar_today, size: 16),
                          ),
                          child: Text(dateWithoutTime.format(date.value)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ShadInputFormField(
                    controller: note,
                    label: const Text('Note / Details'),
                    maxLines: 2,
                    placeholder: const Text('ex. Purchased for weekly stock'),
                  ),
                  const SizedBox(height: 14),
                  Text('Receipt / Bill Photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.secondaryTextColor,
                      )),
                  const SizedBox(height: 6),
                  if (imagePath.value == null)
                    ShadButton.outline(
                      width: double.infinity,
                      onPressed: pickImage,
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.add_a_photo, size: 18),
                      ),
                      child: const Text('Attach Receipt Photo'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.panelBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              File(imagePath.value!),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Receipt attached',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  p.basename(imagePath.value!),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.secondaryTextColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: pickImage,
                            tooltip: 'Change Photo',
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                          IconButton(
                            onPressed: () => imagePath.value = null,
                            tooltip: 'Remove Photo',
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 18),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
