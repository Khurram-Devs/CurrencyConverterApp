import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widget/trend_chart_widget.dart';
import '../widget/conversion_history_widget.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: "1",
  );

  String? _defaultConversionResult;
  bool _hasUserConverted = false;
  Map<String, String> _currencyMap = {};
  List<String> _currencyCodes = [];
  String? _fromCurrency;
  String? _toCurrency;
  double? _convertedRate;
  String? _conversionResult;
  bool _isLoading = false;

  final List<String> _conversionHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchSupportedCurrencies().then((_) => _fetchDefaultConversion());
  }

  Future<void> _fetchDefaultConversion() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://api.frankfurter.app/latest?amount=1&from=USD&to=EUR",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data["rates"]["EUR"] as num).toDouble();
        setState(() {
          _defaultConversionResult = "1 USD = ${rate.toStringAsFixed(2)} EUR";
        });
      }
    } catch (e) {
      debugPrint("Default conversion fetch error: $e");
    }
  }

  Future<void> _fetchSupportedCurrencies() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("https://api.frankfurter.app/currencies"),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final Map<String, String> parsedMap = jsonData.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        setState(() {
          _currencyMap = parsedMap;
          _currencyCodes = parsedMap.keys.toList()..sort();
          _fromCurrency = 'USD';
          _toCurrency =
              _currencyCodes.contains('EUR') ? 'EUR' : _currencyCodes.first;
        });
      }
    } catch (e) {
      debugPrint("Error fetching currencies: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _convertCurrency() async {
    if (_fromCurrency == null || _toCurrency == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
      _hasUserConverted = true;
    });

    try {
      final uri = Uri.parse(
        "https://api.frankfurter.app/latest?amount=$amount&from=$_fromCurrency&to=$_toCurrency",
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data["rates"][_toCurrency] as num).toDouble();
        final result =
            "$amount $_fromCurrency = ${rate.toStringAsFixed(2)} $_toCurrency";

        setState(() {
          _convertedRate = rate / amount;
          _conversionResult = result;
          _conversionHistory.insert(0, result);
          if (_conversionHistory.length > 20) {
            _conversionHistory.removeLast();
          }
        });
      } else {
        setState(() => _conversionResult = "Failed to fetch rate.");
      }
    } catch (e) {
      setState(() => _conversionResult = "Conversion error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child:
            _isLoading && _currencyMap.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: "Enter Amount",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
  builder: (context, constraints) {
    final isWide = constraints.maxWidth > 500;
    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: _buildCurrencyDropdown(
              label: "From",
              selected: _fromCurrency,
              onChanged: (val) =>
                  setState(() => _fromCurrency = val),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.compare_arrows, size: 28),
            onPressed: _swapCurrencies,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCurrencyDropdown(
              label: "To",
              selected: _toCurrency,
              onChanged: (val) =>
                  setState(() => _toCurrency = val),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildCurrencyDropdown(
            label: "From",
            selected: _fromCurrency,
            onChanged: (val) =>
                setState(() => _fromCurrency = val),
          ),
          const SizedBox(height: 10),
          IconButton(
            icon: const Icon(Icons.compare_arrows, size: 28),
            onPressed: _swapCurrencies,
          ),
          const SizedBox(height: 10),
          _buildCurrencyDropdown(
            label: "To",
            selected: _toCurrency,
            onChanged: (val) =>
                setState(() => _toCurrency = val),
          ),
        ],
      );
    }
  },
),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _convertCurrency,
                          icon: const Icon(Icons.currency_exchange_rounded),
                          label: const Text(
                            "Convert Now",
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _conversionResult ??
                                    (_hasUserConverted
                                        ? ''
                                        : (_defaultConversionResult ?? '')),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (_fromCurrency != null && _toCurrency != null)
                        CurrencyRateChart(
                          from: _fromCurrency!,
                          to: _toCurrency!,
                        ),

                      const SizedBox(height: 20),
                      Text(
                        "Conversion History",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      // Replace Expanded + ListView here with ConversionHistoryWidget
                      ConversionHistoryWidget(
                        conversionHistory: _conversionHistory,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String label,
    required String? selected,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: selected,
      items:
          _currencyCodes
              .map(
                (code) => DropdownMenuItem(
                  value: code,
                  child: Text(
                    "$code | ${_currencyMap[code]}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
