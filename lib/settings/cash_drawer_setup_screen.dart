import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CashDrawerSetupScreen extends StatefulWidget {
  const CashDrawerSetupScreen({super.key});

  @override
  State<CashDrawerSetupScreen> createState() => _CashDrawerSetupScreenState();
}

class _CashDrawerSetupScreenState extends State<CashDrawerSetupScreen> {
  bool isAutoOpenEnabled = true;
  String selectedTrigger = 'Printer (RJ11)'; //  گزینهតភ្ជាប់ Cash Drawer

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF1E293B);
    const Color subtitleColor = Color(0xFF64748B);
    const Color primaryColor = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Cash Drawer Setup',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
            fontFamily: 'KantumruyPro',
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textColor),
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
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'កំណត់រចនាសម្ព័ន្ធប្រអប់លុយ (Cash Drawer) ឱ្យបើកដោយស្វ័យប្រវត្តិរាល់ពេលព្រីនវិក្កយបត្ររួច។',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.8),
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
              'Configuration Settings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'KantumruyPro',
              ),
            ),
            const SizedBox(height: 12),

            // ⚙️ Settings Options Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // 1. Auto Open Switch Tile
                    SwitchListTile(
                      value: isAutoOpenEnabled,
                      activeColor: primaryColor,
                      onChanged: (value) {
                        setState(() {
                          isAutoOpenEnabled = value;
                        });
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.point_of_sale_rounded, color: primaryColor, size: 22),
                      ),
                      title: const Text(
                        'Auto Open Cash Drawer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: const Text(
                        'Open drawer automatically on checkout',
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey.shade100),

                    // 2. Trigger Method Selection Tile
                    _buildMenuTile(
                      icon: Icons.settings_ethernet_rounded,
                      title: "Drawer Trigger Port",
                      subtitle: selectedTrigger,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: Colors.white,
                      arrowBgColor: primaryColor.withOpacity(0.08),
                      arrowIconColor: primaryColor,
                      onTap: () {
                        _showTriggerDialog(context);
                      },
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey.shade100),

                    // 3. Test Open Drawer Button Tile
                    _buildMenuTile(
                      icon: Icons.key_rounded,
                      title: "Test Cash Drawer",
                      subtitle: "Send signal to test drawer connection",
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      tileBgColor: Colors.white,
                      arrowBgColor: Colors.blue.withOpacity(0.08),
                      arrowIconColor: Colors.blue,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('កំពុងផ្ញើសញ្ញាសាកល្បងទៅកាន់ Cash Drawer...'),
                            backgroundColor: primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // 🧩 Template Widget សម្រាប់បង្ហាញ Menu Tile នីមួយៗ
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtitleColor,
    required Color tileBgColor,
    required Color arrowBgColor,
    required Color arrowIconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: tileBgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: arrowBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: arrowIconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🪟 Dialog សម្រាប់ជ្រើសរើសប្រភេទ Trigger Port
  void _showTriggerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Trigger Port', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Printer (RJ11 / RJ12)'),
                onTap: () {
                  setState(() {
                    selectedTrigger = 'Printer (RJ11)';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('USB Direct Connection'),
                onTap: () {
                  setState(() {
                    selectedTrigger = 'USB Direct Connection';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}