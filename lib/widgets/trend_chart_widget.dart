import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';

class CurrencyRateChart extends StatefulWidget {
  final String from;
  final String to;

  const CurrencyRateChart({super.key, required this.from, required this.to});

  @override
  State<CurrencyRateChart> createState() => _CurrencyRateChartState();
}

class _CurrencyRateChartState extends State<CurrencyRateChart> {
  List<FlSpot> _spots = [];
  List<String> _dates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoricalRates();
  }

  @override
  void didUpdateWidget(CurrencyRateChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.from != oldWidget.from || widget.to != oldWidget.to) {
      _fetchHistoricalRates();
    }
  }

  Future<void> _fetchHistoricalRates() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final int totalDays = 30;
    final int step = (totalDays / totalDays).floor();

    List<FlSpot> spots = [];
    List<String> labels = [];

    for (int i = totalDays; i >= 0; i -= step) {
      final date = now.subtract(Duration(days: i));
      final formatted = DateFormat('yyyy-MM-dd').format(date);

      final url = Uri.parse(
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$formatted/v1/currencies/${widget.from.toLowerCase()}.json',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final rates = data[widget.from.toLowerCase()] as Map<String, dynamic>;
          final rate = rates[widget.to.toLowerCase()];

          if (rate != null) {
            spots.add(
              FlSpot(spots.length.toDouble(), (rate as num).toDouble()),
            );
            labels.add(DateFormat('MM-dd').format(date));
          }
        }
      } catch (e) {
        debugPrint('Error fetching rate for $formatted: $e');
      }
    }

    setState(() {
      _spots = spots;
      _dates = labels;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Skeletonizer(
          child: Column(
            children: [
              Text(
                "Exchange Rate History",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_spots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No chart data available."),
      );
    }

    final double minY = _spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final double maxY = _spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final double padding =
        (maxY - minY).abs() < 0.01 ? 0.01 : (maxY - minY) * 0.1;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Text(
            "${_spots.length - 1}-Days Exchange Rate History",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color:
                            isDark
                                ? const Color(0x04FFFFFF)
                                : const Color(0x0B000000),
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: -0.2,
                maxX: _spots.length.toDouble() - 0.8,
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: false,
                    color: Colors.blueAccent,
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.blue,
                          strokeWidth: 0,
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: isDark ? Colors.black87 : Colors.white,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        final date =
                            (index >= 0 && index < _dates.length)
                                ? _dates[index]
                                : '';
                        return LineTooltipItem(
                          "$date\n${spot.y.toStringAsFixed(4)} ${widget.to}",
                          TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
