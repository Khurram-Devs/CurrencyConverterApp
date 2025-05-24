import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/gestures.dart';

class ConversionHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final bool isLoading;
  final bool isConversionHistory;

  const ConversionHistoryWidget({
    super.key,
    required this.history,
    required this.isLoading,
    required this.isConversionHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConversionHistory) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            children: [
              const TextSpan(
                text: "Conversion history is disabled.\nEnable it from the ",
              ),
              TextSpan(
                text: "Settings page",
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed('/settings');
                      },
              ),
              const TextSpan(text: "."),
            ],
          ),
        ),
      );
    }

    final showEmptyMessage = !isLoading && history.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Skeletonizer(
        enabled: isLoading,
        child: Column(
          children: [
            if (showEmptyMessage)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "No conversion history yet.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: isLoading ? 5 : history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item =
                      isLoading
                          ? {
                            'amount': '123.45',
                            'from': 'USD',
                            'to': 'EUR',
                            'result': '113.78',
                            'timestamp': null,
                          }
                          : history[index];

                  final timestamp = item['timestamp'];
                  final formattedTime =
                      timestamp != null
                          ? DateFormat(
                            'EEE, MMM d, yyyy • h:mm a',
                          ).format(timestamp.toDate())
                          : 'Loading...';

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(
                          Icons.currency_exchange,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        "${item['amount']} ${item['from']} = ${item['result']} ${item['to']}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${item['from']} → ${item['to']}"),
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
          ],
        ),
      ),
    );
  }
}
