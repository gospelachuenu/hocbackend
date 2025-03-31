import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:houseofchrist/services/supabase_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _posters = [
    'assets/images/poster1.jpg',
    'assets/images/poster2.jpg',
    'assets/images/poster3.jpg',
    'assets/images/poster4.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/images/HOC.png',
          height: 50,
          width: 50,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 40),
              // User Profile Section
              FutureBuilder<Map<String, dynamic>?>(
                future: SupabaseService().getUserProfile(),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: (profile != null && 
                                profile['avatar_url'] != null && 
                                profile['avatar_url'].toString().isNotEmpty)
                                ? Image.network(
                                    profile['avatar_url'],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading avatar: $error');
                                      return const Icon(Icons.person, size: 45, color: Colors.grey);
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  )
                                : const Icon(Icons.person, size: 45, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile != null 
                              ? '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                              : 'User Name',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close drawer
                            Navigator.pushNamed(context, '/profile').then((_) {
                              // Force rebuild to update profile info
                              setState(() {});
                            });
                          },
                          child: const Text('Edit Profile'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'User ID: ${SupabaseService().currentUser?.id ?? ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.live_tv,
                      title: 'Watch Live',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.pushNamed(context, '/watch-live');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.volunteer_activism,
                      title: 'Give',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.pushNamed(context, '/donation');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.phone,
                      title: 'Contact Us',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.pushNamed(context, '/contact-us');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.people,
                      title: 'Prayer Requests',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.pushNamed(context, '/prayer-requests');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.mic,
                      title: 'Testimony',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.pushNamed(context, '/testimony');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.description,
                      title: 'Terms and Conditions',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.pushNamed(context, '/terms-conditions');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.privacy_tip,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        // TODO: Add Privacy Policy screen
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.event,
                      title: 'Events',
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        // TODO: Add Events screen
                      },
                    ),
                  ],
                ),
              ),
              // Social Media Section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Follow us on',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialButton(
                          imagePath: 'assets/icons/facebook.png',
                          onTap: () {},
                        ),
                        _buildSocialButton(
                          imagePath: 'assets/icons/youtube.png',
                          onTap: () {},
                        ),
                        _buildSocialButton(
                          imagePath: 'assets/icons/instagram.png',
                          onTap: () {},
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tiktok, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await SupabaseService().signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/signin');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Carousel
            SizedBox(
              height: 300,
              child: FlutterCarousel(
                items: _posters.map((poster) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Image.asset(
                          poster,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  );
                }).toList(),
                options: CarouselOptions(
                  height: 300,
                  showIndicator: true,
                  slideIndicator: const CircularSlideIndicator(),
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Welcome Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Welcome to House of Christ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We are delighted to have you here. Join us in worship and fellowship as we grow together in faith.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Navigation Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavButton(
                    icon: Icons.announcement,
                    label: 'Announcements',
                    onTap: () {},
                  ),
                  _buildNavButton(
                    icon: Icons.audiotrack,
                    label: 'Audio',
                    onTap: () {},
                  ),
                  _buildNavButton(
                    icon: Icons.church,
                    label: 'Sermons',
                    onTap: () {},
                  ),
                  _buildNavButton(
                    icon: Icons.book,
                    label: 'Daily Word',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.red[700], size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.red[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildSocialButton({
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          imagePath,
          width: 24,
          height: 24,
        ),
      ),
    );
  }
} 