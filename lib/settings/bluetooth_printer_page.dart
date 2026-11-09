import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../msg/appSnackBar.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  bool isScanning = false;
  List<Map<String, dynamic>> devices = [];

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan] == PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted ||
        statuses[Permission.location] == PermissionStatus.granted) {
      _startScan();
    } else {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'សូមបើកសិទ្ធិ Bluetooth និង Location ក្នុង Settings ទើបអាចរកឃើញម៉ាស៊ីនព្រីន!',
        );
      }
      setState(() {
        isScanning = false;
      });
    }
  }

  void _startScan() async {
    setState(() {
      isScanning = true;
    });

    List<BluetoothInfo> results = [];
    try {
      final bool? bluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (bluetoothEnabled == true) {
        results = await PrintBluetoothThermal.pairedBluetooths;
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'សូមបើក Bluetooth ក្នុងទូរស័ព្ទរបស់អ្នកជាមុនសិន!');
        }
      }
    } catch (e) {
      debugPrint("Error scanning printers: $e");
    }

    setState(() {
      devices = results.map((d) {
        return {
          'name': d.name.isNotEmpty ? d.name : 'Unknown Printer',
          'address': d.macAdress,
          'isConnected': false,
          'device': d,
        };
      }).toList();
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌙 NEW: follow the app theme (light / dark)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF1E293B);

    return Scaffold(
      // 🌙 CHANGED: was const Color(0xFFF4F6F9)
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          'Bluetooth Printer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: titleColor,
            fontFamily: 'KantumruyPro',
          ),
        ),
        elevation: 0,
        // 🌙 CHANGED: was Colors.white
        backgroundColor: isDark ? const Color(0xFF151C2E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: titleColor),
        actions: [
          IconButton(
            icon: isScanning
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF10B981),
              ),
            )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
            onPressed: isScanning ? null : _checkPermissionsAndScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'សូម Pair ម៉ាស៊ីនព្រីន (80mm / 58mm) ជាមួយទូរស័ព្ទក្នុង Bluetooth Settings ជាមុនសិន ទើបវារកឃើញទីនេះ។',
                      style: TextStyle(
                        fontSize: 12,
                        // 🌙 CHANGED: was 0xFF1E293B @ 0.8
                        color: titleColor.withValues(alpha: 0.8),
                        fontFamily: 'KantumruyPro',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ឧបករណ៍ដែលបាន Pair រួច (Paired Devices)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: titleColor,
                fontFamily: 'KantumruyPro',
              ),
            ),
            const SizedBox(height: 12),
            devices.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  isScanning
                      ? 'កំពុងស្វែងរកម៉ាស៊ីនព្រីន...'
                      : 'រកមិនឃើញម៉ាស៊ីនព្រីន Bluetooth ទេ។\nសូមធានាថាបាន Pair ក្នុង Setting ទូរស័ព្ទរួចរាល់។',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            )
                : Container(
              decoration: BoxDecoration(
                // 🌙 CHANGED: was Colors.white
                color: isDark ? const Color(0xFF151C2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 68,
                    // 🌙 CHANGED: was Colors.grey.shade100
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    bool isConnected = device['isConnected'];

                    return _buildPrinterTile(
                      name: device['name'],
                      address: device['address'],
                      isConnected: isConnected,
                      onTap: () async {
                        try {
                          String macAddress = device['address'];
                          bool connected = await PrintBluetoothThermal.connect(
                            macPrinterAddress: macAddress,
                          );

                          setState(() {
                            for (var d in devices) {
                              d['isConnected'] = false;
                            }
                            device['isConnected'] = connected;
                          });

                          if (context.mounted) {
                            if (connected) {
                              AppSnackBar.showSuccess(
                                context,
                                'បានតភ្ជាប់ទៅកាន់ ${device['name']} ជោគជ័យ!',
                              );
                            } else {
                              AppSnackBar.showError(
                                context,
                                'ការតភ្ជាប់បរាជ័យ!',
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint("Connection failed: $e");
                          if (context.mounted) {
                            AppSnackBar.showError(
                              context,
                              'ការតភ្ជាប់បរាជ័យ: $e',
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterTile({
    required String name,
    required String address,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    // 🌙 NEW: follow the app theme (light / dark)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFF10B981).withValues(alpha: isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.print_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        // 🌙 CHANGED: was Color(0xFF1E293B)
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isConnected ? 'Connected' : 'Connect',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isConnected
                        ? const Color(0xFF10B981)
                        : (isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}