import 'package:pos/controller/report_controller.dart';
import 'package:pos/pages/pos_modern/owner_pin_dialog.dart';
import 'package:pos/service/app_services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ReportDeleteDialog extends StatelessWidget {
  final int id;
  const ReportDeleteDialog({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Delete Report'),
      description: const Text(
          "Are you sure to delete this report, this action can't be undo"),
      actions: [
        ShadButton.outline(
            onPressed: () => context.pop(), child: const Text('Cancel')),
        ShadButton(
            onPressed: () async {
              // Owner confirmation via the real store PIN (no more
              // hardcoded 111111 shared password).
              final ok = await OwnerPinDialog.show(context);
              if (!ok) {
                if (context.mounted) {
                  ShadToaster.of(context).show(
                    const ShadToast(
                      description: Text('Delete cancelled'),
                    ),
                  );
                }
                return;
              }
              try {
                await reportService.removePenjualan(id);
                await reportController.report.refresh();
                await reportController.reportToday.refresh();
                await reportController.reportYesterday.refresh();
                await reportController.reportIncome.refresh();
                if (context.mounted) {
                  context.pop(); // close this dialog
                  ShadToaster.of(context).show(
                    const ShadToast(
                      backgroundColor: Color(0xFF8B5E3C),
                      description: Text('Report deleted'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ShadToaster.of(context).show(
                    ShadToast(
                      backgroundColor: Colors.red,
                      description: Text('Failed to delete: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete')),
      ],
    );
  }
}
