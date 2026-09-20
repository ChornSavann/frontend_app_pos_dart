import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  List<Store> stores = [];

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
        stores = storeObjects;
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
              if (!currentContext.mounted) return;

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
                  final Store store =
                      stores[index]; // 🟢 ពេលនេះស្គាល់ជា Store Object ហ្មង

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
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
                              builder: (context) =>
                                  ShowStoreScreen(storeId: store.id),
                            ),
                          ).then((value) {
                            if (!context.mounted) return;
                            if (value == true) {
                              _loadStores();
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // 🖼️ Logo Store using CachedNetworkImage
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child:
                                      store.imageUrl != null &&
                                          store.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: store.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child: SizedBox(
                                                  width: 15,
                                                  height: 15,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                Icons.storefront_rounded,
                                                color: Color(0xFF2563EB),
                                                size: 26,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.storefront_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 26,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // 📝 ព័ត៌មាន Store
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (store.phone != null &&
                                        store.phone!.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.phone,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            store.phone!,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (store.address != null &&
                                        store.address!.isNotEmpty) ...[
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
                                              store.address!,
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
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UpdateStoreScreen(
                                          storeId: store.id,
                                        ),
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    if (result == true) _loadStores();
                                  } else if (value == 'delete') {
                                    _confirmDeleteStore(store.id, store.name);
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateStoreScreen()),
          );
          if (!context.mounted) return;
          if (result == true) _loadStores();
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
