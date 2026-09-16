import 'package:flutter/material.dart';
import 'package:pos_inventory/api/api_product.dart';
import '../models/Product.dart';

class ListProductScreen extends StatefulWidget {
  final int? categoryId;
  const ListProductScreen({super.key, this.categoryId});

  @override
  State<ListProductScreen> createState() => _ListProductScreenState();
}

class _ListProductScreenState extends State<ListProductScreen> {
  final ApiProduct apiProduct = ApiProduct();
  late Future<List<Product>> _productsFuture;

  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = apiProduct.fetchProducts(categoryId: widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "All Products List",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // 🔄 Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            );
          }


          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // 📭 Empty State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "មិនមានទិន្នន័យផលិតផលទេ",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final products = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 📋 Header សម្រាប់ Product List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "All Products",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "${products.length} items",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 📦 List ផលិតផលខាងក្រោម Header
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final String? imageUrl = product.imageUrl;

                  int currentQty = _quantities[product.id] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(12.0),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Thumbnail រូបភាពតូចខាងឆ្វេង
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, color: Colors.grey),
                              );
                            },
                          )
                              : Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.shopping_bag, color: Colors.blueAccent),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // ព័ត៌មាន Name, Description, Star 5 និង Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.description ?? 'No description',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // ⭐ ផ្កាយ 5 (Star 5)
                              Row(
                                children: List.generate(
                                  5,
                                      (index) => const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // 💲 បង្ហាញតម្លៃលក់ (Selling Price)
                              Text(
                                "\$${product.sellingPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ➕ ➖ ប៊ូតុងបូកដក និងចំនួនសម្រាប់ Order
                        // Container(
                        //   decoration: BoxDecoration(
                        //     color: Colors.green.shade50,
                        //     borderRadius: BorderRadius.circular(12),
                        //     border: Border.all(color: Colors.green.shade200), // 🟢 គែមពណ៌បៃតងខ្ចី
                        //   ),
                        //   child: Row(
                        //     children: [
                        //       // ➖ Decrease Button
                        //       InkWell(
                        //         onTap: () {
                        //           setState(() {
                        //             if (currentQty > 0) {
                        //               _quantities[product.id] = currentQty - 1;
                        //             }
                        //           });
                        //         },
                        //         child: Padding(
                        //           padding: const EdgeInsets.all(8.0),
                        //           child: Icon(
                        //             Icons.remove,
                        //             size: 16,
                        //             color: currentQty > 0 ? Colors.green.shade700 : Colors.grey,
                        //           ),
                        //         ),
                        //       ),
                        //       // 🔢 Quantity Display
                        //       Padding(
                        //         padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        //         child: Text(
                        //           "$currentQty",
                        //           style: TextStyle(
                        //             fontSize: 14,
                        //             fontWeight: FontWeight.bold,
                        //             color: Colors.green.shade800, // 🟢 អក្សរពណ៌បៃតងដិត
                        //           ),
                        //         ),
                        //       ),
                        //       // ➕ Increase Button
                        //       InkWell(
                        //         onTap: () {
                        //           setState(() {
                        //             _quantities[product.id] = currentQty + 1;
                        //           });
                        //         },
                        //         child: Padding(
                        //           padding: const EdgeInsets.all(8.0),
                        //           child: Icon(
                        //             Icons.add,
                        //             size: 16,
                        //             color: Colors.green.shade700, // 🟢 ប៊ូតុងបូកពណ៌បៃតង
                        //           ),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}