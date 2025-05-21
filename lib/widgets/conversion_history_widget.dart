import 'package:flutter/material.dart';

class ConversionHistoryWidget extends StatelessWidget {
  final List<String> conversionHistory;

  const ConversionHistoryWidget({Key? key, required this.conversionHistory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: conversionHistory.isEmpty
          ? const Center(
              child: Text(
                "No conversions yet.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: conversionHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.indigo),
                    title: Text(conversionHistory[index],
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                );
              },
            ),
    );
  }
}
