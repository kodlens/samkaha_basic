import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/transaction_details.dart';
import 'package:sales_management/utils/helper.dart';

class TransactionDetailModal extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onPrint;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final int txId = (transaction['id'] as num?)?.toInt() ?? 0;
    final String customer = (transaction['customer_name']?.toString().isNotEmpty ?? false)
        ? transaction['customer_name'].toString()
        : 'Walk-in Customer';
    final num total = (transaction['total'] as num?) ?? 0;
    final num payment = (transaction['payment'] as num?) ?? 0;
    final num change = payment - total;

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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ThemeHelper.cardBackground(),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_rounded,
                      color: ThemeHelper.primaryColor(),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction #$txId',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            Helper.formatDateTime(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Customer & Cashier Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CUSTOMER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CASHIER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cashierName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Itemized Breakdown Header
              Text(
                'TRANSACTION ITEMS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: ThemeHelper.textSecondary(),
                ),
              ),
              const SizedBox(height: 8),

              // Async Item List
              FutureBuilder<List<Map<String, dynamic>>>(
                future: TransactionDetails().queryByTransactionId(txId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Error loading items: ${snapshot.error}',
                        style: TextStyle(color: ThemeHelper.error()),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No line items found for this transaction.',
                        style: TextStyle(color: ThemeHelper.textSecondary()),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final num itemQty = (item['quantity'] as num?) ?? 1;
                        final num itemPrice = (item['selling_price'] as num?) ?? 0;
                        final num lineTotal = (item['line_total'] as num?) ?? (itemQty * itemPrice);
                        final String unit = (item['product_unit'] ?? 'x').toString();

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['product_name'] ?? 'Item',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$itemQty $unit @ ${Helper.formatNumberWithPeso(itemPrice)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ThemeHelper.textSecondary(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Helper.formatNumberWithPeso(lineTotal),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Payment Summary Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeHelper.primaryColor().withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Method:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (transaction['payment_method']?.toString().toLowerCase() ?? 'cash') == 'cash'
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            transaction['payment_method']?.toString() ?? 'Cash',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: (transaction['payment_method']?.toString().toLowerCase() ?? 'cash') == 'cash'
                                  ? Colors.green.shade800
                                  : Colors.purple.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount Due:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Helper.formatNumberWithPeso(total),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: ThemeHelper.primaryColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (transaction['payment_method']?.toString().toLowerCase() ?? 'cash') == 'cash'
                              ? 'Cash Tendered:'
                              : 'Amount Tendered:',
                          style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary()),
                        ),
                        Text(
                          Helper.formatNumberWithPeso(payment),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change Returned:',
                          style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary()),
                        ),
                        Text(
                          Helper.formatNumberWithPeso(change > 0 ? change : 0),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Print Receipt & Close
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onPrint,
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text(
                        'Print Receipt',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeHelper.primaryColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
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
}
