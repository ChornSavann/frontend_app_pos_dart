import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  bool isScanning = false;

  // ឧទាហរណ៍បញ្ជីម៉ាស៊ីនព្រីនដែលរកឃើញ
  final List<Map<String, dynamic>> devices = [
    {'name': 'POS-80 Printer', 'address': '00:11:22:33:44:55', 'isConnected': true},
    {'name': 'RP58-Bluetooth', 'address': 'AA:BB:CC:DD:EE:FF', 'isConnected': false},
    {'name': 'Epson TM-P20', 'address': '11:22:33:44:55:66', 'isConnected': false},
  ];

  void _startScan() {
    setState(() {
      isScanning = true;
    });
    // จำลองเวลา Scan រកឧបករណ៍ (២ វិនាទី)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
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
                color: Color(0xFF2563EB),
              ),
            )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
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
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'បើកប៊្លូធូសក្នុងទូរស័ព្ទរបស់អ្នក ដើម្បីស្វែងរកម៉ាស៊ីនព្រីនវិក្កយបត្រ (80mm / 58mm)។',
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

            // 📋 Section Title
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
            Container(
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
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, indent: 68, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    bool isConnected = device['isConnected'];

                    return _buildPrinterTile(
                      name: device['name'],
                      address: device['address'],
                      isConnected: isConnected,
                      onTap: () {
                        setState(() {
                          for (var d in devices) {
                            d['isConnected'] = false;
                          }
                          device['isConnected'] = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'បានតភ្ជាប់ទៅកាន់ ${device['name']} ជោគជ័យ!',
                              style: const TextStyle(fontFamily: 'KantumruyPro'),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
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
                      ? Colors.green.withValues(alpha: 0.1)
                      : const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.print_rounded,
                  color: isConnected ? Colors.green : const Color(0xFF2563EB),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isConnected ? 'Connected' : 'Connect',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green : Colors.grey.shade600,
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