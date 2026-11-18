import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/utils/helper.dart';

Widget transactionCard({
  required Map<String, dynamic> transaction,
  required VoidCallback onTap,
  required VoidCallback onPrint,
}) {
  final int txId = (transaction['id'] as num?)?.toInt() ?? 0;
  final num total = (transaction['total'] as num?) ?? 0;
  final int qty = (transaction['quantity'] as num?)?.toInt() ?? 0;
  final String customer =
      (transaction['customer_name']?.toString().isNotEmpty ?? false)
          ? transaction['customer_name'].toString()
          : 'Walk-in Customer';
  final String paymentMethod =
      transaction['payment_method']?.toString().isNotEmpty == true
          ? transaction['payment_method'].toString()
          : 'Cash';
  final bool isCash = paymentMethod.toLowerCase() == 'cash';

  DateTime? timestamp;
  try {
    if (transaction['timestamp'] != null) {
      timestamp = DateTime.parse(transaction['timestamp'].toString());
    }
  } catch (_) {}

  final cashierName =
      '${transaction['cashier_fname'] ?? ''} ${transaction['cashier_lname'] ?? ''}'
              .trim()
              .isEmpty
          ? (transaction['cashier_username'] ?? 'Staff')
          : '${transaction['cashier_fname'] ?? ''} ${transaction['cashier_lname'] ?? ''}'
              .trim();

  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Colors.grey.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    color: ThemeHelper.cardBackground(),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Transaction ID, Timestamp, and Amount
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ThemeHelper.primaryColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_rounded,
                        size: 13,
                        color: ThemeHelper.primaryColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#$txId',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: ThemeHelper.primaryColor(),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (timestamp != null)
                  Expanded(
                    child: Text(
                      Helper.formatDateTime(timestamp),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: ThemeHelper.textSecondary(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  Helper.formatNumberWithPeso(total),
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: ThemeHelper.primaryColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Middle & Bottom Row: Customer, Cashier, Items Count & Print Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: ThemeHelper.textSecondary(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isCash
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              paymentMethod,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCash
                                    ? Colors.green.shade800
                                    : Colors.purple.shade800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$qty item${qty == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          Text(
                            'Cashier: $cashierName',
                            style: TextStyle(
                              fontSize: 11,
                              color: ThemeHelper.textSecondary(),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Quick Print Receipt Button
                IconButton.filledTonal(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_rounded, size: 18),
                  tooltip: 'Reprint Receipt',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        ThemeHelper.primaryColor().withValues(alpha: 0.1),
                    foregroundColor: ThemeHelper.primaryColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
