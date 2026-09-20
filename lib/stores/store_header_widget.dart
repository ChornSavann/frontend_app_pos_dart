import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      _storeName = prefs.getString('store_name') ?? "ហាងខ្មែរ";
      _storeLogo = prefs.getString('store_logo') ?? "";
      _storeId = prefs.getInt('store_id') ?? 1;

      String regNo = prefs.getString('register_no') ?? "Reg #01";
      String userName = prefs.getString('name') ?? "Chorn Savann";
      _registerInfo = "$regNo • $userName";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowStoreScreen(storeId: _storeId),
            ),
          );
          if (!context.mounted) return;
          if (result == true) {
            _loadStoreData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _storeLogo.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: _storeLogo, // 🟢 ប្រើ Full URL ផ្ទាល់ពី SharedPreferences
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.storefront_rounded,
                      size: 26,
                      color: Colors.blueAccent,
                    ),
                  )
                      : const Icon(
                    Icons.storefront_rounded,
                    size: 26,
                    color: Colors.blueAccent,
                  ),
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
                      _storeName,
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
                            _registerInfo,
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