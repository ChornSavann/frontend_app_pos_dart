import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_customer.dart';

class _C {
  static const navy = Color(0xFF0E2A47);
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF2E9E6B);

  static const avatarColors = <Color>[
    Color(0xFF0E2A47),
    Color(0xFF0F766E),
    Color(0xFF6D28D9),
    Color(0xFFEF6C00),
    Color(0xFF2E9E6B),
    Color(0xFFBE185D),
  ];
}

class _P {
  final bool dark;
  const _P(this.dark);

  Color get bg => dark ? const Color(0xFF0F141B) : const Color(0xFFF2F4F8);
  Color get card => dark ? const Color(0xFF1B222C) : Colors.white;
  Color get field => dark ? const Color(0xFF252E3A) : const Color(0xFFF2F4F8);
  Color get ink => dark ? Colors.white : const Color(0xFF142033);
  Color get muted => dark ? const Color(0xFF9AA7B8) : const Color(0xFF6C7A8E);
  Color get line => dark ? const Color(0xFF2B3542) : const Color(0xFFE0E6EE);
  Color get hero => dark ? const Color(0xFF0B2038) : _C.navy;
  Color get accent => dark ? const Color(0xFF8DB8F0) : _C.navy;
}

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _customerData;
  List<dynamic> _customerOrders = [];
  final ApiCustomer _apiCustomer = ApiCustomer();

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiCustomer.getCustomerDetails(widget.customerId);
      if (result != null && result['success'] == true) {
        setState(() {
          _customerData = result['customer'] ?? {};
          _customerOrders = result['orders'] ?? result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UI ONLY: presentation helpers
  // ═══════════════════════════════════════════════════════════

  Widget _heroStat(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'KhmerOSBattambang',
                        height: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'KhmerOSBattambang',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, _P p) {
    final top = MediaQuery.of(context).padding.top;
    final String name = widget.customerName;
    final Color avatarColor = name.isNotEmpty
        ? _C.avatarColors[name.codeUnitAt(0) % _C.avatarColors.length]
        : _C.avatarColors[0];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, 22),
      decoration: BoxDecoration(
        color: p.hero,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
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
              const Expanded(
                child: Text(
                  "ព័ត៌មានអតិថិជន",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'KhmerOSBattambang',
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: avatarColor,
                      fontFamily: 'KhmerOSBattambang',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KhmerOSBattambang',
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _heroStat(
                    Icons.receipt_long_rounded,
                    'ការបញ្ជាទិញ',
                    '${_customerOrders.length}',
                  ),
                  const SizedBox(width: 10),
                  _heroStat(
                    Icons.stars_rounded,
                    'ពិន្ទុ',
                    '${_customerData?['points'] ?? 0}',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final p = _P(isDarkMode);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.bg,
        body: Column(
          children: [
            _buildHero(context, p),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: p.accent))
                  : RefreshIndicator(
                      color: p.accent,
                      onRefresh: _fetchCustomerData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                        children: [
                          // 👤 ព័ត៌មានទំនាក់ទំនងរបស់អតិថិជន
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: p.card,
                              borderRadius: BorderRadius.circular(22),
                              border: isDarkMode
                                  ? Border.all(color: p.line)
                                  : null,
                              boxShadow: isDarkMode
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: _C.navy.withValues(alpha: 0.07),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: p.accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Icon(
                                        Icons.contact_page_rounded,
                                        size: 18,
                                        color: p.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "ព័ត៌មានទំនាក់ទំនង",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'KhmerOSBattambang',
                                        color: p.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.phone_rounded,
                                  color: Colors.blue,
                                  text:
                                      _customerData?['phone'] ??
                                      'គ្មានលេខទូរស័ព្ទ',
                                ),
                                Divider(height: 1, indent: 50, color: p.line),
                                _buildInfoRow(
                                  icon: Icons.email_outlined,
                                  color: Colors.orange,
                                  text:
                                      _customerData?['email'] ?? 'គ្មានអ៊ីម៉ែល',
                                ),
                                Divider(height: 1, indent: 50, color: p.line),
                                _buildInfoRow(
                                  icon: Icons.location_on_outlined,
                                  color: Colors.red,
                                  text:
                                      _customerData?['address'] ??
                                      'គ្មានអាសយដ្ឋាន',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // 📦 ប្រវត្តិការបញ្ជាទិញ (Orders History Title)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "ប្រវត្តិការបញ្ជាទិញទំនិញ (Orders History)",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'KhmerOSBattambang',
                                      color: p.ink,
                                    ),
                                  ),
                                ),
                                if (_customerOrders.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_customerOrders.length}',
                                      style: TextStyle(
                                        color: p.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          _customerOrders.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: p.muted.withValues(
                                              alpha: 0.12,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.receipt_long_outlined,
                                            size: 40,
                                            color: p.muted,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'អតិថិជននេះមិនទាន់មានប្រវត្តិការបញ្ជាទិញទេ',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: p.muted,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'KhmerOSBattambang',
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _customerOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = _customerOrders[index];
                                    double totalAmount =
                                        double.tryParse(
                                          (order['total_amount'] ??
                                                  order['total'] ??
                                                  0)
                                              .toString(),
                                        ) ??
                                        0.0;

                                    List<dynamic> orderItems =
                                        order['items'] ??
                                        order['details'] ??
                                        [];

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: p.card,
                                        borderRadius: BorderRadius.circular(22),
                                        border: isDarkMode
                                            ? Border.all(color: p.line)
                                            : null,
                                        boxShadow: isDarkMode
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: _C.navy.withValues(
                                                    alpha: 0.07,
                                                  ),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 🔹 ក្បាលវិក្កយបត្រ (Invoice Header)
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _C.green.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(13),
                                                ),
                                                child: const Icon(
                                                  Icons.receipt_rounded,
                                                  color: _C.green,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${order['order_number'] ?? order['invoice_number'] ?? 'N/A'}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14.5,
                                                        color: p.ink,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      "កាលបរិច្ឆេទ: ${order['date'] ?? order['created_at'] ?? ''}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: p.muted,
                                                        fontSize: 11.5,
                                                        fontFamily:
                                                            'KhmerOSBattambang',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "\$${totalAmount.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                  color: _C.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Divider(
                                              height: 1,
                                              color: p.line,
                                            ),
                                          ),

                                          // 🛒 បញ្ជីទំនិញលម្អិត (Items List)
                                          orderItems.isEmpty
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                      ),
                                                  child: Text(
                                                    "គ្មានទិន្នន័យទំនិញ",
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: p.muted,
                                                      fontFamily:
                                                          'KhmerOSBattambang',
                                                    ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  shrinkWrap: true,
                                                  padding: EdgeInsets.zero,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: orderItems.length,
                                                  itemBuilder: (context, itemIndex) {
                                                    final item =
                                                        orderItems[itemIndex];
                                                    final productName =
                                                        item['product_name'] ??
                                                        item['product']?['name'] ??
                                                        'ទំនិញមិនស្គាល់ឈ្មោះ';
                                                    final productImage =
                                                        item['image_url'] ??
                                                        item['product']?['image_url'] ??
                                                        '';

                                                    final quantity =
                                                        item['quantity'] ?? 1;
                                                    final unitPrice =
                                                        double.tryParse(
                                                          (item['unit_price'] ??
                                                                  item['price'] ??
                                                                  0)
                                                              .toString(),
                                                        ) ??
                                                        0.0;
                                                    final totalPrice =
                                                        double.tryParse(
                                                          (item['total_price'] ??
                                                                  (unitPrice *
                                                                      quantity))
                                                              .toString(),
                                                        ) ??
                                                        0.0;

                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: p.field,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          // 🖼️ រូបភាពទំនិញ
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            child:
                                                                productImage
                                                                    .isNotEmpty
                                                                ? Image.network(
                                                                    productImage,
                                                                    width: 48,
                                                                    height: 48,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    errorBuilder:
                                                                        (
                                                                          context,
                                                                          error,
                                                                          stackTrace,
                                                                        ) => Container(
                                                                          width:
                                                                              48,
                                                                          height:
                                                                              48,
                                                                          color:
                                                                              p.card,
                                                                          child: Icon(
                                                                            Icons.image_not_supported,
                                                                            size:
                                                                                18,
                                                                            color:
                                                                                p.muted,
                                                                          ),
                                                                        ),
                                                                  )
                                                                : Container(
                                                                    width: 48,
                                                                    height: 48,
                                                                    color:
                                                                        p.card,
                                                                    child: Icon(
                                                                      Icons
                                                                          .shopping_bag_outlined,
                                                                      size: 20,
                                                                      color: p
                                                                          .muted,
                                                                    ),
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),

                                                          // 📝 ឈ្មោះ និងចំនួន
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  productName,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        13.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        p.ink,
                                                                    fontFamily:
                                                                        'KhmerOSBattambang',
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 3,
                                                                ),
                                                                Text(
                                                                  "ចំនួន: $quantity  ×  \$${unitPrice.toStringAsFixed(2)}",
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        11.5,
                                                                    color:
                                                                        p.muted,
                                                                    fontFamily:
                                                                        'KhmerOSBattambang',
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),

                                                          // 💵 តម្លៃសរុបប្រចាំមុខទំនិញ
                                                          Text(
                                                            "\$${totalPrice.toStringAsFixed(2)}",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: p.ink,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ],
                                      ),
                                    );
                                  },
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

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                color: p.ink,
                fontWeight: FontWeight.w600,
                fontFamily: 'KhmerOSBattambang',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
