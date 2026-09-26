import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_order.dart';
import '../../msg/appSnackBar.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> deliveryData;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.deliveryData,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final int _animationSeconds = 15; // ⏱️ កំណត់ ១៥ វិនាទីសម្រាប់ការតេស្តចលនា
  double _totalMinutes = 2.0;
  int _currentDisplayMinutes = 2;
  bool _isArrived = false;
  final ApiOrder _apiOrder = ApiOrder();

  @override
  void initState() {
    super.initState();

    _totalMinutes = (widget.deliveryData['estimated_minutes'] ?? 2).toDouble();
    _currentDisplayMinutes = _totalMinutes.ceil();

    _controller = AnimationController(
      duration: Duration(seconds: _animationSeconds),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // ⏱️ ធ្វើសមកាលកម្ម (Sync) រវាងនាទី និងចលនារត់របស់ម៉ូតូ
    _controller.addListener(() {
      double progress = _controller.value;
      double remainingTime = _totalMinutes * (1.0 - progress);

      if (remainingTime < 0.05) {
        remainingTime = 0;
      }

      int minsToDisplay = remainingTime.ceil();
      if (_currentDisplayMinutes != minsToDisplay) {
        setState(() {
          _currentDisplayMinutes = minsToDisplay;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isArrived) {
        setState(() => _isArrived = true);
        _showCartPaymentBottomSheet(context);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 💳 ផ្ទាំង Bottom Sheet ទូទាត់ប្រាក់ពេលដល់គោលដៅ
  void _showCartPaymentBottomSheet(BuildContext parentContext) {
    double totalAmount =
        widget.deliveryData['grand_total'] ??
        widget.deliveryData['total_amount'] ??
        0.0;

    final dynamic rawOrderId =
        widget.deliveryData['order_id'] ??
        widget.deliveryData['id'] ??
        widget.orderId;

    int orderId = 0;
    if (rawOrderId is int) {
      orderId = rawOrderId;
    } else {
      orderId =
          int.tryParse(
            rawOrderId.toString().replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
    }

    String cashGivenStr = totalAmount.toStringAsFixed(2);
    String paymentMethod = 'cash';
    String currencyType = 'USD';
    const double exchangeRate = 4100.0;

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
              height: MediaQuery.of(context).size.height * 0.94,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ទូទាត់ប្រាក់ពេលដល់គោលដៅ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                fontFamily: 'KhmerOSBattambang',
                              ),
                            ),
                            Text(
                              "សូមប្រមូលប្រាក់ និងទូទាត់ជូនអតិថិជន",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontFamily: 'KhmerOSBattambang',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "ទឹកប្រាក់សរុប",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontFamily: 'KhmerOSBattambang',
                                ),
                              ),
                              Text(
                                "\$${totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "= ${totalKHR.toStringAsFixed(0)}៛",
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          _buildMethodTab(
                            "សាច់ប្រាក់",
                            Icons.payments_rounded,
                            paymentMethod == 'cash',
                            () => setStateSheet(() => paymentMethod = 'cash'),
                          ),
                          _buildMethodTab(
                            "KHQR",
                            Icons.qr_code_2_rounded,
                            paymentMethod == 'khqr',
                            () => setStateSheet(() => paymentMethod = 'khqr'),
                          ),
                          _buildMethodTab(
                            "កាត",
                            Icons.credit_card,
                            paymentMethod == 'card',
                            () => setStateSheet(() => paymentMethod = 'card'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (paymentMethod == 'cash') ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "រូបិយប័ណ្ណទូទាត់",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'KhmerOSBattambang',
                                          ),
                                        ),
                                        Text(
                                          "1\$ = ${exchangeRate.toStringAsFixed(0)}៛",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _buildCurrencyTab(
                                          "ដុល្លារ (\$)",
                                          "🇺🇸",
                                          'USD',
                                          currencyType == 'USD',
                                          () {
                                            setStateSheet(() {
                                              if (currencyType == 'KHR') {
                                                double currentVal =
                                                    double.tryParse(
                                                      cashGivenStr,
                                                    ) ??
                                                    0;
                                                cashGivenStr =
                                                    (currentVal / exchangeRate)
                                                        .toStringAsFixed(2);
                                              }
                                              currencyType = 'USD';
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _buildCurrencyTab(
                                          "ប្រាក់រៀល (៛)",
                                          "🇰🇭",
                                          'KHR',
                                          currencyType == 'KHR',
                                          () {
                                            setStateSheet(() {
                                              if (currencyType == 'USD') {
                                                double currentVal =
                                                    double.tryParse(
                                                      cashGivenStr,
                                                    ) ??
                                                    0;
                                                cashGivenStr =
                                                    (currentVal * exchangeRate)
                                                        .toStringAsFixed(0);
                                              }
                                              currencyType = 'KHR';
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF4F46E5),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "ប្រាក់ទទួលបាន",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                    fontFamily:
                                                        'KhmerOSBattambang',
                                                  ),
                                                ),
                                                Text(
                                                  currencyType == 'USD'
                                                      ? "\$$cashGivenStr"
                                                      : "$cashGivenStr៛",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4F46E5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                    fontSize: 10,
                                                    color: Colors.green,
                                                    fontFamily:
                                                        'KhmerOSBattambang',
                                                  ),
                                                ),
                                                Text(
                                                  currencyType == 'USD'
                                                      ? "\$${changeUSD.toStringAsFixed(2)}"
                                                      : "${changeKHR.toStringAsFixed(0)}៛",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 3.2,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
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
                                            backgroundColor:
                                                Colors.grey.shade50,
                                            foregroundColor: const Color(
                                              0xFF1E293B,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () => onKeyPressed(key),
                                          child: Text(
                                            key,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ] else ...[
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    "សូមស្កេន QR Code ឬទូទាត់តាមកាត",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'KhmerOSBattambang',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          try {
                            double cashGiven =
                                double.tryParse(cashGivenStr) ?? totalAmount;
                            double actualUSDReceived = currencyType == 'KHR'
                                ? (cashGiven / exchangeRate)
                                : cashGiven;

                            if (paymentMethod == 'cash' &&
                                actualUSDReceived < totalAmount) {
                              AppSnackBar.showError(
                                parentContext,
                                "⚠️ ប្រាក់បានបង់មិនទាន់គ្រប់គ្រាន់ទេ!",
                              );
                              return;
                            }

                            double finalChange = paymentMethod == 'cash'
                                ? (actualUSDReceived - totalAmount)
                                : 0.0;
                            double amountPaid = paymentMethod == 'cash'
                                ? actualUSDReceived
                                : totalAmount;

                            bool success = await _apiOrder
                                .updateDeliveryPaymentAndStatus(
                                  deliveryId: orderId,
                                  status: 'success',
                                  paymentMethod: paymentMethod,
                                  amountPaid: amountPaid,
                                  changeAmount: finalChange,
                                );

                            if (success && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              Navigator.pop(context);
                              AppSnackBar.showSuccess(
                                parentContext,
                                "ការទូទាត់ និងការដឹកជញ្ជូនបានសម្រេចជោគជ័យ!",
                              );
                            } else {
                              AppSnackBar.showError(
                                parentContext,
                                "បរាជ័យក្នុងការ Update ព័ត៌មានទូទាត់!",
                              );
                            }
                          } catch (e) {
                            AppSnackBar.showError(parentContext, "Error: $e");
                          }
                        },
                        child: Text(
                          paymentMethod == 'cash'
                              ? "ទូទាត់ប្រាក់ និងបញ្ចប់ការដឹក (\$${totalAmount.toStringAsFixed(2)})"
                              : "បញ្ជាក់ការទូទាត់ QR",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'KhmerOSBattambang',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                  fontFamily: 'KhmerOSBattambang',
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
                    fontFamily: 'KhmerOSBattambang',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String partnerName =
        widget.deliveryData['delivery_partner'] ?? 'Grab Express';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "តាមដានការដឹកជញ្ជូន ($partnerName)",
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'KhmerOSBattambang',
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCartPaymentBottomSheet(context),
        backgroundColor: Colors.green.shade600,
        icon: const Icon(Icons.payment, color: Colors.white),
        label: const Text(
          "ទូទាត់ប្រាក់ (Payment)",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'KhmerOSBattambang',
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.orderId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isArrived
                            ? "បានដឹកជញ្ជូនរួចរាល់"
                            : "កំពុងធ្វើដំណើរចេញ",
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'KhmerOSBattambang',
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Estimated Time",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isArrived ? "Arrived" : "$_currentDisplayMinutes នាទី",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF047857),
                          fontFamily: 'KhmerOSBattambang',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepItem(
                  icon: Icons.inventory_2_outlined,
                  title: "បានទទួល",
                  isCompleted: true,
                ),
                _buildLine(isCompleted: true),
                _buildStepItem(
                  icon: Icons.route_outlined,
                  title: "តាមផ្លូវ",
                  isCompleted: true,
                ),
                _buildLine(isCompleted: true),
                _buildStepItem(
                  icon: Icons.delivery_dining,
                  title: "កំពុងផ្ញើ",
                  isCompleted: true,
                ),
                _buildLine(isCompleted: _isArrived),
                _buildStepItem(
                  icon: Icons.check_circle_outline,
                  title: "ដល់គោលដៅ",
                  isCompleted: _isArrived,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    double startX = 40;
                    double startY = height - 50;
                    double endX = width - 40;
                    double endY = 50;

                    double progress = _animation.value;
                    double currentX = startX + (endX - startX) * progress;
                    double currentY = startY + (endY - startY) * progress;

                    return Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: const Color(0xFFEEF2F6),
                          child: CustomPaint(painter: _MapRoutePainter()),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 25,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(
                              Icons.store,
                              color: Color(0xFF059669),
                              size: 28,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 30,
                          right: 35,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                          ),
                        ),
                        Positioned(
                          top: currentY - 20,
                          left: currentX - 20,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.two_wheeler,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(
                      Icons.delivery_dining,
                      size: 28,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.deliveryData['name'] ?? "Mock Driver",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$partnerName • ${widget.deliveryData['phone'] ?? '0889986767'}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCircleActionButton(Icons.phone, () {}),
                  const SizedBox(width: 8),
                  _buildCircleActionButton(Icons.chat_bubble, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String title,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF059669)
                : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : Colors.grey.shade500,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'KhmerOSBattambang',
            color: isCompleted ? const Color(0xFF1E293B) : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        height: 2,
        color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCircleActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFD1FAE5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF059669), size: 18),
      ),
    );
  }
}

class _MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(40, size.height - 50),
      Offset(size.width - 40, 50),
      roadPaint,
    );

    final routePaint = Paint()
      ..color = const Color(0xFF059669)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(40, size.height - 50);
    path.lineTo(size.width * 0.4, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.5);
    path.lineTo(size.width - 40, 50);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
