import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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
    // Check if the from/to currency changed
    if (widget.from != oldWidget.from || widget.to != oldWidget.to) {
      _fetchHistoricalRates();
    }
  }

  Future<void> _fetchHistoricalRates() async {
    setState(() => _isLoading = true);  // Show loading on every fetch

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final formatter = DateFormat('yyyy-MM-dd');

    final url = Uri.parse(
      'https://api.frankfurter.app/${formatter.format(startDate)}..${formatter.format(now)}?from=${widget.from}&to=${widget.to}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rateEntries =
            (data['rates'] as Map<String, dynamic>).entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

        List<FlSpot> spots = [];
        List<String> labels = [];

        for (int i = 0; i < rateEntries.length; i++) {
          final date = rateEntries[i].key;
          final rateMap = rateEntries[i].value as Map<String, dynamic>;
          if (rateMap.containsKey(widget.to)) {
            final rate = (rateMap[widget.to] as num).toDouble();
            spots.add(FlSpot(i.toDouble(), rate));
            labels.add(DateFormat('MM-dd').format(DateTime.parse(date)));
          }
        }

        setState(() {
          _spots = spots;
          _dates = labels;
          _isLoading = false;
        });
      } else {
        setState(() {
          _spots = [];
          _dates = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading rates: $e");
      setState(() {
        _spots = [];
        _dates = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
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
          const Text(
            "30-Day Exchange Rate History",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? const Color(0x04FFFFFF)
                        : const Color(0x0B000000),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        // Only label if value matches an actual x in _spots
                        final index = _spots.indexWhere((s) => s.x == value);
                        if (index <= 0 || index >= _spots.length - 1) {
                          return const SizedBox.shrink();
                        }

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            _dates[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
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
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor:
                        isDark ? Colors.black87 : Colors.white,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "${spot.y.toStringAsFixed(4)} ${widget.to}",
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
