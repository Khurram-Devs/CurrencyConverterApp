import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> currencies = [];
  List<String> topCurrencies = [];
  Map<String, String> currencyNames = {};

  @override
  void initState() {
    super.initState();
    fetchSupportedCurrencies();
  }

  Future<void> fetchSupportedCurrencies() async {
    try {
      final response = await http.get(Uri.parse('https://api.frankfurter.app/currencies'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          currencyNames = Map<String, String>.from(data);
          topCurrencies = data.keys.toList();
        });
        fetchCurrencyChanges();
      } else {
        throw Exception('Failed to load currencies');
      }
    } catch (e) {
      debugPrint('Error fetching supported currencies: $e');
    }
  }

  Future<void> fetchCurrencyChanges() async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 2));
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

    try {
      final toList = topCurrencies.where((c) => c != 'USD').join(',');
      final todayRes = await http.get(Uri.parse(
        'https://api.frankfurter.app/latest?from=USD&to=$toList',
      ));
      final yesterdayRes = await http.get(Uri.parse(
        'https://api.frankfurter.app/$yesterdayStr?from=USD&to=$toList',
      ));

      if (todayRes.statusCode == 200 && yesterdayRes.statusCode == 200) {
        final todayRates = json.decode(todayRes.body)['rates'] as Map<String, dynamic>;
        final yesterdayRates = json.decode(yesterdayRes.body)['rates'] as Map<String, dynamic>;

        List<Map<String, dynamic>> updatedCurrencies = [];

        for (var code in topCurrencies) {
          if (code == 'USD') {
            updatedCurrencies.add({'code': 'USD', 'change': 0.0});
            continue;
          }

          final todayRate = todayRates[code];
          final yesterdayRate = yesterdayRates[code];

          if (todayRate != null && yesterdayRate != null) {
            final change = ((todayRate - yesterdayRate) / yesterdayRate) * 100;
            updatedCurrencies.add({'code': code, 'change': change});
          }
        }

        setState(() {
          currencies = updatedCurrencies;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load rate data');
      }
    } catch (e) {
      debugPrint('Error fetching currency rate changes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return Skeletonizer(
    enabled: isLoading,
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: isLoading ? 20 : currencies.length,
      itemBuilder: (context, index) {
        final currency = isLoading
            ? {'code': 'USD', 'change': 0.0}
            : currencies[index];

        final change = currency['change'] as double;
        final isPositive = change >= 0;

        return Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 3,
  margin: const EdgeInsets.symmetric(vertical: 6),
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Currency Code and Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currency['code'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    fontSize: 22,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currencyNames[currency['code']] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    letterSpacing: 2,
                    wordSpacing: 2,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${change.abs().toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 18,
                    letterSpacing: 2,
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                // Add to track functionality
              },
            ),
          ],
        ),
      ],
    ),
  ),
);

      },
    ),
  );
}

}
