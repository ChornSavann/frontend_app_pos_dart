import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_brand.dart';
import 'package:pos_inventory/brand/update_brand_screen.dart';
import 'package:pos_inventory/homesccreeen/screen_home.dart';
import 'package:pos_inventory/models/brand.dart';
import '../constants/baseurl/base_url_api.dart';
import 'create_brand_screen.dart';

class BrandIndexScreen extends StatefulWidget {
  const BrandIndexScreen({super.key});

  @override
  State<BrandIndexScreen> createState() => _BrandIndexScreenState();
}

class _BrandIndexScreenState extends State<BrandIndexScreen> {
  List<BrandModel> _brands = [];
  List<BrandModel> _filteredBrands = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);
    final brands = await ApiBrand().fetchBrands();
    if (mounted) {
      setState(() {
        _brands = brands;
        _filteredBrands = brands;
        _isLoading = false;
      });
    }
  }

  void _filterBrands(String query) {
    final filtered = _brands.where((brand) {
      final nameLower = brand.name.toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower);
    }).toList();

    setState(() {
      _filteredBrands = filtered;
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Success!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteBrand(int id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Delete Brand",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to delete this brand? This action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            setState(() => _isLoading = true);
                            bool success = await ApiBrand().deleteBrand(id);

                            if (!mounted) return;

                            setState(() => _isLoading = false);

                            if (success) {
                              await _loadBrands();
                              _showSuccessDialog("Brand deleted successfully!");
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to delete brand."),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: const Text(
            "Brands Management",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _loadBrands();
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔍 Modern Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search brands...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF4F46E5),
                  size: 22,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF4F46E5),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _filterBrands,
            ),
          ),

          // 📄 Brands List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBrands.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.branding_watermark_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No brands found.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredBrands.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final brand = _filteredBrands[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 🖼️ Brand Logo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    (brand.logo != null &&
                                        brand.logo!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: brand.logo!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey.shade100,
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                                color: Colors.grey,
                                              ),
                                            ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: const Color(
                                          0xFF4F46E5,
                                        ).withValues(alpha: 0.1),
                                        child: const Icon(
                                          Icons.branding_watermark_outlined,
                                          color: Color(0xFF4F46E5),
                                          size: 28,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),

                              // 🏷️ Brand Name & Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      brand.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (brand.description != null &&
                                        brand.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        brand.description!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // ⚙️ Action Buttons (Edit & Delete)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UpdateBrandScreen(brand: brand),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadBrands();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      if (brand.id != null) {
                                        _deleteBrand(brand.id!);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateBrandScreen()),
          );
          if (result == true) {
            _loadBrands();
          }
        },
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Brand",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
