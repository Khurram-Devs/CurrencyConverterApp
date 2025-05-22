import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversionHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const ConversionHistoryWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(
          child: Text(
            "No conversion history yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.separated(
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = history[index];
          final timestamp = item['timestamp'];
          final formattedTime = timestamp != null
              ? DateFormat('EEE, MMM d, yyyy • h:mm a')
                  .format(timestamp.toDate())
              : 'Unknown time';

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.currency_exchange, color: Colors.white),
              ),
              title: Text(
                "${item['amount']} ${item['from']} = ${item['result']} ${item['to']}" ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item['from']} → ${item['to']}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
