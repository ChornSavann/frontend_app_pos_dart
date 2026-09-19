import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_inventory/stores/show_store_screen.dart';
class StoreHeaderWidget extends StatefulWidget {
  const StoreHeaderWidget({super.key});

  @override
  State<StoreHeaderWidget> createState() => _StoreHeaderWidgetState();
}

class _StoreHeaderWidgetState extends State<StoreHeaderWidget> {
  String _storeName = "ហាងខ្មែរ";
  String _storeLogo = "";
  int _storeId = 0;
  String _registerInfo = "Reg #01 • Chorn Savann";

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // 🟢 ឥឡូវវាទាញយកឈ្មោះហាងពិតប្រាកដចេញពី 'store_name' មិនមែន 'name' របស់ user ទៀតទេ
      _storeName = prefs.getString('store_name') ?? "ហាងខ្មែរ";
      _storeLogo = prefs.getString('store_logo') ?? "";
      _storeId = prefs.getInt('store_id') ?? 1;

      String regNo = prefs.getString('register_no') ?? "Reg #01";
      String userName = prefs.getString('name') ?? "Chorn Savann"; // ឈ្មោះ user ទុកបង្ហាញខាងក្រោម
      _registerInfo = "$regNo • $userName";
      print("Logo from SF: $_storeLogo");
      // print("Final Logo URL: $logoUrl");
    });
  }

  @override
  Widget build(BuildContext context) {

    String logoName = _storeLogo;
    if (logoName.startsWith('stores/')) {
      logoName = logoName.replaceFirst('stores/', '');
    }
    String logoUrl = logoName.isNotEmpty
        ? "http://10.0.2.2:8000/stores/$logoName"
        : "";

    return Flexible(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowStoreScreen(storeId: _storeId),
            ),
          ).then((value) {
            if (value == true) {
              _loadStoreData();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              // 🖼️ Store Logo Container
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: logoUrl.isNotEmpty
                      ? Image.network(
                    logoUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.storefront_rounded, size: 28, color: Colors.blueAccent),
                  )
                      : const Icon(Icons.storefront_rounded, size: 28, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 10),

              // 📝 Store & User Information Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _storeName, // 🟢 បង្ហាញឈ្មោះហាងដែលទាញបានពី SharedPreferences
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _registerInfo, // 🟢 បង្ហាញ Reg និងឈ្មោះ User ធម្មតា
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}