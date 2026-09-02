import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;
  String? _error;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CartProduct> get items => _cart?.products ?? [];
  bool get isEmpty => items.isEmpty;
  double get subtotal => _cart?.total ?? 0;
  double get discountedTotal => _cart?.discountedTotal ?? 0;

  Cart _emptyCart() {
    return Cart(
      id: 0,
      products: const [],
      total: 0,
      discountedTotal: 0,
      userId: cartUserId,
      totalProducts: 0,
      totalQuantity: 0,
    );
  }

  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // ENHANCEMENT 3: Load only one cart by user id (GET /carts/user/:id).
  Future<Cart> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      if (cartsJson.isEmpty) {
        return _emptyCart();
      }
      return Cart.fromJson(cartsJson.first);
    }

    throw Exception('Failed to load cart for user $userId');
  }

  Future<void> loadUserCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await getCartByUserId(cartUserId);
    } catch (e) {
      _error = e.toString();
      _cart = _emptyCart();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, int>> _payloadFromCart({int? productId, int? quantity}) {
    final products = <Map<String, int>>[];
    var found = false;

    for (final item in items) {
      if (item.id == productId) {
        found = true;
        final nextQuantity = (item.quantity + (quantity ?? 1));
        if (nextQuantity > 0) {
          products.add({'id': item.id, 'quantity': nextQuantity});
        }
      } else {
        products.add({'id': item.id, 'quantity': item.quantity});
      }
    }

    if (!found && productId != null && (quantity ?? 1) > 0) {
      products.add({'id': productId, 'quantity': quantity ?? 1});
    }

    return products;
  }

  // ENHANCEMENT 3: Add to cart via POST /carts/add, passing product id and quantity.
  Future<void> addProductToCart(Product product, {int quantity = 1}) async {
    await _submitCart(_payloadFromCart(productId: product.id, quantity: quantity));
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    final products = items
        .map((item) => {
              'id': item.id,
              'quantity': item.id == productId ? quantity : item.quantity,
            })
        .where((item) => item['quantity']! > 0)
        .toList();
    await _submitCart(products);
  }

  Future<void> _submitCart(List<Map<String, int>> products) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': cartUserId,
        'products': products,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _cart = Cart.fromJson(jsonDecode(response.body));
      notifyListeners();
      return;
    }

    throw Exception('Failed to update cart');
  }
}
