import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/stores/api_store.dart';
import 'package:pos_inventory/stores/update_store_screen.dart';
import '../msg/appSnackBar.dart';

class ShowStoreScreen extends StatefulWidget {
  final int storeId;

  const ShowStoreScreen({super.key, required this.storeId});

  @override
  State<ShowStoreScreen> createState() => _ShowStoreScreenState();
}

class _ShowStoreScreenState extends State<ShowStoreScreen> {
  final ApiStore apiStore = ApiStore();
  bool isLoading = true;
  Map<String, dynamic>? storeData;

  @override
  void initState() {
    super.initState();
    _fetchStoreDetails();
  }

  Future<void> _fetchStoreDetails() async {
    setState(() => isLoading = true);
    try {
      final data = await apiStore.fetchStoreDetails(widget.storeId);
      setState(() {
        storeData = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching store details: $e');
      setState(() => isLoading = false);
    }
  }

  void _confirmDeleteStore(int storeId, String storeName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Store',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$storeName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              final currentContext = context;
              Navigator.pop(dialogContext);

              bool success = await apiStore.deleteStore(storeId);

              if (success) {
                AppSnackBar.showSuccess(
                  currentContext,
                  'Store deleted successfully! 🗑️',
                );
                Navigator.pop(currentContext, true);
              } else {
                AppSnackBar.showError(
                  currentContext,
                  'Failed to delete store. ❌',
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String logoName = storeData?['logo']?.toString() ?? '';
    if (logoName.startsWith('stores/')) {
      logoName = logoName.replaceFirst('stores/', '');
    }
    String logoUrl = logoName.isNotEmpty
        ? "http://10.0.2.2:8000/stores/$logoName"
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Store Profile',
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
          if (storeData != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UpdateStoreScreen(storeId: widget.storeId),
                    ),
                  ).then((value) {
                    if (value == true) _fetchStoreDetails();
                  });
                },
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : storeData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Store details not found 📭',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 🌟 Modern Gradient Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            image: logoUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(logoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: logoUrl.isEmpty
                              ? const Icon(
                                  Icons.storefront_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 42,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          storeData!['name'] ?? 'Unknown Store',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Active Store',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 📋 Information Details List Card
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
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: CupertinoIcons.phone_fill,
                          label: 'Phone Number',
                          value: storeData!['phone'],
                          iconColor: Colors.green,
                        ),
                        _divider(),
                        _buildInfoTile(
                          icon: CupertinoIcons.mail_solid,
                          label: 'Email Address',
                          value: storeData!['email'],
                          iconColor: Colors.orange,
                        ),
                        _divider(),
                        _buildInfoTile(
                          icon: CupertinoIcons.globe,
                          label: 'Website',
                          value: storeData!['website'],
                          iconColor: Colors.purple,
                        ),
                        _divider(),
                        _buildInfoTile(
                          icon: CupertinoIcons.location_solid,
                          label: 'Address',
                          value: storeData!['address'],
                          iconColor: Colors.redAccent,
                        ),
                        _divider(),
                        _buildInfoTile(
                          icon: CupertinoIcons.text_alignleft,
                          label: 'Description',
                          value: storeData!['description'],
                          iconColor: Colors.blueAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 🗑️ Delete Button Action
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _confirmDeleteStore(
                        widget.storeId,
                        storeData!['name'] ?? 'Store',
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delete Store',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required dynamic value,
    required Color iconColor,
  }) {
    String displayValue = (value != null && value.toString().isNotEmpty)
        ? value.toString()
        : 'Not Provided';

    bool isEmpty = (value == null || value.toString().isEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isEmpty
                        ? Colors.grey.shade400
                        : const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 74,
      endIndent: 20,
      color: Colors.grey.shade100,
    );
  }
}
