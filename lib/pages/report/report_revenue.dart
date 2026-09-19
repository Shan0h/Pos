import 'package:intl/intl.dart';
import 'package:pos/controller/report_controller.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/extension.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class ReportRevenue extends StatelessWidget {
  const ReportRevenue({super.key});

  @override
  Widget build(BuildContext context) {
    final reportIncome = reportController.reportIncome.watch(context);
    final dateRange = reportController.dateRange.watch(context);
    if (reportIncome.hasValue && reportIncome.value != null) {
      return SizedBox(
        height: 250,
        child: LineChart(mainData(context, reportIncome.value!, dateRange)),
      );
    }
    return const SizedBox();
  }

  LineChartData mainData(BuildContext context,
      Map<DateTime, List<PenjualanModel>> data, List<DateTime> dateRange) {
    DateTime start = dateRange.isNotEmpty
        ? DateTime(dateRange.first.year, dateRange.first.month, dateRange.first.day)
        : DateTime.now().subtract(const Duration(days: 30));
    DateTime end = dateRange.length > 1
        ? DateTime(dateRange.last.year, dateRange.last.month, dateRange.last.day)
        : DateTime.now();

    if (end.isBefore(start)) {
      final temp = start;
      start = end;
      end = temp;
    }

    final totalDays = end.difference(start).inDays + 1;
    final List<FlSpot> spots = [];
    final List<DateTime> dateList = [];
    double maxVal = 0;

    for (int i = 0; i < totalDays; i++) {
      final d = start.add(Duration(days: i));
      final dayKey = DateTime(d.year, d.month, d.day);
      dateList.add(dayKey);
      final sales = data[dayKey] ?? [];
      final double dayTotal = sales.fold<double>(0, (p, c) => p + c.totalHarga);
      if (dayTotal > maxVal) {
        maxVal = dayTotal;
      }
      spots.add(FlSpot(i.toDouble(), dayTotal));
    }

    // 20% headroom above the chart; never collapse to zero.
    maxVal = maxVal * 1.2;
    if (maxVal < 100) maxVal = 100;

    const double minX = 0;
    final double maxX = (totalDays > 1 ? totalDays - 1 : 1).toDouble();
    final double interval = (totalDays / 6).ceilToDouble().clamp(1, 30);

    final axisTextColor = context.secondaryTextColor;
    final lineColor =
        context.isDarkMode ? const Color(0xFFD7A86E) : const Color(0xFF8B5E3C);
    final isMultiMonth = totalDays > 31 || start.month != end.month;

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Text(isMultiMonth ? 'Date' : 'Day',
              style: TextStyle(fontSize: 12, color: axisTextColor)),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: interval,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= dateList.length) {
                return const SizedBox();
              }
              final date = dateList[idx];
              final label = isMultiMonth
                  ? DateFormat('d/M').format(date)
                  : date.day.toString();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: axisTextColor),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return Text('0',
                    style: TextStyle(fontSize: 10, color: axisTextColor));
              }
              String text = '';
              if (value >= 1000000) {
                text = '${(value / 1000000).toStringAsFixed(1)}M';
              } else if (value >= 1000) {
                text = '${(value / 1000).toStringAsFixed(0)}k';
              } else {
                text = value.toStringAsFixed(0);
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(text,
                    style: TextStyle(fontSize: 10, color: axisTextColor),
                    textAlign: TextAlign.right),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.15)
                : const Color(0xff37434d).withValues(alpha: 0.2)),
      ),
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: maxVal,
      lineTouchData: LineTouchData(touchTooltipData:
          LineTouchTooltipData(getTooltipItems: (touchedSpots) {
        return touchedSpots.map((touchedSpot) {
          final idx = touchedSpot.x.toInt();
          final dateStr = (idx >= 0 && idx < dateList.length)
              ? DateFormat('dd MMM yyyy').format(dateList[idx])
              : '';
          return LineTooltipItem(
              '$dateStr\n${currency.format(touchedSpot.y)}',
              const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white));
        }).toList();
      })),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: totalDays < 45,
          barWidth: 4,
          color: lineColor,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
