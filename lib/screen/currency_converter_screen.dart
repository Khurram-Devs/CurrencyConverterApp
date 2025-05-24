import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/trend_chart_widget.dart';
import '../widgets/conversion_history_widget.dart';
import '../models/currency.dart';
import '../data/currencies.dart';

class CurrencyConverterScreen extends StatefulWidget {
  final bool isConversionHistory;
  const CurrencyConverterScreen({super.key, required this.isConversionHistory});

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
  late List<Currency> _allCurrencies;
  String? _fromCurrency;
  String? _toCurrency;
  String? _conversionResult;
  double? _convertedRate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _conversionHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();

    // Merge and ensure unique currency codes
    final all = [...fiatCurrencies, ...cryptoCurrencies, ...preciousMetals];
    final seen = <String>{};
    _allCurrencies =
        all.where((currency) => seen.add(currency.code.toLowerCase())).toList();

    _fromCurrency = 'usd';
    _toCurrency = 'eur';
    _fetchDefaultConversion();
    _fetchUserConversionHistory();
  }

  Future<void> _fetchDefaultConversion() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data["usd"]["eur"] as num).toDouble();
        setState(() {
          _defaultConversionResult = "1 USD = ${rate.toStringAsFixed(2)} EUR";
        });
      }
    } catch (e) {
      debugPrint("Default conversion fetch error: $e");
    }
  }

  Future<void> _convertCurrency() async {
    if (_fromCurrency == null || _toCurrency == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasUserConverted = true;
    });

    try {
      final url =
          "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/${_fromCurrency!.toLowerCase()}.json";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data[_fromCurrency!][_toCurrency!] as num).toDouble();
        final result = (amount * rate).toStringAsFixed(2);

        final conversionData = {
          'amount': amount,
          'from': _fromCurrency!.toUpperCase(),
          'to': _toCurrency!.toUpperCase(),
          'result': result,
          'timestamp': Timestamp.now(),
          'userId': user.uid,
        };

        await FirebaseFirestore.instance
            .collection('conversions_history')
            .add(conversionData);

        setState(() {
          _convertedRate = rate;
          _conversionResult = result;
        });

        await _fetchUserConversionHistory();
      } else {
        setState(() => _conversionResult = "Failed to fetch rate.");
      }
    } catch (e) {
      setState(() => _conversionResult = "Conversion error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserConversionHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isHistoryLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('conversions_history')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .limit(20)
              .get();

      setState(() {
        _conversionHistory = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      setState(() => _isHistoryLoading = false);
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Login Required"),
            content: const Text(
              "You must be logged in to convert and view history.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('/settings');
                },
                child: const Text("Go to Log In"),
              ),
            ],
          ),
    );
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convertCurrency();
  }

  Widget _buildCurrencyDropdown({
    required String label,
    required String? selected,
    required ValueChanged<String?>? onChanged,
  }) {
    // Group by lowercase code and pick the first occurrence to prevent duplicates
    final uniqueCurrencies =
        {for (var c in _allCurrencies) c.code.toLowerCase(): c}.values.toList();

    final dropdownItems =
        uniqueCurrencies
            .map(
              (currency) => DropdownMenuItem<String>(
                value: currency.code.toLowerCase(),
                child: Text(
                  "${currency.code.toUpperCase()} | ${currency.name}",
                ),
              ),
            )
            .toList();
    print(
      "All dropdown values: ${_allCurrencies.map((c) => c.code.toLowerCase())}",
    );
    return DropdownButtonFormField<String>(
      value:
          selected != null &&
                  dropdownItems.any((item) => item.value == selected)
              ? selected
              : null, // avoid asserting on missing value
      items: dropdownItems,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _allCurrencies.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: "Enter Amount",
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isSmallScreen = constraints.maxWidth < 600;
                              return isSmallScreen
                                  ? Column(
                                    children: [
                                      _buildCurrencyDropdown(
                                        label: "From",
                                        selected: _fromCurrency,
                                        onChanged:
                                            (val) => setState(
                                              () => _fromCurrency = val,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      IconButton(
                                        icon: const Icon(Icons.swap_vert),
                                        onPressed: _swapCurrencies,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCurrencyDropdown(
                                        label: "To",
                                        selected: _toCurrency,
                                        onChanged:
                                            (val) => setState(
                                              () => _toCurrency = val,
                                            ),
                                      ),
                                    ],
                                  )
                                  : Row(
                                    children: [
                                      Expanded(
                                        child: _buildCurrencyDropdown(
                                          label: "From",
                                          selected: _fromCurrency,
                                          onChanged:
                                              (val) => setState(
                                                () => _fromCurrency = val,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.swap_horiz),
                                        onPressed: _swapCurrencies,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildCurrencyDropdown(
                                          label: "To",
                                          selected: _toCurrency,
                                          onChanged:
                                              (val) => setState(
                                                () => _toCurrency = val,
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _convertCurrency,
                              icon: Icon(
                                Icons.currency_exchange,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              label: Text(
                                "Convert",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(235),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_conversionResult != null ||
                              (!_hasUserConverted &&
                                  _defaultConversionResult != null))
                            Text(
                              _hasUserConverted && _conversionResult != null
                                  ? "${_amountController.text} ${_fromCurrency!.toUpperCase()} = $_conversionResult ${_toCurrency!.toUpperCase()}"
                                  : _defaultConversionResult ?? '',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_fromCurrency != null && _toCurrency != null)
                      _buildCard(
                        child: CurrencyRateChart(
                          from: _fromCurrency!,
                          to: _toCurrency!,
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildCard(
                      child: ConversionHistoryWidget(
                        history: _conversionHistory,
                        isLoading: _isHistoryLoading,
                        isConversionHistory: widget.isConversionHistory,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
