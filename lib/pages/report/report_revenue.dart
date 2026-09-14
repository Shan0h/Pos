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
    if (reportIncome.hasValue && reportIncome.value != null) {
      return SizedBox(
        height: 250,
        child: LineChart(mainData(context, reportIncome.value!)),
      );
    }
    return const SizedBox();
  }

  LineChartData mainData(BuildContext context,
      Map<DateTime, List<PenjualanModel>> data) {
    double maxVal = 0;
    double minX = 1;
    double maxX = 31;

    if (data.isNotEmpty) {
      final days = data.keys.map((d) => d.day).toList();
      minX = days.reduce((a, b) => a < b ? a : b).toDouble();
      maxX = days.reduce((a, b) => a > b ? a : b).toDouble();
    }

    for (var i in data.entries) {
      double total = i.value.fold(0, (p, c) => p + c.totalHarga);
      if (total > maxVal) {
        maxVal = total;
      }
    }
    // 20% headroom above the chart; never collapse to zero.
    maxVal = maxVal * 1.2;
    if (maxVal < 100) maxVal = 100;

    final axisTextColor = context.secondaryTextColor;
    final lineColor =
        context.isDarkMode ? const Color(0xFFD7A86E) : const Color(0xFF8B5E3C);

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
          axisNameWidget: Text('Day',
              style: TextStyle(fontSize: 12, color: axisTextColor)),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: ((maxX - minX) / 6).ceilToDouble().clamp(1, 10),
            getTitlesWidget: (value, meta) {
              // Only label whole days inside the range to avoid clutter.
              if (value < minX || value > maxX) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  value.toInt().toString(),
                  style:
                      TextStyle(fontSize: 10, color: axisTextColor),
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
          return LineTooltipItem(
              currency.format(touchedSpot.y),
              const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white));
        }).toList();
      })),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i in data.entries)
              FlSpot(
                i.key.day.toDouble(),
                i.value.fold(0, (p, c) => p + c.totalHarga),
              ),
          ],
          isCurved: true,
          barWidth: 5,
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
