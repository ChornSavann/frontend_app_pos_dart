import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_inventory/order/delivery/delivery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_order.dart';
import '../api/api_customer.dart';
import '../models/customer.dart';
import '../msg/appSnackBar.dart';
import 'addcustomer/add_customer_dialog.dart';
import 'card_manager.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF0F4F4);
  static const ink = Color(0xFF0F1F1D);
  static const muted = Color(0xFF5E7476);
  static const line = Color(0xFFE3EBEA);
  static const brand = Color(0xFF0F766E);
  static const heroA = Color(0xFF063B37);
  static const heroB = Color(0xFF14A596);
  static const hot = Color(0xFFEF5B16);
  static const danger = Color(0xFFD32F2F);
  static const money = Color(0xFF0B6B3F);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: spacing);

BoxDecoration _card({double radius = 20}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: _C.heroA.withValues(alpha: 0.07),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ],
);

// ─────────────────────────────────────────────────────────────
// Cart screen
// ─────────────────────────────────────────────────────────────
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int? _userId;
  String phone = '';
  String name = '';
  double discountAmount = 0.0;
  double taxAmount = 0.0;

  final TextEditingController searchCustomersByName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    searchCustomersByName.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userId = prefs.getInt('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CartManager.cartItemCount,
      builder: (context, count, child) {
        final items = CartManager.cartItems;

        double subtotal = 0;
        for (var item in items) {
          subtotal += item.product.sellingPrice * item.quantity;
        }
        double totalAmount = (subtotal - discountAmount) + taxAmount;
        if (totalAmount < 0) totalAmount = 0.0;

        var totalQty = 0;
        for (final it in items) {
          totalQty += it.quantity as int;
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: _C.bg,
            body: Column(
              children: [
                _CartHero(
                  itemCount: items.length,
                  qty: totalQty,
                  subtotal: subtotal,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyCart()
                      : ListView.separated(
                    itemCount: items.length,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cartItem = items[index];
                      final product = cartItem.product;
                      return _CartItemCard(
                        name: product.name,
                        price: product.sellingPrice,
                        quantity: cartItem.quantity,
                        imageUrl: product.imageUrl,
                        onDelete: () {
                          HapticFeedback.mediumImpact();
                          setState(() => CartManager.removeItem(index));
                        },
                        onMinus: () {
                          HapticFeedback.selectionClick();
                          setState(() => CartManager.updateQuantity(context, index, -1));
                        },
                        onPlus: () {
                          HapticFeedback.selectionClick();
                          setState(() => CartManager.updateQuantity(context, index, 1));
                        },
                      );
                    },
                  ),
                ),
                if (items.isNotEmpty)
                  _SummaryBar(
                    subtotal: subtotal,
                    discount: discountAmount,
                    tax: taxAmount,
                    total: totalAmount,
                    onEditDiscount: () => _showEditDialog(
                      context,
                      'Edit Discount',
                      discountAmount,
                          (val) => setState(() => discountAmount = val),
                    ),
                    onEditTax: () => _showEditDialog(
                      context,
                      'Edit Order Tax',
                      taxAmount,
                          (val) => setState(() => taxAmount = val),
                    ),
                    onHold: () {
                      AppSnackBar.showSuccess(context, 'Cart put on hold successfully!');
                    },
                    onClear: () => _confirmClear(context),
                    onPay: () => _showAdvancedPaymentBottomSheet(context, totalAmount),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _C.danger, size: 34),
              ),
              const SizedBox(height: 16),
              Text('Clear Cart', style: _t(18, FontWeight.w800, _C.ink)),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to remove all items from the cart?',
                textAlign: TextAlign.center,
                style: _t(13.5, FontWeight.w400, _C.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.ink,
                        side: const BorderSide(color: _C.line),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel', style: _t(14, FontWeight.w800, _C.ink)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        CartManager.clearCart();
                        Navigator.pop(dialogContext);
                        AppSnackBar.showSuccess(context, 'Cart cleared successfully!');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Clear', style: _t(14, FontWeight.w800, Colors.white)),
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

  // ───────────────────────────────────────────────────────────
  // Payment bottom sheet
  // ───────────────────────────────────────────────────────────
  void _showAdvancedPaymentBottomSheet(BuildContext parentContext, double totalAmount) {
    String cashGivenStr = totalAmount.toStringAsFixed(2);
    String paymentMethod = 'cash';
    String orderType = 'dine_in';
    String currencyType = 'USD';
    const double exchangeRate = 4100.0;

    int? selectedCustomerId;
    final TextEditingController customerNameController = TextEditingController(text: '');
    final TextEditingController customerPhoneController = TextEditingController();

    String deliveryAddress = '';
    double deliveryFee = 0.0;
    String? deliveryPartner;
    String? receiverName;
    String? receiverPhone;
    String? deliveryNote;

    // customers are loaded once (not on every keypress)
    Future<List<Customer>> customersFuture = ApiCustomer().getAllCustomers();
    bool sheetAlive = true;

    void showAddCustomerModal(StateSetter setStateSheet) {
      showDialog(
        context: parentContext,
        builder: (BuildContext dialogContext) {
          return AddCustomerDialog(
            initialName: customerNameController.text.trim(),
            onCustomerCreated: (newCustId) {
              setStateSheet(() {
                selectedCustomerId = newCustId;
                customersFuture = ApiCustomer().getAllCustomers();
              });
              customersFuture.then((list) {
                if (!sheetAlive) return;
                for (final c in list) {
                  if (c.id == newCustId) {
                    setStateSheet(() {
                      customerNameController.text = c.name ?? customerNameController.text;
                      customerPhoneController.text = c.phone ?? '';
                    });
                    break;
                  }
                }
              }).catchError((_) {});
            },
          );
        },
      );
    }

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final double finalTotalAmount =
                totalAmount + (orderType == 'delivery' ? deliveryFee : 0.0);
            final double cashGiven = double.tryParse(cashGivenStr) ?? 0;

            final double changeUSD =
            cashGiven >= finalTotalAmount ? cashGiven - finalTotalAmount : 0;
            final double totalKHR = finalTotalAmount * exchangeRate;
            final double cashGivenKHR =
            currencyType == 'KHR' ? cashGiven : (cashGiven * exchangeRate);
            final double changeKHR = cashGivenKHR >= totalKHR ? cashGivenKHR - totalKHR : 0;

            void onKeyPressed(String value) {
              setStateSheet(() {
                if (value == 'C') {
                  cashGivenStr = '0';
                } else if (value == '⌫') {
                  if (cashGivenStr.isNotEmpty && cashGivenStr != '0') {
                    cashGivenStr = cashGivenStr.substring(0, cashGivenStr.length - 1);
                    if (cashGivenStr.isEmpty) cashGivenStr = '0';
                  }
                } else {
                  if (cashGivenStr == '0' && value != '.') {
                    cashGivenStr = value;
                  } else {
                    cashGivenStr += value;
                  }
                }
              });
            }

            void applyDelivery(Map<String, dynamic> deliveryData) {
              setStateSheet(() {
                deliveryAddress = deliveryData['address'];
                deliveryFee = deliveryData['delivery_fee'];
                customerNameController.text = deliveryData['name'];
                customerPhoneController.text = deliveryData['phone'];
                deliveryPartner = deliveryData['delivery_partner'];
                receiverName = deliveryData['name'];
                receiverPhone = deliveryData['phone'];
                deliveryNote = deliveryData['note'];
              });
            }

            void openDelivery() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryScreen(
                    totalAmount: totalAmount,
                    onConfirmDelivery: (deliveryData) => applyDelivery(deliveryData),
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // ── handle + header (fixed) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _C.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SheetHeader(
                          totalUsd: finalTotalAmount,
                          totalKhr: totalKHR,
                          onClose: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),

                  // ── scrollable body ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        14,
                        16,
                        MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // order type
                          _Segmented(
                            selected: orderType,
                            items: const [
                              _SegItem('dine_in', 'ញ៉ាំនៅហាង', Icons.restaurant_rounded),
                              _SegItem('take_away', 'ខ្ចប់', Icons.shopping_bag_outlined),
                              _SegItem('delivery', 'ដឹកជញ្ជូន', Icons.delivery_dining_rounded),
                            ],
                            onChanged: (v) {
                              setStateSheet(() => orderType = v);
                              if (v == 'delivery') openDelivery();
                            },
                          ),
                          const SizedBox(height: 12),

                          if (orderType == 'delivery' && deliveryAddress.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                              decoration: BoxDecoration(
                                color: _C.hot.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _C.hot.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: _C.hot),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('អាសយដ្ឋានដឹកជញ្ជូន',
                                                style: _t(11.5, FontWeight.w800, _C.hot)),
                                            const Spacer(),
                                            Text('សេវា \$${deliveryFee.toStringAsFixed(2)}',
                                                style: _t(11.5, FontWeight.w800, _C.brand)),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(deliveryAddress,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: _t(13, FontWeight.w600, _C.ink, height: 1.35)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 18, color: _C.hot),
                                    onPressed: openDelivery,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // customer (tap to choose)
                          _CustomerTile(
                            name: customerNameController.text.trim(),
                            phone: customerPhoneController.text.trim(),
                            isRegistered: selectedCustomerId != null,
                            onTap: () async {
                              FocusScope.of(context).unfocus();
                              final result = await showModalBottomSheet<_PickResult>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _CustomerPickerSheet(
                                  customersFuture: customersFuture,
                                  selectedId: selectedCustomerId,
                                  currentName: customerNameController.text.trim(),
                                ),
                              );
                              if (result == null || !context.mounted) return;
                              if (result.addNew) {
                                customerNameController.text = result.name;
                                showAddCustomerModal(setStateSheet);
                                return;
                              }
                              setStateSheet(() {
                                selectedCustomerId = result.id;
                                customerNameController.text = result.name;
                                customerPhoneController.text = result.phone;
                                name = result.name;
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // payment method
                          _Segmented(
                            selected: paymentMethod,
                            items: const [
                              _SegItem('cash', 'សាច់ប្រាក់', Icons.payments_rounded),
                              _SegItem('khqr', 'KHQR', Icons.qr_code_2_rounded),
                              _SegItem('card', 'កាត', Icons.credit_card_rounded),
                            ],
                            onChanged: (v) => setStateSheet(() => paymentMethod = v),
                          ),
                          const SizedBox(height: 12),

                          if (paymentMethod == 'cash') ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: _card(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('រូបិយប័ណ្ណទូទាត់',
                                          style: _t(13.5, FontWeight.w800, _C.ink)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _C.bg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('1\$ = ${exchangeRate.toStringAsFixed(0)}៛',
                                            style: _t(11, FontWeight.w700, _C.muted)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _Segmented(
                                    selected: currencyType,
                                    inner: true,
                                    items: const [
                                      _SegItem('USD', 'ដុល្លារ (\$)', null, emoji: '🇺🇸'),
                                      _SegItem('KHR', 'រៀល (៛)', null, emoji: '🇰🇭'),
                                    ],
                                    onChanged: (v) {
                                      setStateSheet(() {
                                        if (v == 'USD' && currencyType == 'KHR') {
                                          final cur = double.tryParse(cashGivenStr) ?? 0;
                                          cashGivenStr = (cur / exchangeRate).toStringAsFixed(2);
                                        } else if (v == 'KHR' && currencyType == 'USD') {
                                          final cur = double.tryParse(cashGivenStr) ?? 0;
                                          cashGivenStr = (cur * exchangeRate).toStringAsFixed(0);
                                        }
                                        currencyType = v;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AmountBox(
                                          label: 'ប្រាក់ទទួលបាន',
                                          value: currencyType == 'USD'
                                              ? '\$$cashGivenStr'
                                              : '$cashGivenStr៛',
                                          color: _C.brand,
                                          filled: true,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _AmountBox(
                                          label: 'ប្រាក់អាប់',
                                          value: currencyType == 'USD'
                                              ? '\$${changeUSD.toStringAsFixed(2)}'
                                              : '${changeKHR.toStringAsFixed(0)}៛',
                                          color: _C.money,
                                          filled: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 36,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _QuickChip(
                                          label: 'ស្មើ (Exact)',
                                          highlight: true,
                                          onTap: () => setStateSheet(() {
                                            cashGivenStr = currencyType == 'USD'
                                                ? finalTotalAmount.toStringAsFixed(2)
                                                : totalKHR.toStringAsFixed(0);
                                          }),
                                        ),
                                        ...(currencyType == 'USD'
                                            ? [5, 10, 20, 50, 100]
                                            : [10000, 20000, 50000, 100000])
                                            .map(
                                              (amt) => _QuickChip(
                                            label: currencyType == 'USD' ? '\$$amt' : '$amt៛',
                                            onTap: () => setStateSheet(
                                                  () => cashGivenStr = amt.toString(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: _card(),
                              child: GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 2.6,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                children: [
                                  '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫',
                                ].map((key) {
                                  final isBack = key == '⌫';
                                  return Material(
                                    color: isBack
                                        ? _C.danger.withValues(alpha: 0.08)
                                        : _C.bg,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        onKeyPressed(key);
                                      },
                                      child: Center(
                                        child: isBack
                                            ? const Icon(Icons.backspace_outlined,
                                            size: 20, color: _C.danger)
                                            : Text(key, style: _t(20, FontWeight.w800, _C.ink)),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ] else ...[
                            Container(
                              height: 230,
                              width: double.infinity,
                              decoration: _card(),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: _C.line),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Image.asset(
                                        'assets/qrcode.jpg',
                                        height: 130,
                                        width: 130,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 80,
                                          color: _C.muted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text('សូមស្កេន QR Code ដើម្បីទូទាត់ប្រាក់',
                                        style: _t(13, FontWeight.w800, _C.ink)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── pay button (fixed) ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: _C.heroA.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: _GradientButton(
                        height: 54,
                        label: paymentMethod == 'cash'
                            ? 'បង់ប្រាក់ (\$${finalTotalAmount.toStringAsFixed(2)})'
                            : 'បញ្ជាក់ការទូទាត់ QR',
                        icon: Icons.check_circle_outline_rounded,
                        onTap: () {
                          if (orderType == 'delivery' && deliveryAddress.isEmpty) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text('សូមបំពេញព័ត៌មាន និងអាសយដ្ឋានដឹកជញ្ជូនសិន!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(sheetContext);
                          _handlePaymentSubmission(
                            parentContext,
                            finalTotalAmount,
                            cashGiven,
                            currencyType == 'KHR' ? (cashGiven / exchangeRate) : cashGiven,
                            paymentMethod,
                            selectedCustomerId,
                            customerNameController.text.trim().isEmpty
                                ? 'Guest'
                                : customerNameController.text.trim(),
                            customerPhoneController.text.trim(),
                            orderType,
                            deliveryAddress,
                            deliveryFee,
                            pickupAddress: 'Store Location',
                            deliveryPartner: deliveryPartner ?? 'Standard',
                            receiverName: receiverName ?? customerNameController.text.trim(),
                            receiverPhone: receiverPhone ?? customerPhoneController.text.trim(),
                            note: deliveryNote,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => sheetAlive = false);
  }

  Future<void> _showEditDialog(
      BuildContext context,
      String title,
      double initialValue,
      Function(double) onSaved,
      ) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _EditAmountDialog(title: title, initialValue: initialValue),
    );
    if (value != null && mounted) onSaved(value);
  }

  void _showInsufficientCashDialog(BuildContext context, double shortAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _C.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: _C.danger, size: 34),
                ),
                const SizedBox(height: 16),
                Text('ប្រាក់មិនគ្រប់គ្រាន់!', style: _t(18, FontWeight.w800, _C.ink)),
                const SizedBox(height: 8),
                Text(
                  'ប្រាក់បានបង់មិនទាន់គ្រប់គ្រាន់សម្រាប់ការទូទាត់ទេ។\nសូមបញ្ចូលទឹកប្រាក់បន្ថែមឱ្យបានស្មើ ឬច្រើនជាងទឹកប្រាក់សរុប។',
                  textAlign: TextAlign.center,
                  style: _t(13.5, FontWeight.w400, _C.muted, height: 1.5),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ខ្វះ  ', style: _t(13, FontWeight.w600, _C.danger)),
                      Text('\$${shortAmount.toStringAsFixed(2)}',
                          style: _t(18, FontWeight.w800, _C.danger)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('យល់ព្រម (OK)', style: _t(14.5, FontWeight.w800, Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePaymentSubmission(
      BuildContext parentContext,
      double totalAmount,
      double cashGiven,
      double actualUSDReceived,
      String paymentMethod,
      int? customerId,
      String customerName,
      String customerPhone,
      String orderType,
      String deliveryAddress,
      double deliveryFee, {
        String? pickupAddress,
        String? deliveryPartner,
        String? receiverName,
        String? receiverPhone,
        String? note,
      }) async {
    if (paymentMethod == 'cash' && actualUSDReceived < totalAmount) {
      _showInsufficientCashDialog(parentContext, totalAmount - actualUSDReceived);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int currentUserId = prefs.getInt('user_id') ?? _userId ?? 1;

    double changeAmount = actualUSDReceived - totalAmount;
    List<Map<String, dynamic>> orderItems = CartManager.cartItems.map((cartItem) {
      return {
        'product_id': cartItem.product.id,
        'product_name': cartItem.product.name,
        'unit_price': cartItem.product.sellingPrice,
        'quantity': cartItem.quantity,
        'total_price': cartItem.product.sellingPrice * cartItem.quantity,
      };
    }).toList();

    if (!parentContext.mounted) return;
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: _C.brand),
          ),
        ),
      ),
    );

    ApiOrder apiOrder = ApiOrder();
    bool isSuccess = false;
    try {
      isSuccess = await apiOrder.createOrderWithPayment(
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        customerId: customerId,
        customerName: customerName.isEmpty ? 'Guest' : customerName,
        customerPhone: customerPhone.isEmpty ? null : customerPhone,
        userId: currentUserId,
        subtotal: totalAmount - (orderType == 'delivery' ? deliveryFee : 0),
        discount: discountAmount,
        tax: taxAmount,
        total: totalAmount,
        paymentMethod: paymentMethod,
        amountPaid: paymentMethod == 'cash' ? actualUSDReceived : totalAmount,
        changeAmount: paymentMethod == 'cash' ? changeAmount : 0.0,
        orderType: orderType,
        deliveryAddress: orderType == 'delivery' ? deliveryAddress : null,
        deliveryFee: orderType == 'delivery' ? deliveryFee : 0.0,
        pickupAddress: pickupAddress,
        deliveryPartner: deliveryPartner,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        note: note,
        items: orderItems,
      );
    } catch (e) {
      isSuccess = false;
    }

    if (!parentContext.mounted) return;
    Navigator.pop(parentContext);

    if (isSuccess) {
      _showSuccessDialog(parentContext, paymentMethod == 'cash' ? changeAmount : 0.0);
    } else {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('Failed to process payment.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext parentContext, double changeAmount) {
    HapticFeedback.lightImpact();
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext successContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _C.brand.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: _C.brand, size: 56),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Payment Successful!', style: _t(20, FontWeight.w800, _C.ink)),
                const SizedBox(height: 6),
                Text('ការទូទាត់ប្រាក់បានសម្រេចជោគជ័យ',
                    style: _t(13, FontWeight.w400, _C.muted)),
                if (changeAmount > 0) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _C.brand.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.brand.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ប្រាក់អាប់ (Change)', style: _t(13.5, FontWeight.w700, _C.muted)),
                        Text('\$${changeAmount.toStringAsFixed(2)}',
                            style: _t(22, FontWeight.w800, _C.money, spacing: -0.4)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _GradientButton(
                    height: 50,
                    label: 'យល់ព្រម (Done)',
                    onTap: () {
                      Navigator.pop(successContext);
                      CartManager.clearCart();
                      Navigator.pop(parentContext, true);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Cart widgets
// ─────────────────────────────────────────────────────────────
class _CartHero extends StatelessWidget {
  final int itemCount;
  final int qty;
  final double subtotal;
  final VoidCallback onBack;
  const _CartHero({
    required this.itemCount,
    required this.qty,
    required this.subtotal,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_C.heroA, _C.heroB],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, top + 6, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cart & Payment',
                            style: _t(21, FontWeight.w800, Colors.white, spacing: -0.3)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 5),
                            Text('$itemCount items · $qty pcs',
                                style: _t(12.5, FontWeight.w600,
                                    Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Subtotal',
                            style: _t(10.5, FontWeight.w600,
                                Colors.white.withValues(alpha: 0.85))),
                        Text('\$${subtotal.toStringAsFixed(2)}',
                            style: _t(17, FontWeight.w800, Colors.white, height: 1.1)),
                      ],
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
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: _C.brand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 48, color: _C.brand),
            ),
            const SizedBox(height: 16),
            Text('Your cart is empty', style: _t(17, FontWeight.w800, _C.ink)),
            const SizedBox(height: 6),
            Text('Add products from the menu to start a sale.',
                textAlign: TextAlign.center,
                style: _t(13, FontWeight.w400, _C.muted, height: 1.5)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: _C.brand,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: Text('Add products', style: _t(13.5, FontWeight.w800, Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final VoidCallback onDelete;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CartItemCard({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.onDelete,
    required this.onMinus,
    required this.onPlus,
  });

  Widget _placeholder() => Container(
    width: 62,
    height: 62,
    color: _C.brand.withValues(alpha: 0.1),
    child: const Icon(Icons.shopping_bag_outlined, color: _C.brand, size: 26),
  );

  @override
  Widget build(BuildContext context) {
    final has = imageUrl != null && imageUrl!.isNotEmpty;
    final lineTotal = price * quantity;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _card(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: has
                ? Image.network(
              imageUrl!,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _t(14.5, FontWeight.w800, _C.ink, height: 1.25)),
                const SizedBox(height: 4),
                Text('\$${price.toStringAsFixed(2)} × $quantity',
                    style: _t(12, FontWeight.w500, _C.muted)),
                const SizedBox(height: 4),
                Text('\$${lineTotal.toStringAsFixed(2)}',
                    style: _t(16, FontWeight.w800, _C.money, spacing: -0.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _C.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: _C.danger, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepButton(icon: Icons.remove_rounded, color: _C.hot, onTap: onMinus),
                    SizedBox(
                      width: 28,
                      child: Text('$quantity',
                          textAlign: TextAlign.center,
                          style: _t(14.5, FontWeight.w800, _C.ink)),
                    ),
                    _StepButton(icon: Icons.add_rounded, color: _C.brand, onTap: onPlus),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final VoidCallback onEditDiscount;
  final VoidCallback onEditTax;
  final VoidCallback onHold;
  final VoidCallback onClear;
  final VoidCallback onPay;

  const _SummaryBar({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.onEditDiscount,
    required this.onEditTax,
    required this.onHold,
    required this.onClear,
    required this.onPay,
  });

  Widget _row(String label, String value, {VoidCallback? onEdit, Color? valueColor}) {
    return Row(
      children: [
        Text(label, style: _t(13, FontWeight.w600, _C.muted)),
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _C.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_rounded, size: 11, color: _C.brand),
                  const SizedBox(width: 3),
                  Text('Edit', style: _t(11, FontWeight.w800, _C.brand)),
                ],
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(value, style: _t(13.5, FontWeight.w800, valueColor ?? _C.ink)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _C.heroA.withValues(alpha: 0.09),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _row('Discount', '-\$${discount.toStringAsFixed(2)}',
                onEdit: onEditDiscount, valueColor: _C.danger),
            const SizedBox(height: 8),
            _row('Order Tax', '\$${tax.toStringAsFixed(2)}', onEdit: onEditTax),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: _C.line),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Grand Total', style: _t(14.5, FontWeight.w800, _C.ink)),
                const Spacer(),
                Text('\$${total.toStringAsFixed(2)}',
                    style: _t(26, FontWeight.w800, _C.money, height: 1, spacing: -0.8)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _SquareButton(icon: Icons.pause_rounded, color: _C.brand, tooltip: 'Hold', onTap: onHold),
                const SizedBox(width: 8),
                _SquareButton(
                    icon: Icons.delete_outline_rounded,
                    color: _C.danger,
                    tooltip: 'Clear',
                    onTap: onClear),
                const SizedBox(width: 10),
                Expanded(
                  child: _GradientButton(
                    height: 54,
                    label: 'Payment',
                    icon: Icons.payment_rounded,
                    onTap: onPay,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _SquareButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double height;
  final VoidCallback onTap;
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.heroA, _C.brand, _C.heroB]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.brand.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(15.5, FontWeight.w800, Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Payment sheet widgets
// ─────────────────────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final double totalUsd;
  final double totalKhr;
  final VoidCallback onClose;
  const _SheetHeader({
    required this.totalUsd,
    required this.totalKhr,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ការទូទាត់ប្រាក់ (Payment)', style: _t(17, FontWeight.w800, _C.ink)),
              const SizedBox(height: 2),
              Text('ជ្រើសរើសប្រភេទ និងវិធីសាស្ត្រទូទាត់',
                  style: _t(12, FontWeight.w500, _C.muted)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_C.heroA, _C.heroB],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _C.brand.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ត្រូវបង់សរុប',
                  style: _t(10, FontWeight.w600, Colors.white.withValues(alpha: 0.85))),
              Text('\$${totalUsd.toStringAsFixed(2)}',
                  style: _t(17, FontWeight.w800, Colors.white, height: 1.1)),
              Text('= ${totalKhr.toStringAsFixed(0)}៛',
                  style: _t(11, FontWeight.w800, const Color(0xFFFFE08A))),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: _C.muted),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _SegItem {
  final String value;
  final String label;
  final IconData? icon;
  final String? emoji;
  const _SegItem(this.value, this.label, this.icon, {this.emoji});
}

class _Segmented extends StatelessWidget {
  final String selected;
  final List<_SegItem> items;
  final ValueChanged<String> onChanged;
  final bool inner;

  const _Segmented({
    required this.selected,
    required this.items,
    required this.onChanged,
    this.inner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: inner ? _C.bg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: inner ? null : Border.all(color: _C.line),
      ),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(it.value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected == it.value
                        ? const LinearGradient(colors: [_C.heroA, _C.brand, _C.heroB])
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected == it.value
                        ? [
                      BoxShadow(
                        color: _C.brand.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (it.emoji != null)
                        Text(it.emoji!, style: const TextStyle(fontSize: 15))
                      else if (it.icon != null)
                        Icon(it.icon,
                            size: 16,
                            color: selected == it.value ? Colors.white : _C.muted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(
                            12.5,
                            FontWeight.w800,
                            selected == it.value ? Colors.white : _C.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool filled;
  const _AmountBox({
    required this.label,
    required this.value,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: filled ? Colors.white : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: filled ? color : color.withValues(alpha: 0.25),
          width: filled ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _t(11, FontWeight.w700, filled ? _C.muted : color)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: _t(20, FontWeight.w800, color, spacing: -0.4)),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool highlight;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight ? _C.brand : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: highlight ? _C.brand : _C.line),
          ),
          child: Text(label,
              style: _t(12.5, FontWeight.w800, highlight ? Colors.white : _C.ink)),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// Edit amount dialog (owns + disposes its own controller)
// ─────────────────────────────────────────────────────────────
class _EditAmountDialog extends StatefulWidget {
  final String title;
  final double initialValue;
  const _EditAmountDialog({required this.title, required this.initialValue});

  @override
  State<_EditAmountDialog> createState() => _EditAmountDialogState();
}

class _EditAmountDialogState extends State<_EditAmountDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue > 0 ? widget.initialValue.toStringAsFixed(2) : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: _t(18, FontWeight.w800, _C.ink)),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              cursorColor: _C.brand,
              style: _t(18, FontWeight.w800, _C.ink),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: _t(18, FontWeight.w600, _C.muted),
                prefixText: '\$ ',
                prefixStyle: _t(18, FontWeight.w800, _C.brand),
                filled: true,
                fillColor: _C.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _C.brand, width: 1.6),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.ink,
                      side: const BorderSide(color: _C.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel', style: _t(14, FontWeight.w800, _C.ink)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final parsed = double.tryParse(_controller.text.trim()) ?? 0.0;
                      Navigator.pop(context, parsed);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Save', style: _t(14, FontWeight.w800, Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Customer selection (tile + searchable picker sheet)
// ─────────────────────────────────────────────────────────────
class _PickResult {
  final int? id;
  final String name;
  final String phone;
  final bool addNew;
  const _PickResult({this.id, this.name = '', this.phone = '', this.addNew = false});
}

const _avatarColors = <Color>[
  Color(0xFF0F766E),
  Color(0xFF3B6FD4),
  Color(0xFF7C4DCC),
  Color(0xFFD6457A),
  Color(0xFFB7791F),
  Color(0xFF0E7490),
];

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final bool guest;
  const _Avatar({required this.name, this.size = 42, this.guest = false});

  @override
  Widget build(BuildContext context) {
    final color = guest ? _C.muted : _avatarColors[name.hashCode.abs() % _avatarColors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: guest || name.trim().isEmpty
          ? Icon(Icons.person_rounded, color: Colors.white, size: size * 0.5)
          : Text(
        String.fromCharCode(name.trim().runes.first).toUpperCase(),
        style: _t(size * 0.42, FontWeight.w800, Colors.white),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final String name;
  final String phone;
  final bool isRegistered;
  final VoidCallback onTap;
  const _CustomerTile({
    required this.name,
    required this.phone,
    required this.isRegistered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = name.isNotEmpty;

    return Container(
      decoration: _card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                _Avatar(name: name, guest: !hasName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('អតិថិជន', style: _t(11, FontWeight.w700, _C.muted)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              hasName ? name : 'អតិថិជនទូទៅ (Guest)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(14.5, FontWeight.w800, _C.ink),
                            ),
                          ),
                          if (isRegistered) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 15, color: _C.brand),
                          ],
                        ],
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(phone, style: _t(12, FontWeight.w600, _C.brand)),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _C.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ជ្រើសរើស', style: _t(12, FontWeight.w800, _C.brand)),
                      const SizedBox(width: 2),
                      const Icon(Icons.expand_more_rounded, size: 18, color: _C.brand),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final Future<List<Customer>> customersFuture;
  final int? selectedId;
  final String currentName;

  const _CustomerPickerSheet({
    required this.customersFuture,
    required this.selectedId,
    required this.currentName,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _row({
    required Widget leading,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: selected ? _C.brand.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? _C.brand.withValues(alpha: 0.4) : _C.line),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(14, FontWeight.w800, _C.ink)),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: _t(12, FontWeight.w600, _C.muted)),
                  ],
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: _C.brand),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim();
    final ql = q.toLowerCase();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: _C.line, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('ជ្រើសរើសអតិថិជន', style: _t(18, FontWeight.w800, _C.ink)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _C.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _search,
                  cursorColor: _C.brand,
                  style: _t(14, FontWeight.w600, _C.ink),
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'ស្វែងរកតាមឈ្មោះ ឬលេខទូរស័ព្ទ',
                    hintStyle: _t(13, FontWeight.w400, _C.muted),
                    prefixIcon: const Icon(Icons.search_rounded, color: _C.muted),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: _C.muted),
                      onPressed: () {
                        _search.clear();
                        setState(() => _q = '');
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Customer>>(
                future: widget.customersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 3, color: _C.brand),
                      ),
                    );
                  }

                  final all = snapshot.data ?? <Customer>[];
                  final filtered = q.isEmpty
                      ? all
                      : all.where((c) {
                    final n = (c.name ?? '').toLowerCase();
                    final p = (c.phone ?? '').toLowerCase();
                    return n.contains(ql) || p.contains(ql);
                  }).toList();

                  final exact = all.any((c) => (c.name ?? '').toLowerCase() == ql);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      _row(
                        leading: const _Avatar(name: '', guest: true),
                        title: 'អតិថិជនទូទៅ (Guest)',
                        selected: widget.selectedId == null && widget.currentName.isEmpty,
                        onTap: () => Navigator.pop(context, const _PickResult()),
                      ),
                      if (q.isNotEmpty && !exact) ...[
                        const SizedBox(height: 8),
                        _row(
                          leading: const _Avatar(name: '', guest: true),
                          title: 'ប្រើឈ្មោះ "$q" ជាអតិថិជនទូទៅ',
                          subtitle: 'មិនរក្សាទុកជាអតិថិជនថ្មី',
                          selected: false,
                          onTap: () => Navigator.pop(context, _PickResult(name: q)),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('អតិថិជនទាំងអស់ (${filtered.length})',
                            style: _t(12, FontWeight.w800, _C.muted)),
                      ),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text('រកមិនឃើញអតិថិជន',
                                style: _t(13.5, FontWeight.w600, _C.muted)),
                          ),
                        )
                      else
                        for (final c in filtered) ...[
                          _row(
                            leading: _Avatar(name: c.name ?? ''),
                            title: c.name ?? '—',
                            subtitle: c.phone ?? 'No Phone',
                            selected: widget.selectedId == c.id,
                            onTap: () => Navigator.pop(
                              context,
                              _PickResult(id: c.id, name: c.name ?? '', phone: c.phone ?? ''),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _C.heroA.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: _GradientButton(
                  height: 50,
                  label: 'បន្ថែមអតិថិជនថ្មី',
                  icon: Icons.person_add_alt_1_rounded,
                  onTap: () => Navigator.pop(context, _PickResult(addNew: true, name: q)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}