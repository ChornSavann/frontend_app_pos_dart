import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/constants/baseurl/base_url_api.dart';

import '../api/api_purchase.dart';
import '../msg/appSnackBar.dart';

// ═════════════════════════════════════════════════════════════
// UI ONLY: design tokens
// ═════════════════════════════════════════════════════════════
class _C {
  static const bg = Color(0xFFF2F4F8);
  static const ink = Color(0xFF142033);
  static const muted = Color(0xFF6C7A8E);
  static const line = Color(0xFFE0E6EE);
  static const navy = Color(0xFF0E2A47);
}

class ViewPurchaseScreen extends StatefulWidget {
  final int purchaseId;

  const ViewPurchaseScreen({super.key, required this.purchaseId});

  @override
  State<ViewPurchaseScreen> createState() => _ViewPurchaseScreenState();
}

class _ViewPurchaseScreenState extends State<ViewPurchaseScreen> {
  final String baseUrl = BaseUrlApi.baseurl;

  bool _isLoading = true;
  Map<String, dynamic>? _purchaseData;
  final ApiPurchase _apiPurchase = ApiPurchase();

  @override
  void initState() {
    super.initState();
    _fetchPurchaseDetail();
  }

  Future<void> _fetchPurchaseDetail() async {
    setState(() => _isLoading = true);

    final responseData = await _apiPurchase.getPurchaseById(widget.purchaseId);
    debugPrint("📦 PURCHASE DETAIL RESPONSE: $responseData");
    if (responseData != null && responseData['success'] == true) {
      setState(() {
        _purchaseData = responseData['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'Error: Failed to load purchase details');
    }
  }

  // Helper សម្រាប់កំណត់ពណ៌ Status Badge
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1️⃣ គណនាសរុបទឹកប្រាក់ទំនិញទាំងអស់ (Subtotal)
    double subTotal = 0.0;
    if (_purchaseData != null && _purchaseData!['items'] is List) {
      for (var item in _purchaseData!['items']) {
        final double qty =
            double.tryParse((item['quantity'] ?? 0).toString()) ?? 0.0;
        final double price =
            double.tryParse((item['unit_cost'] ?? 0).toString()) ?? 0.0;
        subTotal +=
            double.tryParse(
              (item['total_price'] ?? (qty * price)).toString(),
            ) ??
            (qty * price);
      }
    }

    // 2️⃣ ទាញយកតម្លៃ Discount និង Tax ពី API Response
    final double discount =
        double.tryParse((_purchaseData?['discount'] ?? 0).toString()) ?? 0.0;
    final double taxAmount =
        double.tryParse((_purchaseData?['tax'] ?? 0).toString()) ?? 0.0;

    double taxableAmount = subTotal - discount;
    if (taxableAmount < 0) taxableAmount = 0;

    // 3️⃣ គណនា Grand Total ចុងក្រោយ
    double grandTotal =
        double.tryParse((_purchaseData?['total'] ?? 0).toString())! > 0
        ? double.parse((_purchaseData?['total']).toString())
        : (taxableAmount + taxAmount);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _buildHero(context, grandTotal),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _C.navy),
                    )
                  : _purchaseData == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: _C.muted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No data found',
                            style: TextStyle(
                              color: _C.muted,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📄 Purchase Information Card
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(
                                  icon: Icons.receipt_long_rounded,
                                  title: 'Purchase Information',
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.confirmation_number_outlined,
                                  'Purchase Number',
                                  (_purchaseData!['purchase_number'] ??
                                          _purchaseData!['purchaseNumber'] ??
                                          'N/A')
                                      .toString(),
                                ),
                                const _RowDivider(),
                                _buildInfoRow(
                                  Icons.storefront_outlined,
                                  'Supplier Name',
                                  ((_purchaseData!['supplier'] is Map &&
                                              _purchaseData!['supplier']['name'] !=
                                                  null)
                                          ? _purchaseData!['supplier']['name']
                                          : (_purchaseData!['supplier_name'] ??
                                                _purchaseData!['supplierName'] ??
                                                'N/A'))
                                      .toString(),
                                ),
                                const _RowDivider(),
                                _buildInfoRow(
                                  Icons.person_outline_rounded,
                                  'Created By',
                                  (() {
                                    String? name;
                                    if (_purchaseData!['user'] != null &&
                                        _purchaseData!['user'] is Map) {
                                      name = _purchaseData!['user']['name']
                                          ?.toString();
                                    } else {
                                      name =
                                          _purchaseData!['user_name']
                                              ?.toString() ??
                                          _purchaseData!['userName']
                                              ?.toString();
                                    }

                                    if (name != null && name.isNotEmpty) {
                                      return name;
                                    } else if (_purchaseData!['user_id'] !=
                                        null) {
                                      return 'User #${_purchaseData!['user_id']}';
                                    }
                                    return 'N/A';
                                  })(),
                                ),
                                const _RowDivider(),
                                _buildInfoRow(
                                  Icons.payment_rounded,
                                  'Payment Method',
                                  (_purchaseData!['payment_method'] ??
                                          _purchaseData!['paymentMethod'] ??
                                          'Cash')
                                      .toString()
                                      .toUpperCase(),
                                ),
                                const _RowDivider(),
                                _buildInfoRow(
                                  Icons.calendar_today_outlined,
                                  'Date & Time',
                                  (() {
                                    final String rawDate =
                                        (_purchaseData!['date'] ??
                                                _purchaseData!['created_at'] ??
                                                '')
                                            .toString();
                                    if (rawDate.isEmpty || rawDate == 'N/A')
                                      return 'N/A';

                                    try {
                                      // 📌 .toLocal() នឹងដូរកាលបរិច្ឆេទពី UTC ឱ្យត្រូវនឹងម៉ោងក្នុងទូរស័ព្ទ (UTC+7 នៅកម្ពុជា) ស្វ័យប្រវត្តិ
                                      DateTime parsedDate = DateTime.parse(
                                        rawDate,
                                      ).toLocal();
                                      String twoDigits(int n) =>
                                          n.toString().padLeft(2, '0');

                                      int hour = parsedDate.hour;
                                      String period = hour >= 12 ? 'PM' : 'AM';
                                      hour = hour % 12;
                                      hour = hour == 0 ? 12 : hour;

                                      String formattedDate =
                                          "${parsedDate.year}-${twoDigits(parsedDate.month)}-${twoDigits(parsedDate.day)}";
                                      String formattedTime =
                                          "$hour:${twoDigits(parsedDate.minute)} $period";

                                      return "$formattedDate, $formattedTime";
                                    } catch (e) {
                                      return rawDate.length > 19
                                          ? rawDate
                                                .substring(0, 19)
                                                .replaceFirst('T', ' ')
                                          : rawDate;
                                    }
                                  })(),
                                ),
                                if (_purchaseData!['notes'] != null &&
                                    _purchaseData!['notes']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const _RowDivider(),
                                  _buildInfoRow(
                                    Icons.note_alt_outlined,
                                    'Notes',
                                    _purchaseData!['notes'].toString(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 🛒 Items
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'Purchase Items',
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _C.navy.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(_purchaseData!['items'] is List) ? (_purchaseData!['items'] as List).length : 0}',
                                      style: const TextStyle(
                                        color: _C.navy,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // 📋 List of Items
                                ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: (_purchaseData!['items'] is List)
                                      ? (_purchaseData!['items'] as List).length
                                      : 0,
                                  itemBuilder: (context, index) {
                                    final List itemsList =
                                        _purchaseData!['items'] is List
                                        ? _purchaseData!['items']
                                        : [];
                                    final item = itemsList[index];

                                    final double qty =
                                        double.tryParse(
                                          (item['quantity'] ?? 0).toString(),
                                        ) ??
                                        0.0;
                                    final double price =
                                        double.tryParse(
                                          (item['unit_cost'] ?? 0).toString(),
                                        ) ??
                                        0.0;
                                    final double total =
                                        double.tryParse(
                                          (item['total_price'] ?? (qty * price))
                                              .toString(),
                                        ) ??
                                        (qty * price);

                                    String? imageUrl;
                                    if (item['product'] is Map) {
                                      String? img =
                                          item['product']['image'] ??
                                          item['product']['image_url'];
                                      if (img != null && img.isNotEmpty) {
                                        String baseWithoutApi =
                                            baseUrl.endsWith('/api')
                                            ? baseUrl.substring(
                                                0,
                                                baseUrl.length - 4,
                                              )
                                            : (baseUrl.endsWith('/api/')
                                                  ? baseUrl.substring(
                                                      0,
                                                      baseUrl.length - 5,
                                                    )
                                                  : baseUrl);

                                        String cleanBaseUrl =
                                            baseWithoutApi.endsWith('/')
                                            ? baseWithoutApi.substring(
                                                0,
                                                baseWithoutApi.length - 1,
                                              )
                                            : baseWithoutApi;
                                        String cleanImg = img.startsWith('/')
                                            ? img.substring(1)
                                            : img;

                                        imageUrl = cleanImg.startsWith('http')
                                            ? cleanImg
                                            : "$cleanBaseUrl/$cleanImg";
                                      }
                                    }

                                    return Container(
                                      margin: EdgeInsets.only(
                                        bottom: index == itemsList.length - 1
                                            ? 0
                                            : 10,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _C.bg,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          // 🖼️ Product Image Container
                                          Container(
                                            width: 58,
                                            height: 58,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child:
                                                  imageUrl != null &&
                                                      imageUrl.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: imageUrl,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => const Center(
                                                            child: SizedBox(
                                                              width: 18,
                                                              height: 18,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color:
                                                                        _C.navy,
                                                                  ),
                                                            ),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Icon(
                                                            Icons
                                                                .image_not_supported_outlined,
                                                            size: 24,
                                                            color: _C.muted,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.inventory_2_rounded,
                                                      color: _C.navy,
                                                      size: 26,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (item['name'] ??
                                                          item['product_name'] ??
                                                          item['title'] ??
                                                          'Item Name')
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.5,
                                                    color: _C.ink,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: _C.navy
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Qty: ${qty % 1 == 0 ? qty.toInt() : qty}',
                                                        style: const TextStyle(
                                                          color: _C.navy,
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Price: \$${price.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color: _C.muted,
                                                        fontSize: 11.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '\$${total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15.5,
                                              color: _C.navy,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 💰 Summary Breakdown Card (Subtotal, Discount, Tax, Grand Total)
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(
                                  icon: Icons.calculate_outlined,
                                  title: 'Summary',
                                ),
                                const SizedBox(height: 14),
                                _buildSummaryRow(
                                  'Subtotal',
                                  '\$${subTotal.toStringAsFixed(2)}',
                                  false,
                                ),
                                if (discount > 0) ...[
                                  const SizedBox(height: 10),
                                  _buildSummaryRow(
                                    'Discount',
                                    '-\$${discount.toStringAsFixed(2)}',
                                    false,
                                    textColor: Colors.red.shade600,
                                  ),
                                ],
                                if (taxAmount > 0) ...[
                                  const SizedBox(height: 10),
                                  _buildSummaryRow(
                                    'Tax',
                                    '+\$${taxAmount.toStringAsFixed(2)}',
                                    false,
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _C.navy.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _C.navy.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: _buildSummaryRow(
                                    'Grand Total',
                                    '\$${grandTotal.toStringAsFixed(2)}',
                                    true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UI ONLY: presentation helpers
  // ═══════════════════════════════════════════════════════════

  Widget _buildHero(BuildContext context, double grandTotal) {
    final top = MediaQuery.of(context).padding.top;
    final data = _purchaseData;
    final bool ready = !_isLoading && data != null;

    final String purchaseNumber = ready
        ? (data['purchase_number'] ?? data['purchaseNumber'] ?? 'N/A')
              .toString()
        : '';
    final String status = ready ? (data['status'] ?? 'N/A').toString() : '';
    final Color statusColor = _getStatusColor(
      ready ? (data['status'] ?? 'N/A') : 'N/A',
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, ready ? 22 : 14),
      decoration: const BoxDecoration(
        color: _C.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Purchase Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (purchaseNumber.isNotEmpty)
                      Text(
                        purchaseNumber,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                  onPressed: _fetchPurchaseDetail,
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
          if (ready) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grand Total',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: _C.navy),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: _C.muted, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: _C.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String amount,
    bool isTotal, {
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? _C.ink : _C.muted,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 22 : 14.5,
            fontWeight: FontWeight.bold,
            color: textColor ?? (isTotal ? _C.navy : _C.ink),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// UI ONLY: small presentation widgets
// ═════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _C.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: _C.navy),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: _C.ink,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 46, color: _C.line);
}
