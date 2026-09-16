import 'package:flutter/material.dart';

class LanguageSwitcherButton extends StatefulWidget {
  const LanguageSwitcherButton({super.key});

  @override
  State<LanguageSwitcherButton> createState() => _LanguageSwitcherButtonState();
}

class _LanguageSwitcherButtonState extends State<LanguageSwitcherButton> {
  bool isKhmer = true;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          isKhmer = !isKhmer;
        });
      },
      borderRadius: BorderRadius.circular(35),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isKhmer ? Colors.blue.shade50 : Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isKhmer ? Colors.blue.shade200 : Colors.indigo.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ទង់ជាតិមានទំហំសមល្មម
            Text(
              isKhmer ? "🇰🇭" : "🇬🇧",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(width: 5),
            // អក្សរកាត់ KH / EN ធ្វើឱ្យ AppBar មើលទៅមិនសូវណែន
            Text(
              isKhmer ? "KH" : "EN",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isKhmer ? Colors.blue.shade800 : Colors.indigo.shade800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}