import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../widgets/custom_text.dart';

// ENHANCEMENT 1: Detail screen used when a cart item is tapped.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.product});

  final CartProduct product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Product Details',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.network(
                  product.thumbnail,
                  width: double.infinity,
                  height: 220.h,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.image, size: 80.sp),
                ),
              ),
              SizedBox(height: 16.h),
              CustomText(
                text: product.title,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: '\$${product.price.toStringAsFixed(2)}',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: 'Quantity: ${product.quantity}',
                fontSize: 14.sp,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: 'Line total: \$${product.total.toStringAsFixed(2)}',
                fontSize: 14.sp,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text:
                    'Discount: ${product.discountPercentage.toStringAsFixed(2)}%',
                fontSize: 14.sp,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text:
                    'Discounted total: \$${product.discountedTotal.toStringAsFixed(2)}',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
