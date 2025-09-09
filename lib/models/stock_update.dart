import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'stock_update.g.dart';

enum StockUpdateType { morning, evening }

@JsonSerializable()
class StockUpdate {
  final String id;
  final String productId;
  final String productName;
  final int oldQuantity;
  final int newQuantity;
  final StockUpdateType updateType;
  final String? reason;
  final DateTime createdAt;

  StockUpdate({
    String? id,
    required this.productId,
    required this.productName,
    required this.oldQuantity,
    required this.newQuantity,
    required this.updateType,
    this.reason,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory StockUpdate.fromJson(Map<String, dynamic> json) =>
      _$StockUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$StockUpdateToJson(this);

  int get stockDifference => newQuantity - oldQuantity;

  String get formattedUpdateType {
    switch (updateType) {
      case StockUpdateType.morning:
        return 'Morning Update';
      case StockUpdateType.evening:
        return 'Evening Update';
    }
  }

  String get formattedTime =>
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
}
