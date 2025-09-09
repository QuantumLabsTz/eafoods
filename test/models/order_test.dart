import 'package:flutter_test/flutter_test.dart';
import 'package:eafoods/models/order.dart';
import 'package:eafoods/models/delivery_slot.dart';
import 'package:eafoods/models/product.dart';

void main() {
  group('Order Model Tests', () {
    late Order testOrder;
    late DeliverySlot testSlot;
    late List<OrderItem> testItems;

    setUp(() {
      testSlot = DeliverySlot(
        id: 'morning',
        name: 'Morning',
        startTime: '8:00 AM',
        endTime: '11:00 AM',
      );

      testItems = [
        OrderItem(
          productId: '1',
          productName: 'Test Product 1',
          unitPrice: 10.0,
          quantity: 2,
        ),
        OrderItem(
          productId: '2',
          productName: 'Test Product 2',
          unitPrice: 15.0,
          quantity: 1,
        ),
      ];

      testOrder = Order(
        customerName: 'John Doe',
        customerPhone: '1234567890',
        deliveryDate: DateTime(2024, 1, 15),
        deliverySlot: testSlot,
        items: testItems,
        totalAmount: 35.0, // (10*2) + (15*1) = 35
      );
    });

    test('should create order with correct properties', () {
      expect(testOrder.customerName, 'John Doe');
      expect(testOrder.customerPhone, '1234567890');
      expect(testOrder.deliveryDate, DateTime(2024, 1, 15));
      expect(testOrder.deliverySlot, testSlot);
      expect(testOrder.items.length, 2);
      expect(testOrder.totalAmount, 35.0);
      expect(testOrder.status, OrderStatus.pending);
      expect(testOrder.syncStatus, OrderSyncStatus.pendingSync);
    });

    test('should generate unique ID', () {
      final order1 = Order(
        customerName: 'Customer 1',
        customerPhone: '1111111111',
        deliveryDate: DateTime.now(),
        deliverySlot: testSlot,
        items: testItems,
        totalAmount: 35.0,
      );

      final order2 = Order(
        customerName: 'Customer 2',
        customerPhone: '2222222222',
        deliveryDate: DateTime.now(),
        deliverySlot: testSlot,
        items: testItems,
        totalAmount: 35.0,
      );

      expect(order1.id, isNot(equals(order2.id)));
      expect(order1.id.length, greaterThan(10));
    });

    test('should format total amount correctly', () {
      expect(testOrder.formattedTotalAmount, 'TZS 35.00');
    });

    test('should determine if order can be cancelled', () {
      // Pending orders can be cancelled
      expect(testOrder.canBeCancelled, true);

      // Confirmed orders can be cancelled
      final confirmedOrder = testOrder.copyWith(status: OrderStatus.confirmed);
      expect(confirmedOrder.canBeCancelled, true);

      // Delivered orders cannot be cancelled
      final deliveredOrder = testOrder.copyWith(status: OrderStatus.delivered);
      expect(deliveredOrder.canBeCancelled, false);

      // Cancelled orders cannot be cancelled
      final cancelledOrder = testOrder.copyWith(status: OrderStatus.cancelled);
      expect(cancelledOrder.canBeCancelled, false);
    });

    test('should determine if order is offline', () {
      // Pending sync orders are offline
      expect(testOrder.isOffline, true);

      // Synced orders are not offline
      final syncedOrder = testOrder.copyWith(
        syncStatus: OrderSyncStatus.synced,
      );
      expect(syncedOrder.isOffline, false);

      // Failed sync orders are offline
      final failedOrder = testOrder.copyWith(
        syncStatus: OrderSyncStatus.failed,
      );
      expect(failedOrder.isOffline, true);
    });

    test('should create copy with updated values', () {
      final updatedOrder = testOrder.copyWith(
        customerName: 'Jane Doe',
        status: OrderStatus.confirmed,
        syncStatus: OrderSyncStatus.synced,
      );

      expect(updatedOrder.customerName, 'Jane Doe');
      expect(updatedOrder.status, OrderStatus.confirmed);
      expect(updatedOrder.syncStatus, OrderSyncStatus.synced);
      expect(
        updatedOrder.customerPhone,
        '1234567890',
      ); // Should remain unchanged
      expect(updatedOrder.items.length, 2); // Should remain unchanged
    });

    test('should convert to JSON correctly', () {
      final json = testOrder.toJson();

      expect(json['customerName'], 'John Doe');
      expect(json['customerPhone'], '1234567890');
      expect(json['totalAmount'], 35.0);
      expect(json['status'], 'pending');
      expect(json['syncStatus'], 'pendingSync');
      expect(json['items'], isA<List>());
      expect(json['items'].length, 2);
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-order-id',
        'customerName': 'JSON Customer',
        'customerPhone': '9876543210',
        'deliveryDate': DateTime(2024, 2, 1).toIso8601String(),
        'deliverySlot': {
          'id': 'afternoon',
          'name': 'Afternoon',
          'startTime': '12:00 PM',
          'endTime': '3:00 PM',
        },
        'items': [
          {
            'id': 'item-1',
            'productId': '1',
            'productName': 'JSON Product',
            'unitPrice': 20.0,
            'quantity': 3,
          },
        ],
        'totalAmount': 60.0,
        'status': 'confirmed',
        'syncStatus': 'synced',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2024, 1, 1).toIso8601String(),
      };

      final order = Order.fromJson(json);

      expect(order.id, 'test-order-id');
      expect(order.customerName, 'JSON Customer');
      expect(order.customerPhone, '9876543210');
      expect(order.totalAmount, 60.0);
      expect(order.status, OrderStatus.confirmed);
      expect(order.syncStatus, OrderSyncStatus.synced);
      expect(order.items.length, 1);
    });
  });

  group('OrderItem Model Tests', () {
    late OrderItem testItem;

    setUp(() {
      testItem = OrderItem(
        productId: '1',
        productName: 'Test Product',
        unitPrice: 10.0,
        quantity: 3,
      );
    });

    test('should create order item with correct properties', () {
      expect(testItem.productId, '1');
      expect(testItem.productName, 'Test Product');
      expect(testItem.unitPrice, 10.0);
      expect(testItem.quantity, 3);
    });

    test('should calculate total price correctly', () {
      expect(testItem.totalPrice, 30.0); // 10.0 * 3
    });

    test('should generate unique ID', () {
      final item1 = OrderItem(
        productId: '1',
        productName: 'Product 1',
        unitPrice: 10.0,
        quantity: 1,
      );

      final item2 = OrderItem(
        productId: '2',
        productName: 'Product 2',
        unitPrice: 20.0,
        quantity: 1,
      );

      expect(item1.id, isNot(equals(item2.id)));
    });

    test('should create from product correctly', () {
      final product = Product(
        id: '1',
        name: 'Test Product',
        description: 'A test product',
        price: 15.0,
        stockQuantity: 100,
        category: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item = OrderItem.fromProduct(product, 5);

      expect(item.productId, '1');
      expect(item.productName, 'Test Product');
      expect(item.unitPrice, 15.0);
      expect(item.quantity, 5);
      expect(item.totalPrice, 75.0);
    });

    test('should convert to JSON correctly', () {
      final json = testItem.toJson();

      expect(json['productId'], '1');
      expect(json['productName'], 'Test Product');
      expect(json['unitPrice'], 10.0);
      expect(json['quantity'], 3);
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-item-id',
        'productId': '2',
        'productName': 'JSON Product',
        'unitPrice': 25.0,
        'quantity': 2,
      };

      final item = OrderItem.fromJson(json);

      expect(item.id, 'test-item-id');
      expect(item.productId, '2');
      expect(item.productName, 'JSON Product');
      expect(item.unitPrice, 25.0);
      expect(item.quantity, 2);
      expect(item.totalPrice, 50.0);
    });
  });
}
