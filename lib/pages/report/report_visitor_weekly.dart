import 'package:pos/controller/report_controller.dart';
import 'package:pos/utils/extension.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class ReportVisitorWeekLy extends StatefulWidget {
  const ReportVisitorWeekLy({super.key});

  @override
  State<ReportVisitorWeekLy> createState() => _ReportVisitorWeekLyState();
}

class _ReportVisitorWeekLyState extends State<ReportVisitorWeekLy> {
  bool loading = true;

  /// Order counts per weekday (index 0 = Mon … 6 = Sun), derived fresh
  /// from the current reportIncome data — never accumulated.
  final List<int> _counts = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
  }

  /// Rebuilds [_counts] from scratch using the LAST 7 days present in the
  /// report data (sorted by date), grouped Mon..Sun.
  void _recompute() {
    final data = reportController.reportIncome.value.value;
    _counts.fillRange(0, 7, 0);

    if (data != null && data.isNotEmpty) {
      final recentDays = data.keys.toList()
        ..sort((a, b) => b.compareTo(a)); // newest first
      final last7 = recentDays.take(7);
      for (final day in last7) {
        // weekday: Mon=1 … Sun=7 → index 0..6
        final idx = day.weekday - 1;
        _counts[idx] += data[day]!.length;
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  double get _maxY {
    final maxCount = _counts.fold(0, (p, c) => p > c ? p : c);
    final y = maxCount * 1.2;
    return y < 5 ? 5 : y;
  }

  @override
  Widget build(BuildContext context) {
    // Watch keeps this card rebuilding when orders change.
    reportController.reportIncome.watch(context);
    return ShadCard(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Orders by Weekday'),
          ShadButton.ghost(
            onPressed: loading
                ? null
                : () async {
                    setState(() => loading = true);
                    // Pull the latest orders, then rebuild counts from
                    // scratch (never accumulated).
                    await reportController.reportIncome.refresh();
                    _recompute();
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
        ],
      ),
      description: const Text('Orders in the last 7 days'),
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    barTouchData: barTouchData,
                    titlesData: titlesData(context),
                    borderData: borderData(context),
                    barGroups: barGroups,
                    gridData: const FlGridData(show: false),
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _maxY,
                  ),
                ),
              ),
      ),
    );
  }

  BarTouchData get barTouchData => BarTouchData(
        enabled: false,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 8,
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              rod.toY.round().toString(),
              TextStyle(
                color: context.isDarkMode
                    ? const Color(0xFFD7A86E)
                    : const Color(0xFF8B5E3C),
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      );

  Widget getTitles(double value, TitleMeta meta) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final text = (value.toInt() >= 0 && value.toInt() < 7)
        ? labels[value.toInt()]
        : '';
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(
        text,
        style: TextStyle(
          color: context.secondaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  FlTitlesData titlesData(BuildContext context) => FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: getTitles,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      );

  FlBorderData borderData(BuildContext context) => FlBorderData(
        show: false,
      );

  LinearGradient get _barsGradient => const LinearGradient(
        colors: [
          Color(0xFF8B5E3C),
          Color(0xFFD7A86E),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  List<BarChartGroupData> get barGroups => [
        for (var x = 0; x < 7; x++)
          BarChartGroupData(
            x: x,
            barRods: [
              BarChartRodData(
                toY: _counts[x].toDouble(),
                gradient: _barsGradient,
              )
            ],
            showingTooltipIndicators: [0],
          ),
      ];
}
