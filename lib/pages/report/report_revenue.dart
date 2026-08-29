import 'package:pos/controller/report_controller.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/utils/constant.dart';
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
        child: LineChart(mainData(reportIncome.value!)),
      );
    }
    return const SizedBox();
  }

  LineChartData mainData(Map<DateTime, List<PenjualanModel>> data) {
    double maxVal = 0;
    for (var i in data.entries) {
      double total = i.value.fold(0, (p, c) => p + c.totalHarga);
      if (total > maxVal) {
        maxVal = total;
      }
    }
    // Beri ruang ekstra 20% di atas chart
    maxVal = maxVal * 1.2;
    if (maxVal < 100) maxVal = 100;

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
        bottomTitles: const AxisTitles(
          axisNameWidget: Text('Day', style: TextStyle(fontSize: 12)),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 5, // Tunjuk selang 5 hari supaya tak langgar
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
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
                child: Text(text, style: const TextStyle(fontSize: 10), textAlign: TextAlign.right),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d).withValues(alpha: 0.2)),
      ),
      minX: 1,
      maxX: 31,
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
          color: Colors.teal,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true, 
            color: Colors.teal.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
