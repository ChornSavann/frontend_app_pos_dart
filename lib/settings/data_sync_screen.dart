import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DataSyncScreen extends StatefulWidget {
  const DataSyncScreen({super.key});

  @override
  State<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<DataSyncScreen> {
  bool isSyncing = false;
  String lastSynced = 'Just now';

  // ឧទាហរណ៍ទិន្នន័យ Local ដែលត្រូវ Sync
  final Map<String, int> pendingData = {
    'Products': 0,
    'Categories': 0,
    'Orders (Sales)': 5,
    'Customers': 2,
  };

  // Function จำลองการ Sync ទិន្នន័យ
  Future<void> _handleSync() async {
    setState(() {
      isSyncing = true;
    });

    // จำลองเวลาในการ Sync (ឧ. ២ វិនាទី)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isSyncing = false;
      lastSynced = 'Just now';
      // ពេល Sync រួច 0 ទិន្នន័យដែលសល់
      pendingData.updateAll((key, value) => 0);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'ធ្វើសមកាលកម្មទិន្នន័យបានជោគជ័យ!',
            style: TextStyle(fontFamily: 'KantumruyPro'),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPending = pendingData.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'សមកាលកម្មទិន្នន័យ',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Sync Header Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cloud Database Sync',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalPending > 0
                        ? '$totalPending ឯកសាររង់ចាំ Sync'
                        : 'ទិន្នន័យមានភាពទាន់សម័យ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KantumruyPro',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last synced: $lastSynced',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sync Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2563EB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isSyncing ? null : _handleSync,
                      child: isSyncing
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563EB),
                        ),
                      )
                          : const Text(
                        'ធ្វើសមកាលកម្មឥឡូវនេះ (Sync Now)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'KantumruyPro',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📋 Section Title
            const Text(
              'ព័ត៌មានលម្អិតនៃទិន្នន័យ (Pending Items)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'KantumruyPro',
              ),
            ),
            const SizedBox(height: 12),

            // 📋 Breakdown List Card
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
                child: Column(
                  children: [
                    _buildSyncItemTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Products Inventory',
                      count: '${pendingData['Products']} items',
                      isSynced: pendingData['Products'] == 0,
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey.shade100),
                    _buildSyncItemTile(
                      icon: Icons.category_outlined,
                      title: 'Categories & Brands',
                      count: '${pendingData['Categories']} items',
                      isSynced: pendingData['Categories'] == 0,
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey.shade100),
                    _buildSyncItemTile(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Sales Orders',
                      count: '${pendingData['Orders (Sales)']} orders',
                      isSynced: pendingData['Orders (Sales)'] == 0,
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey.shade100),
                    _buildSyncItemTile(
                      icon: Icons.people_outline_rounded,
                      title: 'Customers Data',
                      count: '${pendingData['Customers']} items',
                      isSynced: pendingData['Customers'] == 0,
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

  // Widget សម្រាប់បង្ហាញជួរรายการនីមួយៗ
  Widget _buildSyncItemTile({
    required IconData icon,
    required String title,
    required String count,
    required bool isSynced,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSynced
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isSynced ? 'Synced' : count,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSynced ? Colors.green : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}