import 'package:flutter/material.dart';
import 'package:pos_inventory/CategoryScreen/update_categpry_screen.dart';
import 'package:pos_inventory/api/api_category.dart';
import 'package:pos_inventory/constants/baseurl/base_image_url.dart';

import '../models/category.dart';

class DetailCategoryScreen extends StatefulWidget {
  final int categoryId;

  const DetailCategoryScreen({super.key, required this.categoryId});

  @override
  State<DetailCategoryScreen> createState() => _DetailCategoryScreenState();
}

class _DetailCategoryScreenState extends State<DetailCategoryScreen> {
  final ApiCategory _apiCategory = ApiCategory();

  CategoryModel? _category;
  bool _isLoading = true;
  final String baseUrl = BaseImageUrl.BaseimageUrl;

  @override
  void initState() {
    super.initState();
    _fetchCategoryDetail();
  }

  Future<void> _fetchCategoryDetail() async {
    setState(() => _isLoading = true);

    CategoryModel? category = await _apiCategory.getCategoryById(
      widget.categoryId,
    );

    setState(() {
      _category = category;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0EA5E9),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Category Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_category != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: "Edit Category",
              onPressed: () async {
                final isChanged = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdateCategoryScreen(id: _category!.id),
                  ),
                );
                if (isChanged == true) {
                  _fetchCategoryDetail();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
            )
          : _category == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "រកមិនឃើញព័ត៌មាន Category ទេ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _fetchCategoryDetail,
                    child: const Text("ព្យាយាមម្ដងទៀត"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child:
                          _category!.imageUrl != null &&
                              _category!.imageUrl!.isNotEmpty
                          ? Image.network(
                              _category!.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      size: 40,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                            )
                          : Container(
                              color: const Color(0xFF0EA5E9).withOpacity(0.1),
                              child: const Icon(
                                Icons.category_rounded,
                                size: 50,
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Category Information",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildInfoRow(
                          icon: Icons.title_rounded,
                          title: "Category Name",
                          value: _category!.name,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ),

                        _buildInfoRow(
                          icon: Icons.description_rounded,
                          title: "Description",
                          value:
                              (_category!.description != null &&
                                  _category!.description!.isNotEmpty)
                              ? _category!.description!
                              : "No description provided.",
                          isDescription: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isDescription = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDescription && value == "No description provided."
                      ? Colors.grey.shade400
                      : const Color(0xFF0F172A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
