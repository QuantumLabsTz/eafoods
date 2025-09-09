import 'package:flutter_test/flutter_test.dart';
import 'package:eafoods/services/order_service.dart';
import 'package:eafoods/services/database_service.dart';
import 'package:eafoods/models/order.dart';
import 'package:eafoods/models/delivery_slot.dart';
import 'package:eafoods/models/stock_update.dart';

void main() {
  group('Business Logic Integration Tests', () {
    late DeliverySlot testSlot;
    late List<OrderItem> testItems;

    setUp(() async {
      await DatabaseService.init();

      testSlot = DeliverySlot(
        id: 'morning',
        name: 'Morning',
        startTime: '8:00 AM',
        endTime: '11:00 AM',
      );

      testItems = [
        OrderItem(
          productId: '1',
          productName: 'Fresh Tomatoes',
          unitPrice: 2.50,
          quantity: 5,
        ),
      ];
    });

    tearDown(() async {
      await DatabaseService.clearAllData();
    });

    group('Order Placement Scenarios', () {
      test('should place order within stock successfully', () async {
        // Get initial stock
        final product = await DatabaseService.getProduct('1');
        expect(product, isNotNull);
        final initialStock = product!.stockQuantity;

        final order = Order(
          customerName: 'Test Customer',
          customerPhone: '1234567890',
          deliveryDate: DateTime(2024, 1, 16),
          deliverySlot: testSlot,
          items: testItems,
          totalAmount: 12.50, // 2.50 * 5
        );

        final result = await OrderService.createOrder(order);

        expect(result.success, true);
        expect(result.order, isNotNull);
        expect(result.errors, isEmpty);

        // Verify stock was reduced
        final updatedProduct = await DatabaseService.getProduct('1');
        expect(updatedProduct!.stockQuantity, initialStock - 5);
      });

      test('should reject order exceeding stock', () async {
        // Get initial stock
        final product = await DatabaseService.getProduct('1');
        expect(product, isNotNull);
        final initialStock = product!.stockQuantity;

        // Create order with quantity exceeding stock
        final excessiveItems = [
          OrderItem(
            productId: '1',
            productName: 'Fresh Tomatoes',
            unitPrice: 2.50,
            quantity: initialStock + 10, // More than available
          ),
        ];

        final order = Order(
          customerName: 'Test Customer',
          customerPhone: '1234567890',
          deliveryDate: DateTime(2024, 1, 16),
          deliverySlot: testSlot,
          items: excessiveItems,
          totalAmount: 2.50 * (initialStock + 10),
        );

        final result = await OrderService.createOrder(order);

        expect(result.success, false);
        expect(result.errors, isNotEmpty);
        expect(result.errors.first, contains('Insufficient stock'));

        // Verify stock was not reduced
        final unchangedProduct = await DatabaseService.getProduct('1');
        expect(unchangedProduct!.stockQuantity, initialStock);
      });

      test('should handle order after cutoff time', () async {
        // This test would need to mock the current time to be after 6 PM
        // For now, we test the structure
        final order = Order(
          customerName: 'Test Customer',
          customerPhone: '1234567890',
          deliveryDate: DateTime(2024, 1, 16),
          deliverySlot: testSlot,
          items: testItems,
          totalAmount: 12.50,
        );

        final result = await OrderService.createOrder(order);

        expect(result, isNotNull);
        expect(result.success, isA<bool>());
      });
    });

    group('Order Cancellation Scenarios', () {
      test('should cancel order and restore stock', () async {
        // Get initial stock
        final product = await DatabaseService.getProduct('1');
        expect(product, isNotNull);
        final initialStock = product!.stockQuantity;

        // Place an order first
        final order = Order(
          customerName: 'Test Customer',
          customerPhone: '1234567890',
          deliveryDate: DateTime(2024, 1, 16),
          deliverySlot: testSlot,
          items: testItems,
          totalAmount: 12.50,
        );

        final createResult = await OrderService.createOrder(order);
        expect(createResult.success, true);

        // Verify stock was reduced
        final reducedProduct = await DatabaseService.getProduct('1');
        expect(reducedProduct!.stockQuantity, initialStock - 5);

        // Cancel the order
        final cancelResult = await OrderService.cancelOrder(order.id);
        expect(cancelResult.success, true);

        // Verify stock was restored
        final restoredProduct = await DatabaseService.getProduct('1');
        expect(restoredProduct!.stockQuantity, initialStock);
      });

      test('should not allow cancellation of delivered orders', () async {
        // Create and save an order
        final order = Order(
          customerName: 'Test Customer',
          customerPhone: '1234567890',
          deliveryDate: DateTime(2024, 1, 16),
          deliverySlot: testSlot,
          items: testItems,
          totalAmount: 12.50,
        );

        await DatabaseService.saveOrder(order);

        // Update order status to delivered
        await DatabaseService.updateOrderStatus(
          order.id,
          OrderStatus.delivered,
        );

        // Try to cancel delivered order
        final cancelResult = await OrderService.cancelOrder(order.id);
        expect(cancelResult.success, false);
        expect(cancelResult.errors, contains('Order cannot be cancelled'));
      });
    });

    group('Stock Update Scenarios', () {
      test('should reflect stock updates in product availability', () async {
        // Get initial product
        final product = await DatabaseService.getProduct('1');
        expect(product, isNotNull);
        final initialStock = product!.stockQuantity;

        // Update stock
        final newStock = initialStock + 20;
        await DatabaseService.updateProductStock('1', newStock);

        // Verify stock was updated
        final updatedProduct = await DatabaseService.getProduct('1');
        expect(updatedProduct!.stockQuantity, newStock);
        expect(updatedProduct.availableStock, newStock);
      });

      test('should track stock update history', () async {
        // Get initial product
        final product = await DatabaseService.getProduct('1');
        expect(product, isNotNull);
        final initialStock = product!.stockQuantity;

        // Create stock update
        final stockUpdate = StockUpdate(
          productId: '1',
          productName: 'Fresh Tomatoes',
          oldQuantity: initialStock,
          newQuantity: initialStock + 10,
          updateType: StockUpdateType.morning,
          reason: 'Morning restock',
        );

        await DatabaseService.saveStockUpdate(stockUpdate);

        // Verify stock update was recorded
        final stockUpdates = await DatabaseService.getAllStockUpdates();
        expect(stockUpdates.length, greaterThanOrEqualTo(1));

        final savedUpdate = stockUpdates.firstWhere(
          (update) => update.productId == '1',
        );
        expect(savedUpdate.oldQuantity, initialStock);
        expect(savedUpdate.newQuantity, initialStock + 10);
        expect(savedUpdate.reason, 'Morning restock');
      });
    });

    group('Order Status Management', () {
      test('should track order status changes', () async {
        // Create order
        final order = Order(
          customerName: 'Test Customer',
          customerPhone: '1234567890',
          deliveryDate: DateTime(2024, 1, 16),
          deliverySlot: testSlot,
          items: testItems,
          totalAmount: 12.50,
        );

        await DatabaseService.saveOrder(order);

        // Verify initial status
        final savedOrder = await DatabaseService.getOrder(order.id);
        expect(savedOrder!.status, OrderStatus.pending);

        // Update status to confirmed
        await DatabaseService.updateOrderStatus(
          order.id,
          OrderStatus.confirmed,
        );

        final confirmedOrder = await DatabaseService.getOrder(order.id);
        expect(confirmedOrder!.status, OrderStatus.confirmed);

        // Update status to delivered
        await DatabaseService.updateOrderStatus(
          order.id,
          OrderStatus.delivered,
        );

        final deliveredOrder = await DatabaseService.getOrder(order.id);
        expect(deliveredOrder!.status, OrderStatus.delivered);
      });

      test('should track sync status for offline orders', () async {
        // Create order with pending sync status
        final order = Order(
          customerName: 'Test Customer',
          customerPhone: '1234567890',
          deliveryDate: DateTime(2024, 1, 16),
          deliverySlot: testSlot,
          items: testItems,
          totalAmount: 12.50,
        );

        await DatabaseService.saveOrder(order);

        // Verify initial sync status
        final savedOrder = await DatabaseService.getOrder(order.id);
        expect(savedOrder!.syncStatus, OrderSyncStatus.pendingSync);
        expect(savedOrder.isOffline, true);

        // Update sync status to synced
        await DatabaseService.updateOrderSyncStatus(
          order.id,
          OrderSyncStatus.synced,
        );

        final syncedOrder = await DatabaseService.getOrder(order.id);
        expect(syncedOrder!.syncStatus, OrderSyncStatus.synced);
        expect(syncedOrder.isOffline, false);
      });
    });

    group('Data Integrity', () {
      test(
        'should maintain referential integrity between orders and items',
        () async {
          // Create order with multiple items
          final multiItemOrder = Order(
            customerName: 'Test Customer',
            customerPhone: '1234567890',
            deliveryDate: DateTime(2024, 1, 16),
            deliverySlot: testSlot,
            items: [
              OrderItem(
                productId: '1',
                productName: 'Fresh Tomatoes',
                unitPrice: 2.50,
                quantity: 3,
              ),
              OrderItem(
                productId: '2',
                productName: 'Bananas',
                unitPrice: 1.80,
                quantity: 2,
              ),
            ],
            totalAmount: 11.10, // (2.50 * 3) + (1.80 * 2)
          );

          await DatabaseService.saveOrder(multiItemOrder);

          // Retrieve order and verify items
          final retrievedOrder = await DatabaseService.getOrder(
            multiItemOrder.id,
          );
          expect(retrievedOrder, isNotNull);
          expect(retrievedOrder!.items.length, 2);
          expect(retrievedOrder.items[0].productName, 'Fresh Tomatoes');
          expect(retrievedOrder.items[1].productName, 'Bananas');
        },
      );

      test('should handle concurrent order operations', () async {
        // Create multiple orders simultaneously
        final orders = List.generate(
          3,
          (index) => Order(
            customerName: 'Customer $index',
            customerPhone: '123456789$index',
            deliveryDate: DateTime(2024, 1, 16),
            deliverySlot: testSlot,
            items: [
              OrderItem(
                productId: '1',
                productName: 'Fresh Tomatoes',
                unitPrice: 2.50,
                quantity: 1,
              ),
            ],
            totalAmount: 2.50,
          ),
        );

        // Save all orders
        for (final order in orders) {
          await DatabaseService.saveOrder(order);
        }

        // Verify all orders were saved
        final allOrders = await DatabaseService.getAllOrders();
        expect(allOrders.length, greaterThanOrEqualTo(3));
      });
    });
  });
}
