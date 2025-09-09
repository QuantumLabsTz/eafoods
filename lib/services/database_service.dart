import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/stock_update.dart';
import '../models/delivery_slot.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'eafoods.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _productsTable = 'products';
  static const String _ordersTable = 'orders';
  static const String _orderItemsTable = 'order_items';
  static const String _stockUpdatesTable = 'stock_updates';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<void> init() async {
    try {
      print('DatabaseService: Initializing database...');
      await database;
      print('DatabaseService: Database initialized successfully');
    } catch (e, stackTrace) {
      print('DatabaseService: Error initializing database: $e');
      print('DatabaseService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<Database> _initDatabase() async {
    try {
      print('DatabaseService: Getting database path...');
      String path = join(await getDatabasesPath(), _databaseName);
      print('DatabaseService: Database path: $path');

      print('DatabaseService: Opening database...');
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
      print('DatabaseService: Database opened successfully');
      return db;
    } catch (e, stackTrace) {
      print('DatabaseService: Error in _initDatabase: $e');
      print('DatabaseService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE $_productsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL,
        category TEXT,
        image_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create orders table
    await db.execute('''
      CREATE TABLE $_ordersTable (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        delivery_date TEXT NOT NULL,
        delivery_slot_id TEXT NOT NULL,
        delivery_slot_name TEXT NOT NULL,
        delivery_slot_start_time TEXT NOT NULL,
        delivery_slot_end_time TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create order_items table
    await db.execute('''
      CREATE TABLE $_orderItemsTable (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES $_ordersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create stock_updates table
    await db.execute('''
      CREATE TABLE $_stockUpdatesTable (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        old_quantity INTEGER NOT NULL,
        new_quantity INTEGER NOT NULL,
        update_type TEXT NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES $_productsTable (id) ON DELETE CASCADE
      )
    ''');

    // Insert sample products
    await _insertSampleProducts(db);
  }

  static Future<void> _insertSampleProducts(Database db) async {
    final sampleProducts = [
      {
        'id': '1',
        'name': 'Fresh Tomatoes',
        'description': 'Organic, locally grown tomatoes',
        'price': 2.50,
        'stock_quantity': 100,
        'category': 'Vegetables',
        'image_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Bananas',
        'description': 'Sweet, ripe bananas',
        'price': 1.80,
        'stock_quantity': 150,
        'category': 'Fruits',
        'image_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '3',
        'name': 'Chicken Breast',
        'description': 'Fresh, boneless chicken breast',
        'price': 8.99,
        'stock_quantity': 50,
        'category': 'Meat',
        'image_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '4',
        'name': 'Milk (1L)',
        'description': 'Fresh whole milk',
        'price': 3.20,
        'stock_quantity': 80,
        'category': 'Dairy',
        'image_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '5',
        'name': 'Bread Loaf',
        'description': 'Fresh white bread',
        'price': 2.10,
        'stock_quantity': 60,
        'category': 'Bakery',
        'image_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final product in sampleProducts) {
      await db.insert(_productsTable, product);
    }
  }

  // Product operations
  static Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_productsTable);
    return maps
        .map(
          (map) => Product.fromJson({
            'id': map['id'],
            'name': map['name'],
            'description': map['description'],
            'price': map['price'],
            'stockQuantity': map['stock_quantity'],
            'category': map['category'],
            'imageUrl': map['image_url'],
            'createdAt': map['created_at'],
            'updatedAt': map['updated_at'],
          }),
        )
        .toList();
  }

  static Future<Product?> getProduct(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromJson({
        'id': maps.first['id'],
        'name': maps.first['name'],
        'description': maps.first['description'],
        'price': maps.first['price'],
        'stockQuantity': maps.first['stock_quantity'],
        'category': maps.first['category'],
        'imageUrl': maps.first['image_url'],
        'createdAt': maps.first['created_at'],
        'updatedAt': maps.first['updated_at'],
      });
    }
    return null;
  }

  static Future<void> updateProductStock(String id, int newStock) async {
    final db = await database;
    await db.update(
      _productsTable,
      {
        'stock_quantity': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Order operations
  static Future<String> saveOrder(Order order) async {
    try {
      print('DatabaseService: Starting to save order ${order.id}');
      final db = await database;
      print('DatabaseService: Database connection obtained');

      // Insert or replace order
      await db.insert(_ordersTable, {
        'id': order.id,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'delivery_date': order.deliveryDate.toIso8601String(),
        'delivery_slot_id': order.deliverySlot.id,
        'delivery_slot_name': order.deliverySlot.name,
        'delivery_slot_start_time': order.deliverySlot.startTime,
        'delivery_slot_end_time': order.deliverySlot.endTime,
        'total_amount': order.totalAmount,
        'status': order.status.name,
        'sync_status': order.syncStatus.name,
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': order.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert or replace order items
      print('DatabaseService: Inserting ${order.items.length} order items');
      for (final item in order.items) {
        await db.insert(_orderItemsTable, {
          'id': item.id,
          'order_id': order.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      print('DatabaseService: Order saved successfully');

      return order.id;
    } catch (e, stackTrace) {
      print('DatabaseService: Error saving order: $e');
      print('DatabaseService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<Order>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(_ordersTable);

    List<Order> orders = [];
    for (final orderMap in orderMaps) {
      // Get order items
      final List<Map<String, dynamic>> itemMaps = await db.query(
        _orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [orderMap['id']],
      );

      final items = itemMaps
          .map(
            (itemMap) => OrderItem.fromJson({
              'id': itemMap['id'],
              'productId': itemMap['product_id'],
              'productName': itemMap['product_name'],
              'unitPrice': itemMap['unit_price'],
              'quantity': itemMap['quantity'],
            }),
          )
          .toList();

      // Create delivery slot
      final deliverySlot = DeliverySlot(
        id: orderMap['delivery_slot_id'],
        name: orderMap['delivery_slot_name'],
        startTime: orderMap['delivery_slot_start_time'],
        endTime: orderMap['delivery_slot_end_time'],
      );

      // Create order
      final order = Order(
        id: orderMap['id'],
        customerName: orderMap['customer_name'],
        customerPhone: orderMap['customer_phone'],
        deliveryDate: DateTime.parse(orderMap['delivery_date']),
        deliverySlot: deliverySlot,
        items: items,
        totalAmount: orderMap['total_amount'],
        status: OrderStatus.values.firstWhere(
          (e) => e.name == orderMap['status'],
        ),
        syncStatus: OrderSyncStatus.values.firstWhere(
          (e) => e.name == orderMap['sync_status'],
        ),
        createdAt: DateTime.parse(orderMap['created_at']),
        updatedAt: DateTime.parse(orderMap['updated_at']),
      );

      orders.add(order);
    }

    return orders;
  }

  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final db = await database;
    await db.update(
      _ordersTable,
      {'status': status.name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  static Future<void> updateOrderSyncStatus(
    String orderId,
    OrderSyncStatus syncStatus,
  ) async {
    final db = await database;
    await db.update(
      _ordersTable,
      {
        'sync_status': syncStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  static Future<void> deleteOrder(String orderId) async {
    final db = await database;
    await db.delete(_ordersTable, where: 'id = ?', whereArgs: [orderId]);
  }

  static Future<Order?> getOrder(String orderId) async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      _ordersTable,
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (orderMaps.isEmpty) return null;

    final orderMap = orderMaps.first;

    // Get order items
    final List<Map<String, dynamic>> itemMaps = await db.query(
      _orderItemsTable,
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    final items = itemMaps
        .map((itemMap) => OrderItem.fromJson(itemMap))
        .toList();

    // Create delivery slot
    final deliverySlot = DeliverySlot(
      id: orderMap['delivery_slot_id'],
      name: orderMap['delivery_slot_name'],
      startTime: orderMap['delivery_slot_start_time'],
      endTime: orderMap['delivery_slot_end_time'],
    );

    // Create order
    return Order(
      id: orderMap['id'],
      customerName: orderMap['customer_name'],
      customerPhone: orderMap['customer_phone'],
      deliveryDate: DateTime.parse(orderMap['delivery_date']),
      deliverySlot: deliverySlot,
      items: items,
      totalAmount: orderMap['total_amount'],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == orderMap['status'],
      ),
      syncStatus: OrderSyncStatus.values.firstWhere(
        (e) => e.name == orderMap['sync_status'],
      ),
      createdAt: DateTime.parse(orderMap['created_at']),
      updatedAt: DateTime.parse(orderMap['updated_at']),
    );
  }

  static Future<List<Order>> getPendingSyncOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      _ordersTable,
      where: 'sync_status = ?',
      whereArgs: [OrderSyncStatus.pendingSync.name],
    );

    List<Order> orders = [];
    for (final orderMap in orderMaps) {
      // Get order items
      final List<Map<String, dynamic>> itemMaps = await db.query(
        _orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [orderMap['id']],
      );

      final items = itemMaps
          .map(
            (itemMap) => OrderItem.fromJson({
              'id': itemMap['id'],
              'productId': itemMap['product_id'],
              'productName': itemMap['product_name'],
              'unitPrice': itemMap['unit_price'],
              'quantity': itemMap['quantity'],
            }),
          )
          .toList();

      // Create delivery slot
      final deliverySlot = DeliverySlot(
        id: orderMap['delivery_slot_id'],
        name: orderMap['delivery_slot_name'],
        startTime: orderMap['delivery_slot_start_time'],
        endTime: orderMap['delivery_slot_end_time'],
      );

      // Create order
      final order = Order(
        id: orderMap['id'],
        customerName: orderMap['customer_name'],
        customerPhone: orderMap['customer_phone'],
        deliveryDate: DateTime.parse(orderMap['delivery_date']),
        deliverySlot: deliverySlot,
        items: items,
        totalAmount: orderMap['total_amount'],
        status: OrderStatus.values.firstWhere(
          (e) => e.name == orderMap['status'],
        ),
        syncStatus: OrderSyncStatus.values.firstWhere(
          (e) => e.name == orderMap['sync_status'],
        ),
        createdAt: DateTime.parse(orderMap['created_at']),
        updatedAt: DateTime.parse(orderMap['updated_at']),
      );

      orders.add(order);
    }

    return orders;
  }

  static Future<void> saveProduct(Product product) async {
    final db = await database;
    await db.insert(
      _productsTable,
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Stock update operations
  static Future<void> saveStockUpdate(StockUpdate stockUpdate) async {
    final db = await database;
    await db.insert(_stockUpdatesTable, {
      'id': stockUpdate.id,
      'product_id': stockUpdate.productId,
      'product_name': stockUpdate.productName,
      'old_quantity': stockUpdate.oldQuantity,
      'new_quantity': stockUpdate.newQuantity,
      'update_type': stockUpdate.updateType.name,
      'reason': stockUpdate.reason,
      'created_at': stockUpdate.createdAt.toIso8601String(),
    });
  }

  static Future<List<StockUpdate>> getAllStockUpdates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _stockUpdatesTable,
      orderBy: 'created_at DESC',
    );
    return maps
        .map(
          (map) => StockUpdate.fromJson({
            'id': map['id'],
            'productId': map['product_id'],
            'productName': map['product_name'],
            'oldQuantity': map['old_quantity'],
            'newQuantity': map['new_quantity'],
            'updateType': map['update_type'],
            'reason': map['reason'],
            'createdAt': map['created_at'],
          }),
        )
        .toList();
  }

  // Utility methods
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_ordersTable);
    await db.delete(_orderItemsTable);
    await db.delete(_stockUpdatesTable);
    await db.delete(_productsTable);
    await _insertSampleProducts(db);
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
