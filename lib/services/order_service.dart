import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import 'database_service.dart';

class OrderService {
  static const String _baseUrl = 'https://api.eafoods.com';
  static const Duration _timeout = Duration(seconds: 10);

  // Business logic constants
  static const int _cutoffHour = 18; // 6:00 PM

  /// Check if current time is after cutoff (6:00 PM)
  static bool isAfterCutoff() {
    final now = DateTime.now();
    return now.hour >= _cutoffHour;
  }

  /// Calculate delivery date based on cutoff time
  static DateTime calculateDeliveryDate(DateTime orderDate) {
    if (isAfterCutoff()) {
      // Orders after 6 PM go to +2 days
      return DateTime(orderDate.year, orderDate.month, orderDate.day + 2);
    } else {
      // Orders before 6 PM go to next day
      return DateTime(orderDate.year, orderDate.month, orderDate.day + 1);
    }
  }

  /// Validate if order can be placed (stock check)
  static Future<List<String>> validateOrder(List<OrderItem> items) async {
    final errors = <String>[];

    for (final item in items) {
      final product = await DatabaseService.getProduct(item.productId);

      if (product == null) {
        errors.add('Product ${item.productName} not found');
        continue;
      }

      if (product.stockQuantity < item.quantity) {
        errors.add(
          'Insufficient stock for ${item.productName}. Available: ${product.stockQuantity}, Requested: ${item.quantity}',
        );
      }
    }

    return errors;
  }

  /// Create a new order
  static Future<OrderResult> createOrder(Order order) async {
    try {
      // Validate order
      final validationErrors = await validateOrder(order.items);
      if (validationErrors.isNotEmpty) {
        return OrderResult(
          success: false,
          order: order,
          errors: validationErrors,
        );
      }

      // Reduce stock immediately when order is created (as per assignment requirements)
      await _updateLocalStock(order.items);

      // Check cutoff time
      if (isAfterCutoff()) {
        // Update delivery date to +2 days
        final updatedOrder = order.copyWith(
          deliveryDate: calculateDeliveryDate(order.createdAt),
        );

        // Save to local storage (offline queue)
        await DatabaseService.saveOrder(updatedOrder);

        return OrderResult(
          success: true,
          order: updatedOrder,
          message:
              'Order placed successfully. Delivery scheduled for ${_formatDate(updatedOrder.deliveryDate)} due to cutoff time.',
        );
      }

      // Try to sync with server
      final syncResult = await _syncOrderToServer(order);

      if (syncResult.success) {
        // Save order as synced
        final syncedOrder = order.copyWith(
          status: OrderStatus.confirmed,
          syncStatus: OrderSyncStatus.synced,
        );
        await DatabaseService.saveOrder(syncedOrder);

        return OrderResult(
          success: true,
          order: syncedOrder,
          message:
              'Order placed successfully. Delivery scheduled for ${_formatDate(order.deliveryDate)}.',
        );
      } else {
        // Save to offline queue
        await DatabaseService.saveOrder(order);

        return OrderResult(
          success: true,
          order: order,
          message:
              'Order saved offline. Will sync when connection is available.',
        );
      }
    } catch (e) {
      // Save to offline queue as fallback
      await DatabaseService.saveOrder(order);

      return OrderResult(
        success: true,
        order: order,
        message: 'Order saved offline due to network error.',
      );
    }
  }

  /// Cancel an order
  static Future<OrderResult> cancelOrder(String orderId) async {
    try {
      final order = await DatabaseService.getOrder(orderId);
      if (order == null) {
        return OrderResult(success: false, errors: ['Order not found']);
      }

      if (!order.canBeCancelled) {
        return OrderResult(
          success: false,
          errors: ['Order cannot be cancelled'],
        );
      }

      // Restore stock
      await _restoreStock(order.items);

      // Update order status
      final cancelledOrder = order.copyWith(
        status: OrderStatus.cancelled,
        syncStatus: OrderSyncStatus.pendingSync,
      );

      await DatabaseService.saveOrder(cancelledOrder);

      // Try to sync cancellation with server
      await _syncOrderToServer(cancelledOrder);

      return OrderResult(
        success: true,
        order: cancelledOrder,
        message: 'Order cancelled successfully',
      );
    } catch (e) {
      return OrderResult(
        success: false,
        errors: ['Failed to cancel order: ${e.toString()}'],
      );
    }
  }

  /// Sync pending orders with server
  static Future<void> syncPendingOrders() async {
    final pendingOrders = await DatabaseService.getPendingSyncOrders();

    for (final order in pendingOrders) {
      try {
        final result = await _syncOrderToServer(order);
        if (result.success) {
          final syncedOrder = order.copyWith(
            syncStatus: OrderSyncStatus.synced,
          );
          await DatabaseService.saveOrder(syncedOrder);
        } else {
          final failedOrder = order.copyWith(
            syncStatus: OrderSyncStatus.failed,
          );
          await DatabaseService.saveOrder(failedOrder);
        }
      } catch (e) {
        final failedOrder = order.copyWith(syncStatus: OrderSyncStatus.failed);
        await DatabaseService.saveOrder(failedOrder);
      }
    }
  }

  /// Sync order to server
  static Future<OrderResult> _syncOrderToServer(Order order) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/orders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(order.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OrderResult(success: true, order: order);
      } else {
        return OrderResult(
          success: false,
          order: order,
          errors: ['Server error: ${response.statusCode}'],
        );
      }
    } catch (e) {
      return OrderResult(
        success: false,
        order: order,
        errors: ['Network error: ${e.toString()}'],
      );
    }
  }

  /// Update local stock when order is created (reduces stock immediately)
  static Future<void> _updateLocalStock(List<OrderItem> items) async {
    for (final item in items) {
      final product = await DatabaseService.getProduct(item.productId);
      if (product != null) {
        final updatedProduct = product.copyWith(
          stockQuantity: product.stockQuantity - item.quantity,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.saveProduct(updatedProduct);
      }
    }
  }

  /// Restore stock after order cancellation
  static Future<void> _restoreStock(List<OrderItem> items) async {
    for (final item in items) {
      final product = await DatabaseService.getProduct(item.productId);
      if (product != null) {
        final updatedProduct = product.copyWith(
          stockQuantity: product.stockQuantity + item.quantity,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.saveProduct(updatedProduct);
      }
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class OrderResult {
  final bool success;
  final Order? order;
  final List<String> errors;
  final String? message;

  OrderResult({
    required this.success,
    this.order,
    this.errors = const [],
    this.message,
  });
}
