import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

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
    _startScan();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Bluetooth Printer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
            fontFamily: 'KantumruyPro',
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
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
            onPressed: isScanning ? null : _startScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Status Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
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
                      'សូមបើក Bluetooth និង Pair ជាមួយម៉ាស៊ីនព្រីន (80mm / 58mm) ជាមុនសិន ទើបវារកឃើញទីនេះ។',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                        fontFamily: 'KantumruyPro',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'ឧបករណ៍ដែលបានរកឃើញ (Available Devices)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'KantumruyPro',
              ),
            ),
            const SizedBox(height: 12),

            // 📋 Devices List Card
            devices.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  isScanning
                      ? 'កំពុងស្វែងរកម៉ាស៊ីនព្រីន...'
                      : 'រកមិនឃើញម៉ាស៊ីនព្រីន Bluetooth ទេ។\nសូមពិនិត្យការតភ្ជាប់ក្នុងទូរស័ព្ទរបស់អ្នក។',
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                    color: Colors.grey.shade100,
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

                          // 🟢 ប្រើប្រាស់ macPrinterAddress ឱ្យត្រូវតាម package
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

  // Widget សម្រាប់បង្ហាញជួរម៉ាស៊ីនព្រីននីមួយៗ
  Widget _buildPrinterTile({
    required String name,
    required String address,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
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
                      : const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.print_rounded,
                  color: isConnected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF10B981),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
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
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isConnected ? 'Connected' : 'Connect',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isConnected
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade600,
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