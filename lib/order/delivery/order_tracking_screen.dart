import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  final int _animationSeconds = 15;
  double _totalMinutes = 2.0;
  int _currentDisplayMinutes = 2;
  bool _isArrived = false;
  final ApiOrder _apiOrder = ApiOrder();

  GoogleMapController? _mapController;
  late LatLng _storeLocation;
  late LatLng _customerLocation;

  final BitmapDescriptor _driverIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueAzure,
  );

  @override
  void initState() {
    super.initState();
    final data = widget.deliveryData;

    double storeLat =
        double.tryParse(
          data['store_lat']?.toString() ??
              data['pickup_lat']?.toString() ??
              data['latitude']?.toString() ??
              '11.5564',
        ) ??
        11.5564;

    double storeLng =
        double.tryParse(
          data['store_lng']?.toString() ??
              data['pickup_lng']?.toString() ??
              data['longitude']?.toString() ??
              '104.9282',
        ) ??
        104.9282;

    double customerLat =
        double.tryParse(
          data['customer_lat']?.toString() ??
              data['delivery_lat']?.toString() ??
              data['lat']?.toString() ??
              '11.5650',
        ) ??
        11.5650;

    double customerLng =
        double.tryParse(
          data['customer_lng']?.toString() ??
              data['delivery_lng']?.toString() ??
              data['lng']?.toString() ??
              '104.9150',
        ) ??
        104.9150;

    _storeLocation = LatLng(storeLat, storeLng);
    _customerLocation = LatLng(customerLat, customerLng);

    _totalMinutes = (data['estimated_minutes'] ?? 2).toDouble();
    _currentDisplayMinutes = _totalMinutes.ceil();

    _controller = AnimationController(
      duration: Duration(seconds: _animationSeconds),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

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

  // 💳 ផ្ទាំង Bottom Sheet ទូទាត់ប្រាក់ (មានប្តូរប្រាក់ USD / KHR 🇺🇸/🇰🇭 យ៉ាងស្អាត)
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
            double totalKHR = totalAmount * exchangeRate;
            double cashGivenKHR = currencyType == 'KHR'
                ? cashGiven
                : (cashGiven * exchangeRate);
            double changeKHR = cashGivenKHR >= totalKHR
                ? cashGivenKHR - totalKHR
                : 0;
            double changeUSD = cashGiven >= totalAmount
                ? cashGiven - totalAmount
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
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Payment Method Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (paymentMethod == 'cash') ...[
                              Container(
                                padding: const EdgeInsets.all(12),
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
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF4F46E5),
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
                                            padding: const EdgeInsets.all(10),
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
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
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
                                  childAspectRatio: 2.8,
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
                                            backgroundColor:
                                                Colors.grey.shade50,
                                            foregroundColor: const Color(
                                              0xFF1E293B,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
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
                                    "សូមស្កេន KHQR ដើម្បីទូទាត់",
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
                    const SizedBox(height: 12),
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
                        onPressed: () async {
                          try {
                            double cashGiven =
                                double.tryParse(cashGivenStr) ?? totalAmount;
                            double actualUSDReceived = currencyType == 'KHR'
                                ? (cashGiven / exchangeRate)
                                : cashGiven;

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
                          "ទូទាត់ប្រាក់ និងបញ្ចប់ការដឹក (\$${totalAmount.toStringAsFixed(2)})",
                          style: const TextStyle(
                            fontSize: 15,
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
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flagEmoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isSelected
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                  fontFamily: 'KhmerOSBattambang',
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
    String driverName =
        widget.deliveryData['name'] ??
        widget.deliveryData['driver_name'] ??
        "Budi Santoso";
    String driverPhone =
        widget.deliveryData['phone'] ??
        widget.deliveryData['driver_phone'] ??
        '0987654321';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Order Tracking",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF1E293B),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 📊 Top Status Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Out for Delivery",
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
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
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Estimated Arrival",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            _isArrived
                                ? "Arrived"
                                : "$_currentDisplayMinutes minutes",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildTimelineStep(
                      title: "Picked Up",
                      time: "10:15 AM",
                      isCompleted: true,
                    ),
                    _buildTimelineLine(isCompleted: true),
                    _buildTimelineStep(
                      title: "In Transit",
                      time: "10:32 AM",
                      isCompleted: true,
                    ),
                    _buildTimelineLine(isCompleted: true),
                    _buildTimelineStep(
                      title: "Out for Delivery",
                      time: "10:45 AM",
                      isCompleted: true,
                    ),
                    _buildTimelineLine(isCompleted: _isArrived),
                    _buildTimelineStep(
                      title: "Delivered",
                      time: "Pending",
                      isCompleted: _isArrived,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🗺️ Google Maps View
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                double progress = _animation.value;
                double currentLat =
                    _storeLocation.latitude +
                    (_customerLocation.latitude - _storeLocation.latitude) *
                        progress;
                double currentLng =
                    _storeLocation.longitude +
                    (_customerLocation.longitude - _storeLocation.longitude) *
                        progress;
                LatLng currentDriverPos = LatLng(currentLat, currentLng);

                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _storeLocation,
                        zoom: 14.0,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('store'),
                          position: _storeLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                        Marker(
                          markerId: const MarkerId('customer'),
                          position: _customerLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: currentDriverPos,
                          icon: _driverIcon,
                        ),
                      },
                      polylines: {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: [_storeLocation, _customerLocation],
                          color: const Color(0xFF059669),
                          width: 5,
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // 🛵🎨 Modern Bottom Driver Card (Exactly matching UI reference)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  "4.9",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Text(
                                  " (320 reviews)",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Honda Beat • B 1234 KLM",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildActionIconButton(
                        icon: Icons.phone_rounded,
                        color: const Color(0xFF10B981),
                        bgColor: Colors.green.shade50,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _buildActionIconButton(
                        icon: Icons.chat_bubble_rounded,
                        color: const Color(0xFF10B981),
                        bgColor: Colors.green.shade50,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCartPaymentBottomSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.payment_rounded, size: 18),
                      label: const Text(
                        "ទូទាត់ប្រាក់ និងបញ្ចប់ការដឹក (Payment)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'KhmerOSBattambang',
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
  }

  Widget _buildTimelineStep({
    required String title,
    required String time,
    required bool isCompleted,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF059669)
                  : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isCompleted
                  ? const Color(0xFF1E293B)
                  : Colors.grey.shade400,
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine({required bool isCompleted}) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
