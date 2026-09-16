import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/translate_constants.dart';

class ChangeLaungScreen extends StatefulWidget {
  const ChangeLaungScreen({super.key});

  @override
  State<ChangeLaungScreen> createState() => _ChangeLaungScreenState();
}

class _ChangeLaungScreenState extends State<ChangeLaungScreen> {
  bool isKhmer = true;
  // មុខងារសម្រាប់ប្តូរភាសាជាមួយ GetX
  void onChangeLanguage() {
    print(Get.locale?.languageCode??"");
    setState(() {
      isKhmer = !isKhmer;
    });

    if (Get.locale?.languageCode == TranslateConstants.km) {
      var locale = Locale(TranslateConstants.en, TranslateConstants.us);
      Get.updateLocale(locale);
    } else {
      var locale = Locale(TranslateConstants.km, TranslateConstants.kh);
      Get.updateLocale(locale);
    }
  }
  String _selectedLanguage = 'km';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  // ទាញយកភាសាដែលបានរក្សាទុកក្នុង SharedPreferences
  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'km';
      _isLoading = false;
    });
  }

  // រក្សាទុកភាសាថ្មីចូល SharedPreferences និងប្តូរភាសា GetX
  Future<void> _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);

    setState(() {
      _selectedLanguage = languageCode;
    });

    Locale newLocale;
    if (languageCode == TranslateConstants.km) {
      newLocale = const Locale(TranslateConstants.km, TranslateConstants.kh);
    } else {
      newLocale = const Locale(TranslateConstants.en, TranslateConstants.us);
    }

    // ធ្វើបច្ចុប្បន្នភាពភាសាជាសកលក្នុងកម្មវិធី
    Get.updateLocale(newLocale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title:  Text(
          TranslateConstants.language.tr,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your preferred language',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // 🇰🇭 ភាសាខ្មែរ (Khmer)
            _buildLanguageOption(
              title: 'ភាសាខ្មែរ (Khmer)',
              subtitle: 'Khmer',
              flag: '🇰🇭',
              languageCode: 'km',
            ),
            const SizedBox(height: 12),

            // 🇬🇧 ភាសាអង់គ្លេស (English)
            _buildLanguageOption(
              title: 'English',
              subtitle: 'English',
              flag: '🇬🇧',
              languageCode: 'en',
            ),
          ],
        ),
      ),
    );
  }

  // 🛠️ Widget ជំនួយសម្រាប់បង្ហាញជម្រើសភាសានីមួយៗ
  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String flag,
    required String languageCode,
  }) {
    bool isSelected = _selectedLanguage == languageCode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 30),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue.shade700 : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        trailing: Radio<String>(
          value: languageCode,
          groupValue: _selectedLanguage,
          activeColor: Colors.blue.shade600,
          onChanged: (value) {
            if (value != null) {
              _saveLanguage(value);
            }
          },
        ),
        onTap: () {
          _saveLanguage(languageCode);
        },
      ),
    );
  }
}