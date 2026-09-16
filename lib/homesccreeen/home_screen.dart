import 'package:flutter/material.dart';

class PosHomeScreen extends StatefulWidget {
  const PosHomeScreen({super.key});

  @override
  State<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends State<PosHomeScreen> {
  final List<Map<String, dynamic>> _categories = [
    {"id": 1, "name": "All", "icon": Icons.grid_view_rounded},
    {"id": 2, "name": "Burgers", "icon": Icons.lunch_dining_rounded},
    {"id": 3, "name": "Drinks", "icon": Icons.local_bar_rounded},
    {"id": 4, "name": "Desserts", "icon": Icons.icecream_rounded},
    {"id": 5, "name": "Snacks", "icon": Icons.cookie_rounded},
  ];

  final List<Map<String, dynamic>> _products = [
    {
      "name": "Classic Cheeseburger",
      "price": 4.99,
      "category": "Burgers",
      "image": "🍔",
    },
    {
      "name": "Crispy Chicken Burger",
      "price": 5.49,
      "category": "Burgers",
      "image": "🍗",
    },
    {
      "name": "Double Beef BBQ Burger",
      "price": 7.99,
      "category": "Burgers",
      "image": "🍔",
    },
    {
      "name": "Spicy Zinger Burger",
      "price": 5.99,
      "category": "Burgers",
      "image": "🌶️",
    },
    {
      "name": "Fish Fillet Burger",
      "price": 4.50,
      "category": "Burgers",
      "image": "🐟",
    },

    // --- DRINKS ---
    {
      "name": "Iced Cafe Latte",
      "price": 3.25,
      "category": "Drinks",
      "image": "☕",
    },
    {
      "name": "Coca Cola Large",
      "price": 1.99,
      "category": "Drinks",
      "image": "🥤",
    },
    {
      "name": "Iced Americano",
      "price": 2.75,
      "category": "Drinks",
      "image": "🥤",
    },
    {
      "name": "Green Tea Frappe",
      "price": 3.99,
      "category": "Drinks",
      "image": "🍵",
    },
    {
      "name": "Fresh Orange Juice",
      "price": 3.50,
      "category": "Drinks",
      "image": "🍊",
    },
    {
      "name": "Mineral Water",
      "price": 0.99,
      "category": "Drinks",
      "image": "💧",
    },

    // --- DESSERTS ---
    {
      "name": "Chocolate Brownie",
      "price": 3.99,
      "category": "Desserts",
      "image": "🍰",
    },
    {
      "name": "Strawberry Cheesecake",
      "price": 4.25,
      "category": "Desserts",
      "image": "🍰",
    },
    {
      "name": "Vanilla Ice Cream Scoop",
      "price": 1.99,
      "category": "Desserts",
      "image": "🍨",
    },
    {
      "name": "Chocolate Glazed Donut",
      "price": 1.50,
      "category": "Desserts",
      "image": "🍩",
    },
    {
      "name": "Macaron Box (3 pcs)",
      "price": 4.50,
      "category": "Desserts",
      "image": "🍬",
    },

    // --- SNACKS ---
    {
      "name": "French Fries XL",
      "price": 2.49,
      "category": "Snacks",
      "image": "🍟",
    },
    {
      "name": "Cheese Loaded Fries",
      "price": 3.75,
      "category": "Snacks",
      "image": "🍟",
    },
    {
      "name": "Fried Chicken Nuggets (6pcs)",
      "price": 2.99,
      "category": "Snacks",
      "image": "🍤",
    },
    {
      "name": "Crispy Onion Rings",
      "price": 2.25,
      "category": "Snacks",
      "image": "🧅",
    },
    {
      "name": "Popcorn Chicken Bucket",
      "price": 4.99,
      "category": "Snacks",
      "image": "🍿",
    },
  ];
  int _selectedCategoryId = 1;

  @override
  Widget build(BuildContext context) {
    // Determine screen width to make it responsive
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      endDrawer: _buildSettingsDrawer(context),
      body: Row(
        children: [
          // Left Side: Product Menu Catalog
          Expanded(flex: isTablet ? 3 : 1, child: _buildMenuCatalog()),

          // Right Side: Fixed Checkout Cart Pane (Only permanent on larger screens)
          if (isTablet)
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Colors.grey[200]!)),
              ),
              child: _buildCartPane(),
            ),
        ],
      ),

      // Floating Cart Action Button for smaller smartphone screens
      // floatingActionButton: !isTablet
      // ? FloatingActionButton.extended(
      //     onPressed: () {
      //       showModalBottomSheet(
      //         context: context,
      //         isScrollControlled: true,
      //         builder: (context) => SizedBox(
      //           height: MediaQuery.of(context).size.height * 0.85,
      //           child: _buildCartPane(),
      //         ),
      //       );
      //     },
      //     backgroundColor: Colors.blueAccent,
      //     icon: const Icon(
      //       Icons.shopping_cart_rounded,
      //       color: Colors.white,
      //     ),
      //     label: const Text(
      //       "View Order (3 items)",
      //       style: TextStyle(color: Colors.white),
      //     ),
      //   )
      // : null,

      //============
      floatingActionButton: Transform.translate(
        offset: const Offset(
          0,
          20,
        ), // 🛠️ ផ្លាស់ទីទម្លាក់ចុះក្រោមតាមអ័ក្ស Y ចំនួន 12 ភិចសែល
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: FloatingActionButton(
            onPressed: () {
              // print("Order/Globe Button Clicked");
            },
            backgroundColor: Colors.blueAccent[400],
            shape: const CircleBorder(),
            elevation: 4,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language_rounded, color: Colors.white, size: 24),
                SizedBox(height: 1),
                Text(
                  "Order",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // បង្កើតខ្សែរលកកោង
        notchMargin: 8.0, // ចម្ងាយរវាងរង្វង់មូល និងរបារស
        color: Colors.white,
        elevation: 15,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ឆ្វេងទី១: Home
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, color: Colors.grey, size: 24),
                      Text(
                        "Home",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // ឆ្វេងទី២: Menu
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.grey,
                        size: 24,
                      ),
                      Text(
                        "Menu",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // ⚠️ ផ្ទាំងទំនេរកណ្តាល៖ សម្រាប់ទុកឱ្យប៊ូតុង FloatingActionButton លៀនចូល
              const SizedBox(width: 45),

              // ស្តាំទី១: Profile
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: Colors.grey,
                        size: 24,
                      ),
                      Text(
                        "Profile",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // ស្តាំទី២: Settings
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: Colors.grey,
                        size: 24,
                      ),
                      Text(
                        "Settings",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. App Bar Component ---
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,

      // Using Flexible to prevent the title from pushing the actions off-screen
      title: Flexible(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.blueAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),

            // Text Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Express POS",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
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
                          "Reg #01 • Chorn Savann",
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

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: Colors.grey[200], thickness: 1),
      ),

      actions: [
        _buildActionCircle(Icons.search_rounded, () {
          // Search Logic...
        }),
        const SizedBox(width: 8),

        Stack(
          alignment: Alignment.center,
          children: [
            _buildActionCircle(Icons.notifications_none_rounded, () {
              _showNotificationSheet(context);
            }),
            Positioned(
              right: 8,
              top: 14,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),

        Builder(
          builder: (context) => _buildActionCircle(
            Icons.settings_outlined,
            () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // Helper for circular buttons to keep the main code clean
  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: onTap,
        splashRadius: 24,
      ),
    );
  }

  // --- 2. Left Menu Component (Categories + Products) ---
  Widget _buildMenuCatalog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Category Selector List
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = cat['id'] == _selectedCategoryId;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(cat['name']),
                  avatar: Icon(
                    cat['icon'],
                    size: 18,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blueAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? Colors.blueAccent : Colors.grey[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    setState(() => _selectedCategoryId = cat['id']);
                  },
                ),
              );
            },
          ),
        ),

        // Product Grid View Grid Setup
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.82,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail Visual PlaceHolder
                        Container(
                          height: 85,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              product['image'],
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          product['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\$${product['price'].toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 3. Right Cart/Checkout Pane Component ---
  Widget _buildCartPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cart Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Current Order",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                label: const Text(
                  "Clear All",
                  style: TextStyle(color: Colors.redAccent),
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Cart Items List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text("🍔", style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Classic Cheeseburger",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "\$4.99 x 2",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildQtyButton(Icons.remove, () {}),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "2",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildQtyButton(Icons.add, () {}),
                    ],
                  ),
                ],
              );
            },
          ),
        ),

        // Pricing Computation Details Summary Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryRow("Subtotal", "\$9.98"),
              _buildSummaryRow("Tax (10%)", "\$1.00"),
              const Divider(height: 20),
              _buildSummaryRow("Total Amount", "\$10.98", isTotal: true),
              const SizedBox(height: 16),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.point_of_sale_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "PROCEED TO PAYMENT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Small Helper Widget for Summary Row entries
  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Small Helper Widget for Cart Quantity buttons
  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.black54),
      ),
    );
  }
}

