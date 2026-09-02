import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import 'detail_screen.dart';
import '../widgets/custom_text.dart';

const _priceColor = Color(0xFFE8A317);
const _plusColor = Color(0xFFFFD54F);
const _minusColor = Color(0xFFE0E0E0);

// ENHANCEMENT 1: Make a cart_screen
// ENHANCEMENT 3: Render only one user cart and match the sample cart UI.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();
    final content = _CartBody(cartService: cartService);

    if (!showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Cart',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Icon(Icons.settings, size: 24.sp),
          ),
        ],
      ),
      body: content,
    );
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({required this.cartService});

  final CartService cartService;

  @override
  Widget build(BuildContext context) {
    if (cartService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cartService.error != null && cartService.isEmpty) {
      return Center(
        child: CustomText(
          text: 'Error: ${cartService.error}',
          fontSize: 14.sp,
        ),
      );
    }

    if (cartService.isEmpty) {
      return Center(
        child: CustomText(
          text: 'Your cart is empty.',
          fontSize: 16.sp,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: cartService.items.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final item = cartService.items[index];
              return _CartItemCard(item: item);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: 'Subtotal',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _priceColor,
                  ),
                  CustomText(
                    text: '\$${cartService.subtotal.toStringAsFixed(2)}',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _priceColor,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: 'Delivery Fee',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _priceColor,
                  ),
                  CustomText(
                    text: '\$0.00',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _priceColor,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order confirmed')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _plusColor,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: CustomText(
                    text: 'Confirm Order',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartProduct item;

  @override
  Widget build(BuildContext context) {
    final cartService = context.read<CartService>();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        // ENHANCEMENT 1: Cart items are clickable and open detail_screen.
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(product: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.network(
                  item.thumbnail,
                  width: 64.w,
                  height: 64.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.image, size: 32.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.title,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: '\$${item.price.toStringAsFixed(2)}',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: _priceColor,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text:
                          '${item.discountPercentage.toStringAsFixed(0)}% off - \$${item.total.toStringAsFixed(2)} total',
                      fontSize: 11.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _QtyButton(
                    icon: Icons.add,
                    color: _plusColor,
                    onTap: () {
                      cartService.updateQuantity(item.id, item.quantity + 1);
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: CustomText(
                      text: '${item.quantity}',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.remove,
                    color: _minusColor,
                    onTap: () {
                      cartService.updateQuantity(item.id, item.quantity - 1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.r),
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: Icon(icon, size: 16.sp, color: Colors.black),
        ),
      ),
    );
  }
}
