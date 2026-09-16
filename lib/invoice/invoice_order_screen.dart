import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InvoiceOrderScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const InvoiceOrderScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // ទទួលយកទិន្នន័យ ឬប្រើប្រាស់ Default Mockup Data ប្រសិនបើគ្មានទិន្នន័យបញ្ជូនមក
    final invoiceData = {
      'invoice_number': data['invoice_number'] ?? 'INV-2026-990120',
      'amount': data['amount'] ?? '25.00',
      'currency': data['currency'] ?? 'USD',
      'merchant': data['merchant'] ?? 'POS System Cambodia',
      'method': data['method'] ?? 'Cash',
      'time': data['time'] ?? '2026-06-07 14:30:00',
      'sender': data['sender'] ?? 'Chorn Savann',
      'amount_paid': data['amount_paid'] ?? '25.00',
      'change_amount': data['change_amount'] ?? '0.00',
      'items': data['items'] ?? [
        {"name": "Coca Cola", "qty": 3, "unit_price": 10.00, "total": 20.00},
        {"name": "Burger", "qty": 1, "unit_price": 5.00, "total": 5.00},
      ]
    };

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Invoice Details", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFFF7F8FC),
        border: null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 10),
                    // 1. Success Check Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF4CAF50), size: 38),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Payment Success!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Your payment has been successfully done.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // 2. Card 1: Transaction General Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Amount", style: TextStyle(color: Colors.grey, fontSize: 14)),
                              Text("${invoiceData['currency']} ${invoiceData['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Payment Status", style: TextStyle(color: Colors.grey, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text("Success", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                          ),
                          _buildInfoRow("Invoice No", invoiceData['invoice_number']),
                          _buildInfoRow("Merchant", invoiceData['merchant']),
                          _buildInfoRow("Payment Method", invoiceData['method']),
                          _buildInfoRow("Payment Time", invoiceData['time']),
                          _buildInfoRow("Customer", invoiceData['sender']),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Card 2: Items Purchased List (បញ្ជីទំនិញ)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Items Purchased", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                          ),
                          ...((invoiceData['items'] as List).map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text("${item['qty']} x \$${item['unit_price']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text("\$${item['total']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ))),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                          ),
                          _buildInfoRow("Amount Paid", "\$${invoiceData['amount_paid']}"),
                          _buildInfoRow("Change", "\$${invoiceData['change_amount']}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 4. Bottom Buttons (Get PDF & Done)
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 10),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.arrow_down_doc, color: Color(0xFF5C2D91)),
                            SizedBox(width: 8),
                            Text("Get PDF Receipt", style: TextStyle(color: Color(0xFF5C2D91), fontWeight: FontWeight.w600, fontSize: 16)),
                          ],
                        ),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CupertinoButton(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF5C2D91),
                        child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}