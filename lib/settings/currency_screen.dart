import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  // កំណត់រូបិយប័ណ្ណដែលជ្រើសរើសស្រាប់ (ឧ. USD ជាគោល)
  String selectedCurrency = 'USD';

  final List<Map<String, String>> currencies = [
    {
      'code': 'USD',
      'name': 'US Dollar (\$ / ៛ Riel)',
      'symbol': '\$',
      'description': 'ប្រាក់ដុល្លារអាមេរិក (គាំទ្រការប្តូរប្រាក់រៀលស្វ័យប្រវត្តិ)',
    },
    {
      'code': 'KHR',
      'name': 'Cambodian Riel (៛)',
      'symbol': '៛',
      'description': 'ប្រាក់រៀលកម្ពុជា',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'រូបិយប័ណ្ណ (Currency)',
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
            const Text(
              'ជ្រើសរើសរូបិយប័ណ្ណគោលសម្រាប់កត់ត្រាការលក់ (Base Currency)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontFamily: 'KantumruyPro',
              ),
            ),
            const SizedBox(height: 16),

            // 📋 Currency Options List Card
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
                    _buildCurrencyTile(
                      code: 'USD',
                      title: 'Currency / រូបិយប័ណ្ណ',
                      subtitle: 'USD (\$ / ៛ Riel)',
                      icon: Icons.monetization_on_rounded,
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey.shade100),
                    _buildCurrencyTile(
                      code: 'KHR',
                      title: 'Currency / រូបិយប័ណ្ណ',
                      subtitle: 'KHR (៛ Riel)',
                      icon: Icons.money_rounded,
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

  // Widget សម្រាប់បង្ហាញជួរនីមួយៗ
  Widget _buildCurrencyTile({
    required String code,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    bool isSelected = selectedCurrency == code;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCurrency = code;
          });
          // អ្នកអាចបន្ថែម Logic រក្សាទុកចូល SharedPreferences ទីនេះបាន
        },
        child: Padding(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'KantumruyPro',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Radio / Check Icon ពេលជ្រើសរើស
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}