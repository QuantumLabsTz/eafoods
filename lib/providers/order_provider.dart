import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/delivery_slot.dart';
import '../services/database_service.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  final List<OrderItem> _cartItems = [];
  DeliverySlot? _selectedDeliverySlot;
  String _customerName = '';
  String _customerPhone = '';
  String _notes = '';
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  List<OrderItem> get cartItems => _cartItems;
  DeliverySlot? get selectedDeliverySlot => _selectedDeliverySlot;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<DeliverySlot> get availableDeliverySlots =>
      DeliverySlot.getDefaultSlots();

  double get cartTotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String get formattedCartTotal => 'TZS ${cartTotal.toStringAsFixed(2)}';

  bool get isCartEmpty => _cartItems.isEmpty;

  bool get canPlaceOrder {
    return _cartItems.isNotEmpty &&
        _selectedDeliverySlot != null &&
        _customerName.isNotEmpty &&
        _customerPhone.isNotEmpty;
  }

  List<Order> get pendingOrders {
    return _orders
        .where(
          (order) =>
              order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed,
        )
        .toList();
  }

  List<Order> get offlineOrders {
    return _orders.where((order) => order.isOffline).toList();
  }

  Future<void> loadOrders() async {
    _setLoading(true);
    _clearError();

    try {
      _orders = await DatabaseService.getAllOrders();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load orders: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void addToCart(Product product, int quantity) {
    // Check if product is already in cart
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      // Update quantity
      final existingItem = _cartItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;

      if (newQuantity <= product.stockQuantity) {
        _cartItems[existingIndex] = OrderItem(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          quantity: newQuantity,
        );
      } else {
        _setError(
          'Cannot add more items. Available stock: ${product.stockQuantity}',
        );
        return;
      }
    } else {
      // Add new item
      if (quantity <= product.stockQuantity) {
        _cartItems.add(OrderItem.fromProduct(product, quantity));
      } else {
        _setError(
          'Cannot add items. Available stock: ${product.stockQuantity}',
        );
        return;
      }
    }

    _clearError();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = OrderItem(
          productId: _cartItems[index].productId,
          productName: _cartItems[index].productName,
          unitPrice: _cartItems[index].unitPrice,
          quantity: quantity,
        );
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void setDeliverySlot(DeliverySlot slot) {
    _selectedDeliverySlot = slot;
    notifyListeners();
  }

  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  void setCustomerPhone(String phone) {
    _customerPhone = phone;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  Future<OrderResult> placeOrder() async {
    if (!canPlaceOrder) {
      return OrderResult(
        success: false,
        errors: ['Please fill in all required fields and add items to cart'],
      );
    }

    _setLoading(true);
    _clearError();

    try {
      final deliveryDate = OrderService.calculateDeliveryDate(DateTime.now());

      final totalAmount = _cartItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      final order = Order(
        customerName: _customerName,
        customerPhone: _customerPhone,
        deliveryDate: deliveryDate,
        deliverySlot: _selectedDeliverySlot!,
        items: List.from(_cartItems),
        totalAmount: totalAmount,
      );

      // Use OrderService to create order (this handles stock reduction)
      final result = await OrderService.createOrder(order);

      if (result.success) {
        _orders.insert(0, result.order!);
        clearCart();
        _resetForm();
      }

      return result;
    } catch (e) {
      final errorResult = OrderResult(
        success: false,
        errors: ['Failed to place order: ${e.toString()}'],
      );
      _setError(errorResult.errors.first);
      return errorResult;
    } finally {
      _setLoading(false);
    }
  }

  Future<OrderResult> cancelOrder(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      await DatabaseService.updateOrderStatus(orderId, OrderStatus.cancelled);

      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: OrderStatus.cancelled);
        notifyListeners(); // Notify UI to rebuild
      }

      return OrderResult(success: true, order: _orders[index], errors: []);
    } catch (e) {
      final errorResult = OrderResult(
        success: false,
        errors: ['Failed to cancel order: ${e.toString()}'],
      );
      _setError(errorResult.errors.first);
      return errorResult;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncPendingOrders() async {
    _setLoading(true);
    _clearError();

    try {
      await OrderService.syncPendingOrders();
      await loadOrders(); // Reload orders to reflect sync status
    } catch (e) {
      _setError('Failed to sync orders: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _resetForm() {
    _selectedDeliverySlot = null;
    _customerName = '';
    _customerPhone = '';
    _notes = '';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      // Update in database
      await DatabaseService.updateOrderStatus(orderId, newStatus);

      // Update in local list
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update order status: ${e.toString()}');
      return false;
    }
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }
}
