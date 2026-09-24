import 'dart:core';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_order.dart';
import '../api/api_customer.dart';
import '../models/customer.dart';
import 'addcustomer/add_customer_dialog.dart';
import 'card_manager.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int? _userId;
  String phone = '';
  String name = '';
  final TextEditingController searchCustomersByName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
    });
  }

  // 🟢 ហៅ Dialog ពី File ខាងក្រៅមកប្រើ
  void _showAddCustomerDialog(
    BuildContext context,
    StateSetter setStateSheet,
    String initialName,
    Function(int) onCustomerCreated,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AddCustomerDialog(
          initialName: initialName,
          onCustomerCreated: (newCustId) {
            onCustomerCreated(newCustId);
            setStateSheet(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CartManager.cartItemCount,
      builder: (context, count, child) {
        final items = CartManager.cartItems;
        double totalAmount = items.fold(
          0,
          (sum, item) => sum + (item.product.sellingPrice * item.quantity),
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: const Text(
                "Cart & Payment",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your cart is empty",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemBuilder: (context, index) {
                          final cartItem = items[index];
                          final product = cartItem.product;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      product.imageUrl != null &&
                                          product.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          product.imageUrl!,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildPlaceholderImage(),
                                        )
                                      : _buildPlaceholderImage(),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "\$${product.sellingPrice.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () => setState(
                                        () => CartManager.removeItem(index),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade400,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => setState(
                                              () => CartManager.updateQuantity(
                                                index,
                                                -1,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.remove,
                                                color: Colors.orange.shade700,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              '${cartItem.quantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => setState(
                                              () => CartManager.updateQuantity(
                                                index,
                                                1,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.add,
                                                color: Colors.green.shade700,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Amount",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  "\$${totalAmount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () =>
                                    _showAdvancedPaymentBottomSheet(
                                      context,
                                      totalAmount,
                                    ),
                                child: const Text(
                                  "Proceed to Payment",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFF4F46E5),
        size: 30,
      ),
    );
  }

  void _showAdvancedPaymentBottomSheet(
    BuildContext parentContext,
    double totalAmount,
  ) {
    String cashGivenStr = totalAmount.toStringAsFixed(2);
    String paymentMethod = 'cash';
    String orderType = 'dine_in';
    String currencyType = 'USD';
    const double exchangeRate = 4100.0;

    int? selectedCustomerId;
    final TextEditingController customerNameController = TextEditingController(
      text: '',
    );
    final TextEditingController customerPhoneController =
        TextEditingController();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            double cashGiven = double.tryParse(cashGivenStr) ?? 0;

            double changeUSD = cashGiven >= totalAmount
                ? cashGiven - totalAmount
                : 0;
            double totalKHR = totalAmount * exchangeRate;
            double cashGivenKHR = currencyType == 'KHR'
                ? cashGiven
                : (cashGiven * exchangeRate);
            double changeKHR = cashGivenKHR >= totalKHR
                ? cashGivenKHR - totalKHR
                : 0;

            void onKeyPressed(String value) {
              setStateSheet(() {
                if (value == 'C') {
                  cashGivenStr = '0';
                } else if (value == '⌫') {
                  if (cashGivenStr.isNotEmpty && cashGivenStr != '0') {
                    cashGivenStr = cashGivenStr.substring(
                      0,
                      cashGivenStr.length - 1,
                    );
                    if (cashGivenStr.isEmpty) cashGivenStr = '0';
                  }
                } else {
                  if (cashGivenStr == '0') {
                    cashGivenStr = value;
                  } else {
                    cashGivenStr += value;
                  }
                }
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ការទូទាត់ប្រាក់ (Payment)",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "ជ្រើសរើសប្រភេទ និងវិធីសាស្ត្រទូទាត់",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "ទឹកប្រាក់ត្រូវបង់សរុប",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "\$${totalAmount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  "= ${totalKHR.toStringAsFixed(0)}៛",
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            _buildOrderTypeTab(
                              "ញ៉ាំនៅហាង",
                              Icons.restaurant,
                              orderType == 'dine_in',
                              () {
                                setStateSheet(() => orderType = 'dine_in');
                              },
                            ),
                            _buildOrderTypeTab(
                              "ខ្ចប់",
                              Icons.shopping_bag_outlined,
                              orderType == 'take_away',
                              () {
                                setStateSheet(() => orderType = 'take_away');
                              },
                            ),
                            _buildOrderTypeTab(
                              "ដឹកជញ្ជូន",
                              Icons.delivery_dining,
                              orderType == 'delivery',
                              () {
                                setStateSheet(() => orderType = 'delivery');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: customerNameController,
                                    keyboardType: TextInputType.name,
                                    decoration: const InputDecoration(
                                      labelText:
                                          "ស្វែងរកតាមឈ្មោះ (Customer Name)",
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.person_search_outlined,
                                        color: Color(0xFF4F46E5),
                                        size: 18,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (val) {
                                      setStateSheet(() {
                                        name = val.trim();
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  _showAddCustomerDialog(
                                    context,
                                    setStateSheet,
                                    customerNameController.text.trim(),
                                    (newCustId) {
                                      setStateSheet(() {
                                        selectedCustomerId = newCustId;
                                        name = customerNameController.text
                                            .trim();
                                      });
                                    },
                                  );
                                },
                                child: const Icon(
                                  Icons.person_add_alt_1_outlined,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: FutureBuilder<List<Customer>>(
                              future: ApiCustomer().getAllCustomers().then((
                                list,
                              ) {
                                if (name.isEmpty) return list;
                                return list
                                    .where(
                                      (c) => (c.name ?? '')
                                          .toLowerCase()
                                          .contains(name.toLowerCase()),
                                    )
                                    .toList();
                              }),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const LinearProgressIndicator(
                                    color: Color(0xFF4F46E5),
                                  );
                                }
                                final List<Customer> customers =
                                    snapshot.data ?? [];

                                final bool isValidCustomer =
                                    selectedCustomerId == null ||
                                    customers.any(
                                      (cust) => cust.id == selectedCustomerId,
                                    );

                                return DropdownButtonFormField<int?>(
                                  initialValue: isValidCustomer
                                      ? selectedCustomerId
                                      : null,
                                  isDense: true,
                                  dropdownColor: Colors.white,
                                  decoration: const InputDecoration(
                                    labelText: "អតិថិជន (Select Customer)",
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF4F46E5),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text(
                                        "អតិថិជនទូទៅ (Guest)",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    ...customers.map((cust) {
                                      return DropdownMenuItem<int?>(
                                        value: cust.id,
                                        child: Text(
                                          "${cust.name} (${cust.phone ?? 'No Phone'})",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    setStateSheet(() {
                                      selectedCustomerId = val;
                                      if (val != null) {
                                        final matched = customers.firstWhere(
                                          (c) => c.id == val,
                                          orElse: () => customers.first,
                                        );
                                        customerNameController.text =
                                            matched.name!;
                                        customerPhoneController.text =
                                            matched.phone ?? '';
                                      } else {
                                        customerNameController.text = '';
                                        customerPhoneController.clear();
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            _buildMethodTab(
                              "សាច់ប្រាក់",
                              Icons.payments_rounded,
                              paymentMethod == 'cash',
                              () {
                                setStateSheet(() => paymentMethod = 'cash');
                              },
                            ),
                            _buildMethodTab(
                              "KHQR",
                              Icons.qr_code_2_rounded,
                              paymentMethod == 'khqr',
                              () {
                                setStateSheet(() => paymentMethod = 'khqr');
                              },
                            ),
                            _buildMethodTab(
                              "កាត",
                              Icons.credit_card,
                              paymentMethod == 'card',
                              () {
                                setStateSheet(() => paymentMethod = 'card');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (paymentMethod == 'cash') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "រូបិយប័ណ្ណទូទាត់ (Currency)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  Text(
                                    "1\$ = ${exchangeRate.toStringAsFixed(0)}៛",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildCurrencyTab(
                                    "ដុល្លារអាមេរិក (\$)",
                                    "🇺🇸",
                                    'USD',
                                    currencyType == 'USD',
                                    () {
                                      setStateSheet(() {
                                        if (currencyType == 'KHR') {
                                          double currentVal =
                                              double.tryParse(cashGivenStr) ??
                                              0;
                                          double inUSD =
                                              currentVal / exchangeRate;
                                          cashGivenStr = inUSD.toStringAsFixed(
                                            2,
                                          );
                                        }
                                        currencyType = 'USD';
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCurrencyTab(
                                    "ប្រាក់រៀលខ្មែរ (៛)",
                                    "🇰🇭",
                                    'KHR',
                                    currencyType == 'KHR',
                                    () {
                                      setStateSheet(() {
                                        if (currencyType == 'USD') {
                                          double currentVal =
                                              double.tryParse(cashGivenStr) ??
                                              0;
                                          double inKHR =
                                              currentVal * exchangeRate;
                                          cashGivenStr = inKHR.toStringAsFixed(
                                            0,
                                          );
                                        }
                                        currencyType = 'KHR';
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF4F46E5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "ប្រាក់ទទួលបាន",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currencyType == 'USD'
                                                ? "\$$cashGivenStr"
                                                : "$cashGivenStr៛",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "ប្រាក់អាប់",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currencyType == 'USD'
                                                ? "\$${changeUSD.toStringAsFixed(2)}"
                                                : "${changeKHR.toStringAsFixed(0)}៛",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: currencyType == 'USD'
                                    ? [5, 10, 20, 50, 100].map((amt) {
                                        return OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor:
                                                Colors.grey.shade50,
                                            minimumSize: const Size(54, 34),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () => setStateSheet(
                                            () => cashGivenStr = amt.toString(),
                                          ),
                                          child: Text(
                                            "\$$amt",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        );
                                      }).toList()
                                    : [10000, 20000, 50000, 100000].map((amt) {
                                        return OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor:
                                                Colors.grey.shade50,
                                            minimumSize: const Size(64, 34),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () => setStateSheet(
                                            () => cashGivenStr = amt.toString(),
                                          ),
                                          child: Text(
                                            "$amt៛",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 2.7,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            children:
                                [
                                  '1',
                                  '2',
                                  '3',
                                  '4',
                                  '5',
                                  '6',
                                  '7',
                                  '8',
                                  '9',
                                  '.',
                                  '0',
                                  '⌫',
                                ].map((key) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade50,
                                      foregroundColor: const Color(0xFF1E293B),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.zero,
                                      side: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    onPressed: () => onKeyPressed(key),
                                    child: Text(
                                      key,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ] else ...[
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "assets/qrcode.jpg",
                                    height: 130,
                                    width: 130,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.qr_code,
                                      size: 70,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "សូមស្កេន QR Code ដើម្បីទូទាត់ប្រាក់",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _handlePaymentSubmission(
                              parentContext,
                              totalAmount,
                              cashGiven,
                              currencyType == 'KHR'
                                  ? (cashGiven / exchangeRate)
                                  : cashGiven,
                              paymentMethod,
                              customerNameController.text.trim().isEmpty
                                  ? 'Guest'
                                  : customerNameController.text.trim(),
                              customerPhoneController.text.trim(),
                            );
                          },
                          child: Text(
                            paymentMethod == 'cash'
                                ? "បង់ប្រាក់ (\$${totalAmount.toStringAsFixed(2)})"
                                : "បញ្ជាក់ការទូទាត់ QR",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderTypeTab(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyTab(
    String title,
    String flagEmoji,
    String type,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flagEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isSelected
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaymentSubmission(
    BuildContext parentContext,
    double totalAmount,
    double cashGiven,
    double actualUSDReceived,
    String paymentMethod,
    String customerName,
    String customerPhone,
  ) async {
    if (paymentMethod == 'cash' && actualUSDReceived < totalAmount) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text("Insufficient cash given!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double changeAmount = actualUSDReceived - totalAmount;
    List<Map<String, dynamic>> orderItems = CartManager.cartItems.map((
      cartItem,
    ) {
      return {
        'product_id': cartItem.product.id,
        'product_name': cartItem.product.name,
        'unit_price': cartItem.product.sellingPrice,
        'quantity': cartItem.quantity,
        'total_price': cartItem.product.sellingPrice * cartItem.quantity,
      };
    }).toList();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    ApiOrder apiOrder = ApiOrder();
    bool isSuccess = false;
    try {
      isSuccess = await apiOrder.createOrderWithPayment(
        orderNumber: "ORD-${DateTime.now().millisecondsSinceEpoch}",
        customerName: customerName.isEmpty ? 'Guest' : customerName,
        customerPhone: customerPhone.isEmpty ? null : customerPhone,
        userId: _userId ?? 1,
        subtotal: totalAmount,
        discount: 0.0,
        tax: 0.0,
        total: totalAmount,
        paymentMethod: paymentMethod,
        amountPaid: paymentMethod == 'cash' ? actualUSDReceived : totalAmount,
        changeAmount: paymentMethod == 'cash' ? changeAmount : 0.0,
        items: orderItems,
      );
    } catch (e) {
      isSuccess = false;
    }

    if (!parentContext.mounted) return;
    Navigator.pop(parentContext);

    if (isSuccess) {
      _showSuccessDialog(
        parentContext,
        paymentMethod == 'cash' ? changeAmount : 0.0,
      );
    } else {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text("Failed to process payment."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _showSuccessDialog(BuildContext parentContext, double changeAmount) {
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext successContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 56,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "Payment Successful!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),

              const Text(
                "ការទូទាត់ប្រាក់បានសម្រេចជោគជ័យ",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              if (changeAmount > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ប្រាក់អាប់ (Change):",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        "\$${changeAmount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 🟢 ប៊ូតុង Done បញ្ចប់សកម្មភាព
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(successContext);
                    CartManager.clearCart();
                    Navigator.pop(parentContext, true);
                  },
                  child: const Text(
                    "យល់ព្រម (Done)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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
}