///
Widget _buildSettingsDrawer(BuildContext context) {
  return Drawer(
    width: 270, // Clean width profile for POS terminals
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Drawer User Profile Header Accent
        UserAccountsDrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.brown,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
          ),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100), // Perfect circle clip
              child: Image.asset(
                'assets/Savann.jpg', // Your local image asset file
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,

                // Fallback placeholder if the file name is ever changed or missing
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person_rounded,
                    color: Colors.blueAccent,
                    size: 32,
                  );
                },
              ),
            ),
          ),
          accountName: const Text(
            "Chorn Savann",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          accountEmail: const Text("Chornsavann@gmail.com"),
        ),

        // 2. Navigation Settings Links Options
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 12, bottom: 8),
                child: Text(
                  "REGISTER MANAGEMENT",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),
              ),
              _buildDrawerItem(
                Icons.high_quality_outlined,
                "Transaction History",
                () {},
              ),
              _buildDrawerItem(
                Icons.analytics_outlined,
                "Shift Reports & X-Read",
                () {},
              ),
              _buildDrawerItem(
                Icons.payments_outlined,
                "Cash Drawer (Open/Close)",
                () {},
              ),

              const Divider(height: 32),

              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text(
                  "SYSTEM CONFIG",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),
              ),
              _buildDrawerItem(
                Icons.print_rounded,
                "Receipt Printer Setup",
                () {},
              ),
              _buildDrawerItem(
                Icons.cloud_sync_rounded,
                "Sync Laravel Database",
                () {},
              ),
              _buildDrawerItem(
                Icons.tune_rounded,
                "Terminal Parameters",
                () {},
              ),
            ],
          ),
        ),

        // 3. Persistent Drawer Logout Footer
        const Divider(height: 1),
        // 3. Persistent Drawer Logout Footer with Session Metrics
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color:
                Colors.grey[50], // Soft background to differentiate the footer
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Full-Width Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Handle terminal lockout / closing shift sessions
                    print("Initiating Close Shift workflow...");
                  },
                  icon: const Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    "CLOSE SHIFT & LOGOUT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent[700],
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Compact helper for setting row parameters clean
Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
  return ListTile(
    leading: Icon(icon, color: Colors.black, size: 22),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: Colors.grey,
    ),
    dense: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    onTap: onTap,
  );
}

//Notication
void _showNotificationSheet(BuildContext context) {
  // Mock data for notification alerts
  final List<Map<String, dynamic>> notifications = [
    {
      "title": "Low Stock Alert!",
      "desc": "Coca Cola Large is running low (Only 5 left).",
      "time": "5 mins ago",
      "type": "warning",
      "icon": Icons.warning_amber_rounded,
      "color": Colors.orange,
    },
    {
      "title": "New Online Order #1042",
      "desc": "Received new order via Food App (2 items).",
      "time": "12 mins ago",
      "type": "info",
      "icon": Icons.delivery_dining_rounded,
      "color": Colors.blue,
    },
    {
      "title": "Database Sync Success",
      "desc": "Categories and products synced with Laravel backend.",
      "time": "1 hr ago",
      "type": "success",
      "icon": Icons.cloud_done_rounded,
      "color": Colors.green,
    },
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hug content size
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Notifications",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "3 New",
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Mark all as read",
                      style: TextStyle(color: Colors.blueAccent[700]),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Notification Items List array
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'], color: item['color'], size: 22),
                    ),
                    title: Text(
                      item['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          item['desc'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['time'],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      // Perform specific notification routing logic here
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
