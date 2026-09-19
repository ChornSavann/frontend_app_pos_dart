import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/stores/api_store.dart';
import 'package:pos_inventory/stores/create_store_screen.dart';
import 'package:pos_inventory/stores/show_store_screen.dart';
import 'package:pos_inventory/stores/update_store_screen.dart';

import '../msg/appSnackBar.dart';
import 'models/store.dart';

class IndexStoreScreen extends StatefulWidget {
  const IndexStoreScreen({super.key});

  @override
  State<IndexStoreScreen> createState() => _IndexStoreScreenState();
}

class _IndexStoreScreenState extends State<IndexStoreScreen> {
  final ApiStore apiStore = ApiStore();
  bool isLoading = true;
  List<Map<String, dynamic>> stores = [];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => isLoading = true);
    try {
      final List<Store> storeObjects = await apiStore.fetchStoreInfo();
      setState(() {
        stores = storeObjects.map((store) => store.toJson()).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stores: $e');
      setState(() => isLoading = false);
    }
  }

  // 🗑️ មុខងារលុប Store
  void _confirmDeleteStore(int storeId, String storeName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Store'),
        content: Text('Are you sure you want to delete "$storeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final currentContext = context;

              Navigator.pop(dialogContext);
              bool success = await apiStore.deleteStore(storeId);
              if (success) {
                _loadStores();
                AppSnackBar.showSuccess(
                  currentContext,
                  'Store deleted successfully! 🗑️',
                );
              } else {
                AppSnackBar.showError(
                  currentContext,
                  'Failed to delete store. ❌',
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Store Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStores,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : stores.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No stores found 📭',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF2563EB),
              onRefresh: _loadStores,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  String logoName = store['logo']?.toString() ?? '';
                  if (logoName.startsWith('stores/')) {
                    logoName = logoName.replaceFirst('stores/', '');
                  }
                  String logoUrl = logoName.isNotEmpty
                      ? "http://10.0.2.2:8000/stores/$logoName"
                      : "";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowStoreScreen(
                                storeId:
                                    store['id'],
                              ),
                            ),
                          ).then((value) {
                            // ប្រសិនបើមានការលុប ឬកែប្រែពី ShowStoreScreen វានឹង Refresh ទិន្នន័យមកវិញ
                            if (value == true) {
                              _loadStores();
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // 🖼️ Logo Store
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  image: logoUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(logoUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: logoUrl.isEmpty
                                    ? const Icon(
                                        Icons.storefront_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 26,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),

                              // 📝 ព័ត៌មាន Store
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store['name'] ?? 'Unknown Store',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (store['phone'] != null &&
                                        store['phone'].toString().isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.phone,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            store['phone'],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (store['address'] != null &&
                                        store['address']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.location,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              store['address'],
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                    ],
                                  ],
                                ),
                              ),

                              // ⚙️ Action Buttons (Edit & Delete Menu)
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.grey,
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UpdateStoreScreen(
                                          storeId: store['id'],
                                          storeData: store,
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value == true) _loadStores();
                                    });
                                  } else if (value == 'delete') {
                                    _confirmDeleteStore(
                                      store['id'],
                                      store['name'] ?? 'Store',
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                          color: Colors.blueAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_rounded,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateStoreScreen()),
          ).then((value) {
            if (value == true) _loadStores();
          });
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Store',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
