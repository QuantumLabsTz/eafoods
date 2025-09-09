import 'package:flutter_test/flutter_test.dart';
import 'package:eafoods/services/database_service.dart';
import 'package:eafoods/models/product.dart';
import 'package:eafoods/models/order.dart';
import 'package:eafoods/models/delivery_slot.dart';
import 'package:eafoods/models/stock_update.dart';

void main() {
  group('DatabaseService Tests', () {
    setUp(() async {
      // Initialize database for testing
      await DatabaseService.init();
    });

    tearDown(() async {
      // Clean up after each test
      await DatabaseService.clearAllData();
    });

    group('Product Operations', () {
      test('should get all products', () async {
        final products = await DatabaseService.getAllProducts();
        
        expect(products, isA<List<Product>>());
        expect(products.length, greaterThanOrEqualTo(5)); // Should have seeded products
      });

      test('should get product by ID', () async {
        final products = await DatabaseService.getAllProducts();
        if (products.isNotEmpty) {
          final firstProduct = products.first;
          final retrievedProduct = await DatabaseService.getProduct(firstProduct.id);
          
          expect(retrievedProduct, isNotNull);
          expect(retrievedProduct!.id, firstProduct.id);
          expect(retrievedProduct.name, firstProduct.name);
        }
      });

      test('should return null for non-existent product', () async {
        final product = await DatabaseService.getProduct('non-existent-id');
        expect(product, isNull);
      });

      test('should update product stock', () async {
        final products = await DatabaseService.getAllProducts();
        if (products.isNotEmpty) {
          final firstProduct = products.first;
          final newStock = firstProduct.stockQuantity + 10;
          
          await DatabaseService.updateProductStock(firstProduct.id, newStock);
          
          final updatedProduct = await DatabaseService.getProduct(firstProduct.id);
          expect(updatedProduct!.stockQuantity, newStock);
        }
      });

      test('should save product', () async {
        final product = Product(
          id: 'test-product',
          name: 'Test Product',
          description: 'A test product',
          price: 15.0,
          stockQuantity: 50,
          category: 'Test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await DatabaseService.saveProduct(product);
        
        final retrievedProduct = await DatabaseService.getProduct('test-product');
        expect(retrievedProduct, isNotNull);
        expect(retrievedProduct!.name, 'Test Product');
        expect(retrievedProduct.price, 15.0);
      });
    });

    group('Order Operations', () {
      late Order testOrder;

      setUp(() {
        final deliverySlot = DeliverySlot(
          id: 'morning',
          name: 'Morning',
          startTime: '8:00 AM',
          endTime: '11:00 AM',
        );

        final orderItems = [
          OrderItem(
            productId: '1',
            productName: 'Test Product',
            unitPrice: 10.0,
            quantity: 2,
          ),
        ];

        testOrder = Order(
          customerName: 'Test Customer',
          customerPhone: '1234567890',
          deliveryDate: DateTime(2024, 1, 16),
          deliverySlot: deliverySlot,
          items: orderItems,
          totalAmount: 20.0,
        );
      });

      test('should save order', () async {
        final orderId = await DatabaseService.saveOrder(testOrder);
        
        expect(orderId, testOrder.id);
        
        final retrievedOrder = await DatabaseService.getOrder(orderId);
        expect(retrievedOrder, isNotNull);
        expect(retrievedOrder!.customerName, 'Test Customer');
        expect(retrievedOrder.items.length, 1);
      });

      test('should get all orders', () async {
        await DatabaseService.saveOrder(testOrder);
        
        final orders = await DatabaseService.getAllOrders();
        expect(orders, isA<List<Order>>());
        expect(orders.length, greaterThanOrEqualTo(1));
      });

      test('should get order by ID', () async {
        await DatabaseService.saveOrder(testOrder);
        
        final retrievedOrder = await DatabaseService.getOrder(testOrder.id);
        expect(retrievedOrder, isNotNull);
        expect(retrievedOrder!.id, testOrder.id);
        expect(retrievedOrder.customerName, testOrder.customerName);
      });

      test('should return null for non-existent order', () async {
        final order = await DatabaseService.getOrder('non-existent-id');
        expect(order, isNull);
      });

      test('should update order status', () async {
        await DatabaseService.saveOrder(testOrder);
        
        await DatabaseService.updateOrderStatus(testOrder.id, OrderStatus.confirmed);
        
        final updatedOrder = await DatabaseService.getOrder(testOrder.id);
        expect(updatedOrder!.status, OrderStatus.confirmed);
      });

      test('should update order sync status', () async {
        await DatabaseService.saveOrder(testOrder);
        
        await DatabaseService.updateOrderSyncStatus(testOrder.id, OrderSyncStatus.synced);
        
        final updatedOrder = await DatabaseService.getOrder(testOrder.id);
        expect(updatedOrder!.syncStatus, OrderSyncStatus.synced);
      });

      test('should get pending sync orders', () async {
        await DatabaseService.saveOrder(testOrder);
        
        final pendingOrders = await DatabaseService.getPendingSyncOrders();
        expect(pendingOrders, isA<List<Order>>());
        expect(pendingOrders.length, greaterThanOrEqualTo(1));
        
        // All returned orders should have pending sync status
        for (final order in pendingOrders) {
          expect(order.syncStatus, OrderSyncStatus.pendingSync);
        }
      });

      test('should delete order', () async {
        await DatabaseService.saveOrder(testOrder);
        
        await DatabaseService.deleteOrder(testOrder.id);
        
        final deletedOrder = await DatabaseService.getOrder(testOrder.id);
        expect(deletedOrder, isNull);
      });
    });

    group('Stock Update Operations', () {
      test('should save stock update', () async {
        final stockUpdate = StockUpdate(
          productId: '1',
          productName: 'Test Product',
          oldQuantity: 100,
          newQuantity: 80,
          updateType: StockUpdateType.morning,
          reason: 'Morning stock update',
        );

        await DatabaseService.saveStockUpdate(stockUpdate);
        
        final stockUpdates = await DatabaseService.getAllStockUpdates();
        expect(stockUpdates, isA<List<StockUpdate>>());
        expect(stockUpdates.length, greaterThanOrEqualTo(1));
        
        final savedUpdate = stockUpdates.firstWhere(
          (update) => update.id == stockUpdate.id,
        );
        expect(savedUpdate.productName, 'Test Product');
        expect(savedUpdate.oldQuantity, 100);
        expect(savedUpdate.newQuantity, 80);
      });

      test('should get all stock updates', () async {
        final stockUpdate1 = StockUpdate(
          productId: '1',
          productName: 'Product 1',
          oldQuantity: 100,
          newQuantity: 80,
          updateType: StockUpdateType.morning,
        );

        final stockUpdate2 = StockUpdate(
          productId: '2',
          productName: 'Product 2',
          oldQuantity: 50,
          newQuantity: 30,
          updateType: StockUpdateType.evening,
        );

        await DatabaseService.saveStockUpdate(stockUpdate1);
        await DatabaseService.saveStockUpdate(stockUpdate2);
        
        final stockUpdates = await DatabaseService.getAllStockUpdates();
        expect(stockUpdates.length, greaterThanOrEqualTo(2));
      });
    });

    group('Database Initialization', () {
      test('should initialize database successfully', () async {
        // Database should already be initialized in setUp
        final products = await DatabaseService.getAllProducts();
        expect(products, isA<List<Product>>());
      });

      test('should have seeded products', () async {
        final products = await DatabaseService.getAllProducts();
        expect(products.length, greaterThanOrEqualTo(5));
        
        // Check for expected sample products
        final productNames = products.map((p) => p.name).toList();
        expect(productNames, contains('Fresh Tomatoes'));
        expect(productNames, contains('Bananas'));
        expect(productNames, contains('Chicken Breast'));
      });
    });
  });
}
