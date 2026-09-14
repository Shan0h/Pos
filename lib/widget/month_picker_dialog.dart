import 'package:flutter/material.dart';

/// A month picker dialog: pick a year (‹ ›) then a month (3x4 grid).
///
/// Returns the first day of the picked month (DateTime(year, month)) or
/// null when dismissed. Future months are disabled — exporting a future
/// month is meaningless.
class MonthPickerDialog extends StatefulWidget {
  const MonthPickerDialog({super.key});

  static Future<DateTime?> show(BuildContext context) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => const MonthPickerDialog(),
    );
  }

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  bool _isCurrentMonth(int month) =>
      DateTime.now().year == _year && DateTime.now().month == month;

  bool _isFutureMonth(int month) =>
      _year > DateTime.now().year ||
      (_year == DateTime.now().year && month > DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year--),
          ),
          Expanded(
            child: Text(
              '$_year',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            // Can't navigate into the future.
            onPressed:
                _year >= DateTime.now().year ? null : () => setState(() => _year++),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: List.generate(12, (index) {
            final month = index + 1;
            final isFuture = _isFutureMonth(month);
            final isSelected = _isCurrentMonth(month);
            return OutlinedButton(
              onPressed: isFuture
                  ? null
                  : () => Navigator.of(context).pop(DateTime(_year, month)),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isSelected ? const Color(0xFF8B5E3C) : Colors.grey.shade700,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF8B5E3C)
                      : (isFuture
                          ? Colors.grey.withValues(alpha: 0.3)
                          : Colors.grey.shade400),
                ),
              ),
              child: Text(
                _monthNames[index],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
