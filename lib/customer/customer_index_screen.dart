import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/api/api_customer.dart';
import 'package:pos_inventory/customer/customer_create_screen.dart';
import 'package:pos_inventory/customer/customer_update_screen.dart';
import 'package:pos_inventory/customer/customer_detail_screen.dart';
import 'package:pos_inventory/models/customer.dart';

class _C {
  static const navy = Color(0xFF0E2A47);
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF2E9E6B);
  static const amber = Color(0xFFB7791F);

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
  Color get ink => dark ? Colors.white : const Color(0xFF142033);
  Color get muted => dark ? const Color(0xFF9AA7B8) : const Color(0xFF6C7A8E);
  Color get line => dark ? const Color(0xFF2B3542) : const Color(0xFFE0E6EE);
  Color get hero => dark ? const Color(0xFF0B2038) : _C.navy;
}

const _font = 'KhmerOSBattambang';

TextStyle _t(double size, FontWeight w, Color c, {double? height}) => TextStyle(
  fontSize: size,
  fontWeight: w,
  color: c,
  fontFamily: _font,
  height: height,
);

class CustomerIndexScreen extends StatefulWidget {
  const CustomerIndexScreen({super.key});

  @override
  State<CustomerIndexScreen> createState() => _CustomerIndexScreenState();
}

