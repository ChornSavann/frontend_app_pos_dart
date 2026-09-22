import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/api/stores/api_store.dart';
import 'package:pos_inventory/stores/models/store.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final ApiStore _apiStore = ApiStore();
  Store? _store;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  Future<void> _fetchStoreData() async {
    setState(() => _isLoading = true);
    try {
      List<Store> stores = await _apiStore.fetchStoreInfo();
      if (mounted) {
        setState(() {
          _store = stores.isNotEmpty ? stores.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("❌ ERROR fetching store in AboutScreen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'អំពីហាង (About Store)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
            fontFamily: 'KantumruyPro',
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: const Color(0xFF1E293B),
              onPressed: _fetchStoreData,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
                strokeWidth: 2,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 26,
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
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                (_store?.imageUrl != null &&
                                    _store!.imageUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: _store!.imageUrl!,
                                    width: 86,
                                    height: 86,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.storefront_rounded,
                                          size: 45,
                                          color: Color(0xFF2563EB),
                                        ),
                                  )
                                : Container(
                                    width: 86,
                                    height: 86,
                                    color: Colors.blue.shade50,
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      size: 45,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _store?.name.isNotEmpty == true
                              ? _store!.name
                              : 'Khmer APP Store',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'KantumruyPro',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Version 1.0.0 (Build 2026 By Chorn Savann)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          _buildAboutTile(
                            icon: Icons.store_rounded,
                            title: 'Store Name',
                            subtitle: _store?.name.isNotEmpty == true
                                ? _store!.name
                                : 'N/A',
                          ),
                          Divider(
                            height: 1,
                            indent: 68,
                            color: Colors.grey.shade100,
                          ),
                          _buildAboutTile(
                            icon: Icons.location_on_rounded,
                            title: 'Address / Location',
                            subtitle:
                                (_store?.address != null &&
                                    _store!.address!.isNotEmpty)
                                ? _store!.address!
                                : 'Phnom Penh, Cambodia',
                          ),
                          Divider(
                            height: 1,
                            indent: 68,
                            color: Colors.grey.shade100,
                          ),
                          _buildAboutTile(
                            icon: Icons.phone_rounded,
                            title: 'Phone Number',
                            subtitle:
                                (_store?.phone != null &&
                                    _store!.phone!.isNotEmpty)
                                ? _store!.phone!
                                : '+855 12 345 678',
                            actionIcon: Icons.phone_forwarded_rounded,
                            onActionTap: () {
                              // Optional: លោតចូលកម្មវិធី Call ផ្ទាល់
                              final phone = _store?.phone;
                              if (phone != null && phone.isNotEmpty) {
                                launchUrl(Uri.parse('tel:$phone'));
                              }
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 68,
                            color: Colors.grey.shade100,
                          ),
                          _buildAboutTile(
                            icon: Icons.email_rounded,
                            title: 'Email Address',
                            subtitle:
                                (_store?.email != null &&
                                    _store!.email!.isNotEmpty)
                                ? _store!.email!
                                : 'support@khmerapp.com',
                            actionIcon: Icons.send_rounded,
                            onActionTap: () {
                              // Optional: លោតចូល Email ផ្ទាល់
                              final email = _store?.email;
                              if (email != null && email.isNotEmpty) {
                                launchUrl(Uri.parse('mailto:$email'));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer Copyright
                  Text(
                    '© 2026 Khmer APP. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAboutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? actionIcon,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (actionIcon != null && onActionTap != null)
            IconButton(
              icon: Icon(actionIcon, size: 18, color: const Color(0xFF2563EB)),
              onPressed: onActionTap,
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}
