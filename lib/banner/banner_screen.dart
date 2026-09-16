import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AutoPlayBanner extends StatefulWidget {
  const AutoPlayBanner({super.key});

  @override
  State<AutoPlayBanner> createState() => _AutoPlayBannerState();
}

class _AutoPlayBannerState extends State<AutoPlayBanner> {
  final List<Map<String, String>> _banners = [
    {
      'image': 'https://i.pinimg.com/1200x/5f/25/c9/5f25c9e089de4494bbad02253cb79473.jpg',
      'title': 'Special Drink Discount! 🥤',
      'subtitle': 'បញ្ចុះតម្លៃ ២០% រាល់ការបញ្ជាទិញភេសជ្ជៈថ្ងៃនេះ',
    },
    {
      'image': 'https://i.pinimg.com/736x/0d/38/d0/0d38d0e41306868a7ebe55ca950ab1e9.jpg',
      'title': 'New Menu Available 🎉',
      'subtitle': 'រីករាយជាមួយរសជាតិថ្មីដ៏ឈ្ងុយឆ្ងាញ់',
    },
    {
      'image': 'https://i.pinimg.com/1200x/86/76/d1/8676d14dccb55555813613cd2f78001c.jpg',
      'title': 'Fresh & Tasty 🍌',
      'subtitle': 'ស្រស់ស្រាយរាល់ថ្ងៃជាមួយទឹកផ្លែឈើធម្មជាតិ',
    },
  ];

  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            height: 200.0,
            autoPlay: true,
            enlargeCenterPage: false,
            viewportFraction: 0.92,
            aspectRatio: 16 / 9,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: _banners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 🖼️ Background Image
                        Image.network(
                          banner['image']!,
                          fit: BoxFit.cover,
                        ),

                        // 🌑 Gradient Overlay (ធ្វើឱ្យរូបភាពងងឹតបន្តិចផ្នែកខាងក្រោម ដើម្បីឱ្យអក្សរមើលឃើញច្បាស់)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),

                        // 📝 Title & Subtitle ពីលើ Banner
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                banner['title']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner['subtitle']!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
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
        const SizedBox(height: 12),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
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
      ],
    );
  }
}