import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/currency.dart';
import '../data/currencies.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  List<Currency> displayedCurrencies = fiatCurrencies;
  List<Map<String, dynamic>> currenciesData = [];
  List<Map<String, dynamic>> filteredData = [];

  String selectedCategory = 'fiat';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchCurrencyChanges();
  }

  void onCategoryChanged(String? value) {
    if (value == null) return;
    setState(() {
      selectedCategory = value;
      searchQuery = '';
      switch (value) {
        case 'fiat':
          displayedCurrencies = fiatCurrencies;
          break;
        case 'crypto':
          displayedCurrencies = cryptoCurrencies;
          break;
        case 'metal':
          displayedCurrencies = preciousMetals;
          break;
      }
      isLoading = true;
    });
    fetchCurrencyChanges();
  }

  void applySearchFilter() {
    if (searchQuery.isEmpty) {
      filteredData = currenciesData;
    } else {
      filteredData = currenciesData
          .where((currency) =>
              (currency['code'] as String)
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              (currency['name'] as String)
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  Future<void> fetchCurrencyChanges() async {
    final base = 'usd';
    currenciesData.clear();

    try {
      final latestUrl = Uri.parse(
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$base.json',
      );
      final latestResponse = await http.get(latestUrl);

      DateTime checkDate = DateTime.now().subtract(const Duration(days: 7));
      Map<String, dynamic>? previousRates;
      String? previousDateUsed;

      for (int i = 0; i < 5; i++) {
        final dateStr = DateFormat('yyyy-MM-dd').format(checkDate);
        final previousUrl = Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$dateStr/v1/currencies/$base.json',
        );
        final prevResponse = await http.get(previousUrl);

        if (prevResponse.statusCode == 200) {
          previousRates = json.decode(prevResponse.body)[base];
          previousDateUsed = dateStr;
          break;
        } else {
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }

      if (latestResponse.statusCode == 200 && previousRates != null) {
        final latestRates = json.decode(latestResponse.body)[base];

        for (final currency in displayedCurrencies) {
          final code = currency.code.toLowerCase();

          if (code == base) {
            currenciesData.add({
              'code': code,
              'name': currency.name,
              'change': 0.0,
            });
            continue;
          }

          final todayRate = latestRates[code];
          final yestRate = previousRates[code];

          if (todayRate != null && yestRate != null) {
            final change = ((todayRate - yestRate) / yestRate) * 100;
            currenciesData.add({
              'code': currency.code,
              'name': currency.name,
              'change': change,
            });
          }
        }

        filteredData = currenciesData;
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('API error:\nLatest: ${latestResponse.statusCode}');
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
    return Column(
      children: [
        // Category dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: InputDecoration(
              labelText: 'Currency Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'fiat', child: Text('Fiat')),
              DropdownMenuItem(value: 'crypto', child: Text('Crypto')),
              DropdownMenuItem(value: 'metal', child: Text('Metal')),
            ],
            onChanged: onCategoryChanged,
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            onChanged: (value) {
              searchQuery = value;
              applySearchFilter();
            },
            decoration: InputDecoration(
              hintText: 'Search currency by name or code...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Currency list
        Expanded(
          child: Skeletonizer(
            enabled: isLoading,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: isLoading ? 20 : filteredData.length,
              itemBuilder: (context, index) {
                final currency = isLoading
                    ? {'code': 'usd', 'name': 'US Dollar', 'change': 0.0}
                    : filteredData[index];

                final change = currency['change'] as double;
                final isPositive = change >= 0;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  (currency['code'] as String).toUpperCase(),
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
                                  currency['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
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
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isPositive ? Colors.green : Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                // Add to tracking logic
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
          ),
        ),
      ],
    );
  }
}
