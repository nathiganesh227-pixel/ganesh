import 'package:flutter/foundation.dart';
import '../models/shopping.dart';
import 'shopping_mock_data.dart';

class ShoppingCartManager extends ChangeNotifier {
  static final ShoppingCartManager instance = ShoppingCartManager._internal();
  ShoppingCartManager._internal() {
    // Seed initial cart item for a ready-to-test out of the box experience
    _items.add(
      CartItem(
        product: ShoppingMockData.products[1], // Air Jordan 1
        selectedVariant: ShoppingMockData.products[1].variants[1],
        quantity: 1,
      ),
    );
  }

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get itemsTotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get discountAmount {
    // 10% promotional member discount
    return itemsTotal > 0 ? (itemsTotal * 0.10).roundToDouble() : 0.0;
  }

  double get platformFee => _items.isEmpty ? 0.0 : 49.0;

  double get gstAmount => (itemsTotal - discountAmount) * 0.18;

  double get grandTotal => itemsTotal - discountAmount + platformFee + gstAmount;

  void addItem(Product product, {ProductVariant? variant, int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.selectedVariant?.id == variant?.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, selectedVariant: variant, quantity: quantity));
    }
    notifyListeners();
  }

  void updateQuantity(int index, int delta) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
