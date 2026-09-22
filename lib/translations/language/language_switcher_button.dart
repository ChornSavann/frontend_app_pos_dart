
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_inventory/constants/translate_constants.dart';

class LanguageSwitcherButton extends StatefulWidget {
  const LanguageSwitcherButton({super.key});

  @override
  State<LanguageSwitcherButton> createState() => _LanguageSwitcherButtonState();
}

class _LanguageSwitcherButtonState extends State<LanguageSwitcherButton> {
  void onChangeLanguage() {
    if (Get.locale?.languageCode == TranslateConstants.km) {
      var locale = const Locale(TranslateConstants.en, TranslateConstants.us);
      Get.updateLocale(locale);
    } else {
      var locale = const Locale(TranslateConstants.km, TranslateConstants.kh);
      Get.updateLocale(locale);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isKhmer = Get.locale?.languageCode != TranslateConstants.en;

    return SizedBox(
      height: 40,
      child: InkWell(
        onTap: onChangeLanguage,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isKhmer ? "🇰🇭" : "🇬🇧",
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(width: 6),
              Text(
                isKhmer ? "KH" : "EN",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
