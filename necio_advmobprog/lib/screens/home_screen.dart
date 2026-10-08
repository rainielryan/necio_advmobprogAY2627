import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _showChat = false;
  String _firstName = 'Profile';
  final PageController _pageController = PageController();

  static const int _cartIndex = 1;

  @override
  void initState() {
    super.initState();
    UserService().getUser().then((user) {
      if (!mounted) return;
      setState(() {
        _firstName = user.firstName.isNotEmpty ? user.firstName : 'Profile';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: (_selectedIndex == 0 && !_showChat)
              ? Image.asset(
                  'assets/images/nubdexchange_logo.png',
                  scale: 11.sp,
                )
              : CustomText(
                  text: _showChat
                      ? 'Chat'
                      : (_selectedIndex == _cartIndex)
                          ? 'Cart'
                          : (_selectedIndex == 2)
                              ? _firstName
                              : 'Home',
                  fontSize: 20.sp,
                  // color: FB_LIGHT_PRIMARY,
                  fontWeight: FontWeight.w600,
                ),
          actions: [
            // ENHANCEMENT 1: Open cart_screen to render the carts API endpoint.
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              icon: Icon(Icons.shopping_cart_outlined, size: 24.sp),
            ),
            // ENHANCEMENT 3: Open settings page (dark/light mode switch).
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: Icon(Icons.settings, size: 24.sp),
            ),
          ],
        ),
        body: Stack(
          children: [
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: const <Widget>[
                ProductScreen(),
                CartScreen(showAppBar: false),
                // ENHANCEMENT 3: Profile tab renders the saved User model.
                ProfileScreen(),
              ],
              onPageChanged: (page) {
                setState(() {
                  _selectedIndex = page;
                  _showChat = false;
                });
              },
            ),
            if (_showChat) const Positioned.fill(child: ChatScreen()),
          ],
        ),
        // ENHANCEMENT 1: FloatingActionButton opens the chat list.
        // ENHANCEMENT 2: Hide the FloatingActionButton on cart_screen.
        floatingActionButton: _selectedIndex == _cartIndex
            ? null
            : FloatingActionButton(
                backgroundColor: const Color(0xFFFFD54F),
                onPressed: () {
                  setState(() {
                    _showChat = true;
                  });
                },
                child: const Icon(Icons.chat, color: Colors.black),
              ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false, //selected item
          showUnselectedLabels: false, //unselected item
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
      _showChat = false;
    });
    _pageController.jumpToPage(value);
  }
}
