import 'package:json_annotation/json_annotation.dart';

part 'delivery_slot.g.dart';

@JsonSerializable()
class DeliverySlot {
  final String id;
  final String name;
  final String startTime;
  final String endTime;

  DeliverySlot({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory DeliverySlot.fromJson(Map<String, dynamic> json) =>
      _$DeliverySlotFromJson(json);
  Map<String, dynamic> toJson() => _$DeliverySlotToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliverySlot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  static List<DeliverySlot> getDefaultSlots() {
    return [
      DeliverySlot(
        id: 'morning',
        name: 'Morning',
        startTime: '8:00 AM',
        endTime: '11:00 AM',
      ),
      DeliverySlot(
        id: 'afternoon',
        name: 'Afternoon',
        startTime: '12:00 PM',
        endTime: '3:00 PM',
      ),
      DeliverySlot(
        id: 'evening',
        name: 'Evening',
        startTime: '4:00 PM',
        endTime: '7:00 PM',
      ),
    ];
  }

  String get timeRange => '$startTime - $endTime';
}
