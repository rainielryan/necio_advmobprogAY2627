import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  Cart _emptyCart([int? userId]) {
    return Cart(
      id: 0,
      products: const [],
      total: 0,
      discountedTotal: 0,
      userId: userId ?? cartUserId,
      totalProducts: 0,
      totalQuantity: 0,
    );
  }

  // ENHANCEMENT 3: Use the saved logged-in user's id for the cart.
  // Firebase accounts have no DummyJSON id, so 0 must not be sent to /carts/user/0.
  Future<int?> _savedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id') ?? 0;
    if (id <= 0) return null;
    return id;
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
        return _emptyCart(userId);
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
      final userId = await _savedUserId();
      if (userId == null) {
        _cart = _emptyCart(0);
      } else {
        _cart = await getCartByUserId(userId);
      }
    } catch (e) {
      _error = 'Could not load the cart. Check your connection and try again.';
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
    final userId = await _savedUserId() ?? cartUserId;
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
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
