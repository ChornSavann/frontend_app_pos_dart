import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

class Productmodel {
  final int? id;
  final String name;
  final String description;
  final String image;

  Productmodel({
    this.id,
    required this.name,
    required this.description,
    required this.image,
  });

  factory Productmodel.fromJson(Map<String, dynamic> json) {
    return Productmodel(
      id: json['id'],
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'No description available',
      image: json['image'] ?? '',
    );
  }
}

class BannerProductScreen extends StatefulWidget {
  final int? categoryId;
  const BannerProductScreen({super.key, this.categoryId});

  @override
  State<BannerProductScreen> createState() => _BannerProductScreenState();
}

class _BannerProductScreenState extends State<BannerProductScreen> {
  final String baseUrl = 'http://10.0.2.2:8000/api';
  late Future<List<Productmodel>> _productsFuture;

  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts(categoryId: widget.categoryId);
  }

  Future<List<Productmodel>> fetchProducts({int? categoryId}) async {
    try {
      String url = (categoryId == null || categoryId == 0)
          ? '$baseUrl/products'
          : '$baseUrl/products/category/$categoryId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> decodedData = jsonResponse['data'] ?? [];

        return decodedData.map((dynamic item) {
          return Productmodel.fromJson(item as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception(
          "Failed to load products. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: FutureBuilder<List<Productmodel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
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

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "មិនមានទិន្នន័យផលិតផលទេ",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final products = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🌟 Carousel Slider Banner
                CarouselSlider(
                  carouselController: _controller,
                  options: CarouselOptions(
                    height: 230.0,
                    autoPlay: true,
                    enlargeCenterPage: false,
                    viewportFraction: 0.92,
                    aspectRatio: 16 / 9,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration: const Duration(
                      milliseconds: 800,
                    ),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                  items: products.map((product) {
                    String imageUrl = product.image;
                    if (!imageUrl.startsWith('http')) {
                      imageUrl = 'http://10.0.2.2:8000/$imageUrl';
                    }

                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // 🖼️ Background Image
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  cacheWidth: 1200,
                                  cacheHeight: 800,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // 🌑 Smooth Gradient Overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.1),
                                        Colors.black.withOpacity(0.85),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),

                                // 🏷️ Badge ពិសេសពីលើ Banner (Modern Look)
                                Positioned(
                                  top: 14,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Special Offer",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 📝 Title & Description ពីលើ Banner
                                Positioned(
                                  bottom: 18,
                                  left: 18,
                                  right: 18,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.description,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 🟢 Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: products.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _controller.animateToPage(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentIndex == entry.key ? 24.0 : 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentIndex == entry.key
                              ? const Color(0xFF4F46E5)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // // 📋 Header សម្រាប់ Product List ខាងក្រោម
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       const Text(
                //         "All Products",
                //         style: TextStyle(
                //           fontSize: 16,
                //           fontWeight: FontWeight.bold,
                //           color: Colors.black87,
                //         ),
                //       ),
                //       Text(
                //         "${products.length} items",
                //         style: TextStyle(
                //           fontSize: 13,
                //           color: Colors.grey.shade600,
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 12),

                // 📦 List ផលិតផលខាងក្រោម Banner (Card Layout ស្អាត)
                // ListView.builder(
                //   shrinkWrap: true,
                //   physics: const NeverScrollableScrollPhysics(),
                //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                //   itemCount: products.length,
                //   itemBuilder: (context, index) {
                //     final product = products[index];
                //     String imageUrl = product.image;
                //     if (!imageUrl.startsWith('http')) {
                //       imageUrl = 'http://10.0.2.2:8000/$imageUrl';
                //     }
                //
                //     return Container(
                //       margin: const EdgeInsets.only(bottom: 12.0),
                //       padding: const EdgeInsets.all(12.0),
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.circular(16),
                //         boxShadow: [
                //           BoxShadow(
                //             color: Colors.black.withOpacity(0.03),
                //             blurRadius: 8,
                //             offset: const Offset(0, 3),
                //           ),
                //         ],
                //       ),
                //       child: Row(
                //         children: [
                //           // Thumbnail រូបភាពតូចខាងឆ្វេង
                //           ClipRRect(
                //             borderRadius: BorderRadius.circular(12),
                //             child: Image.network(
                //               imageUrl,
                //               width: 70,
                //               height: 70,
                //               fit: BoxFit.cover,
                //               errorBuilder: (context, error, stackTrace) {
                //                 return Container(
                //                   width: 70,
                //                   height: 70,
                //                   color: Colors.grey.shade200,
                //                   child: const Icon(Icons.image, color: Colors.grey),
                //                 );
                //               },
                //             ),
                //           ),
                //           const SizedBox(width: 14),
                //           // ព័ត៌មាន Name & Description
                //           Expanded(
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   product.name,
                //                   style: const TextStyle(
                //                     fontSize: 15,
                //                     fontWeight: FontWeight.bold,
                //                     color: Colors.black87,
                //                   ),
                //                 ),
                //                 const SizedBox(height: 4),
                //                 Text(
                //                   product.description,
                //                   style: TextStyle(
                //                     fontSize: 12,
                //                     color: Colors.grey.shade600,
                //                   ),
                //                   maxLines: 2,
                //                   overflow: TextOverflow.ellipsis,
                //                 ),
                //               ],
                //             ),
                //           ),
                //         ],
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}