class _CustomerIndexScreenState extends State<CustomerIndexScreen> {
  final ApiCustomer apiCustomer = ApiCustomer();

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    apiCustomer.getAllCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'KhmerOSBattambang',
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? _C.red : _C.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSuccessDialog(String message, {VoidCallback? onDeleteOrClose}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final p = _P(isDarkMode);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _C.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text("ជោគជ័យ!", style: _t(20, FontWeight.bold, p.ink)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _t(14, FontWeight.w400, p.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (onDeleteOrClose != null) {
                      onDeleteOrClose();
                    }
                  },
                  child: const Text(
                    "យល់ព្រម",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KhmerOSBattambang',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(int customerId, String customerName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final p = _P(isDarkMode);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _C.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "បញ្ជាក់ការលុប",
                  style: TextStyle(
                    fontFamily: 'KhmerOSBattambang',
                    color: _C.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "តើអ្នកពិតជាចង់លុបអតិថិជនឈ្មោះ \"$customerName\" នេះមែនទេ?",
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontSize: 14,
              height: 1.5,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "បោះបង់",
                style: TextStyle(
                  fontFamily: 'KhmerOSBattambang',
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                bool success = await ApiCustomer().deleteCustomer(customerId);
                if (!mounted) return;

                if (success) {
                  _showSuccessDialog(
                    "បានលុបអតិថិជនចេញពីប្រព័ន្ធដោយជោគជ័យ!",
                    onDeleteOrClose: () {
                      setState(() {});
                    },
                  );
                } else {
                  _showSnackBar("មានបញ្ហាក្នុងការលុបអតិថិជន!", isError: true);
                }
              },
              child: const Text(
                "លុប",
                style: TextStyle(
                  fontFamily: 'KhmerOSBattambang',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _heroButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 21),
        color: Colors.white,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildHero(BuildContext context, _P p) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        Navigator.of(context).canPop() ? 4 : 20,
        top + 8,
        12,
        18,
      ),
      decoration: BoxDecoration(
        color: p.hero,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Expanded(
            child: _isSearching
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        fontFamily: 'KhmerOSBattambang',
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: "ស្វែងរកឈ្មោះ ឬអ៊ីម៉ែល...",
                        hintStyle: TextStyle(
                          fontFamily: 'KhmerOSBattambang',
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 14,
                        ),
                        icon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "បញ្ជីអតិថិជន",
                        style: _t(20, FontWeight.bold, Colors.white),
                      ),
                      Text(
                        "Customers",
                        style: _t(
                          12,
                          FontWeight.w500,
                          Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
          ),
          _heroButton(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            _isSearching ? 'បិទការស្វែងរក' : 'ស្វែងរកអតិថិជន',
            () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = "";
                }
              });
            },
          ),
          _heroButton(Icons.refresh_rounded, 'ផ្ទុកទិន្នន័យឡើងវិញ', () {
            setState(() {
              apiCustomer.getAllCustomers();
            });
          }),
        ],
      ),
    );
  }

  Widget _messageState(
    _P p, {
    required IconData icon,
    required Color color,
    required String text,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: _t(14.5, FontWeight.bold, p.muted, height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  Widget _infoLine(_P p, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: p.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(12.5, FontWeight.w500, p.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: _t(11.5, FontWeight.w700, color),
            ),
          ),
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
              child: FutureBuilder<List<Customer>>(
                future: apiCustomer.getAllCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _C.navy),
                    );
                  } else if (snapshot.hasError) {
                    return _messageState(
                      p,
                      icon: Icons.error_outline_rounded,
                      color: _C.red,
                      text: "មានបញ្ហា៖ ${snapshot.error}",
                      action: FilledButton.icon(
                        onPressed: () => setState(() {}),
                        style: FilledButton.styleFrom(
                          backgroundColor: _C.navy,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          "ព្យាយាមម្តងទៀត",
                          style: TextStyle(fontFamily: 'KhmerOSBattambang'),
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _messageState(
                      p,
                      icon: Icons.people_outline_rounded,
                      color: _C.navy,
                      text: "មិនមានទិន្នន័យអតិថិជនទេ",
                    );
                  }

                  final allCustomers = snapshot.data!;
                  final customers = allCustomers.where((cust) {
                    final nameLower = (cust.name ?? '').toLowerCase();
                    final emailLower = (cust.email ?? '').toLowerCase();
                    return nameLower.contains(_searchQuery) ||
                        emailLower.contains(_searchQuery);
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _C.navy.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.people_alt_rounded,
                                size: 18,
                                color: isDarkMode ? Colors.white : _C.navy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "ចំនួនអតិថិជនសរុប៖",
                                style: _t(13.5, FontWeight.w600, p.muted),
                              ),
                            ),
                            Text(
                              "${customers.length} នាក់",
                              style: _t(
                                17,
                                FontWeight.bold,
                                isDarkMode ? Colors.white : _C.navy,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: customers.isEmpty
                            ? _messageState(
                                p,
                                icon: Icons.search_off_rounded,
                                color: p.muted,
                                text: "រកមិនឃើញអតិថិជនដែលស្វែងរកទេ",
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  100,
                                ),
                                itemCount: customers.length,
                                itemBuilder: (context, index) {
                                  final cust = customers[index];
                                  final customerName =
                                      cust.name ?? 'គ្មានឈ្មោះ';
                                  final customerEmail = cust.email ?? '';
                                  final int invoiceCount =
                                      cust.ordersCount ?? 0;

                                  final Color avatarColor =
                                      customerName.isNotEmpty
                                      ? _C.avatarColors[customerName.codeUnitAt(
                                              0,
                                            ) %
                                            _C.avatarColors.length]
                                      : _C.avatarColors[0];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
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
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(22),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CustomerDetailScreen(
                                                    customerId: cust.id,
                                                    customerName: customerName,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            14,
                                            4,
                                            14,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Avatar
                                              Container(
                                                width: 52,
                                                height: 52,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: avatarColor.withValues(
                                                    alpha: 0.14,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                child: Text(
                                                  customerName.isNotEmpty
                                                      ? customerName[0]
                                                            .toUpperCase()
                                                      : 'C',
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : avatarColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 21,
                                                    fontFamily:
                                                        'KhmerOSBattambang',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),

                                              // Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 2,
                                                          ),
                                                      child: Text(
                                                        customerName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: _t(
                                                          16,
                                                          FontWeight.bold,
                                                          p.ink,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    if (customerEmail
                                                        .isNotEmpty)
                                                      _infoLine(
                                                        p,
                                                        Icons
                                                            .mail_outline_rounded,
                                                        customerEmail,
                                                      ),
                                                    if (cust.phone != null &&
                                                        cust.phone!.isNotEmpty)
                                                      _infoLine(
                                                        p,
                                                        Icons.phone_outlined,
                                                        "ទូរស័ព្ទ៖ ${cust.phone}",
                                                      ),
                                                    const SizedBox(height: 10),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 6,
                                                      children: [
                                                        _chip(
                                                          Icons
                                                              .receipt_long_rounded,
                                                          "វិក្កយបត្រ (Invoice): $invoiceCount",
                                                          _C.green,
                                                        ),
                                                        _chip(
                                                          Icons.star_rounded,
                                                          "${cust.points}ពិន្ទុ",
                                                          _C.amber,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Menu
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert_rounded,
                                                  color: p.muted,
                                                ),
                                                color: p.card,
                                                elevation: 6,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                onSelected: (String value) async {
                                                  if (value == 'edit') {
                                                    final result =
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                CustomerUpdateScreen(
                                                                  customerId:
                                                                      cust.id,
                                                                ),
                                                          ),
                                                        );

                                                    if (result == true) {
                                                      _showSnackBar(
                                                        "បានអាប់ដេតព័ត៌មានអតិថិជនដោយជោគជ័យ!",
                                                      );
                                                      setState(() {});
                                                    }
                                                  } else if (value ==
                                                      'delete') {
                                                    _showDeleteConfirmDialog(
                                                      cust.id,
                                                      customerName,
                                                    );
                                                  }
                                                },
                                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                  PopupMenuItem<String>(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                6,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: _C.navy
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: Icon(
                                                            Icons.edit_rounded,
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                : _C.navy,
                                                            size: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          'កែសម្រួល',
                                                          style: _t(
                                                            13.5,
                                                            FontWeight.w600,
                                                            p.ink,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                6,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: _C.red
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: const Icon(
                                                            Icons
                                                                .delete_rounded,
                                                            color: _C.red,
                                                            size: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          'លុប',
                                                          style: _t(
                                                            13.5,
                                                            FontWeight.w600,
                                                            _C.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerCreateScreen(),
              ),
            );

            if (result == true) {
              _showSnackBar("បានអាប់ដេតបញ្ជីអតិថិជនថ្មី!");
              setState(() {});
            }
          },
          backgroundColor: _C.navy,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            "បន្ថែមអតិថិជន",
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
