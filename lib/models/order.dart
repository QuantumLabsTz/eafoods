import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'product.dart';
import 'delivery_slot.dart';

part 'order.g.dart';

enum OrderStatus { pending, confirmed, cancelled, delivered }

enum OrderSyncStatus { synced, pendingSync, failed }

@JsonSerializable()
class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  // Computed properties for backward compatibility
  double get price => unitPrice;
  String get unit => 'pieces'; // Default unit

  OrderItem({
    String? id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  }) : id = id ?? const Uuid().v4(),
       totalPrice = unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  factory OrderItem.fromProduct(Product product, int quantity) {
    return OrderItem(
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: quantity,
    );
  }
}

@JsonSerializable()
class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final DateTime deliveryDate;
  final DeliverySlot deliverySlot;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final OrderSyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties for backward compatibility
  DateTime get orderDate => createdAt;
  String? get notes => null; // Default to null for now

  Order({
    String? id,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryDate,
    required this.deliverySlot,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.syncStatus = OrderSyncStatus.pendingSync,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  Order copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    DateTime? deliveryDate,
    DeliverySlot? deliverySlot,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    OrderSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get formattedTotalAmount => 'TZS ${totalAmount.toStringAsFixed(2)}';

  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  bool get isOffline =>
      syncStatus == OrderSyncStatus.pendingSync ||
      syncStatus == OrderSyncStatus.failed;
}
