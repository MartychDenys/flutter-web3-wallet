import 'dart:convert';

class TossOrder {
  final String id;
  final String itemName;
  final String emoji;
  final String size;
  final double price;
  final DateTime createdAt;
  final String shipName;
  final String shipCity;
  final String shipAddress;

  const TossOrder({
    required this.id,
    required this.itemName,
    required this.emoji,
    required this.size,
    required this.price,
    required this.createdAt,
    required this.shipName,
    required this.shipCity,
    required this.shipAddress,
  });

  String get status {
    final age = DateTime.now().difference(createdAt);
    if (age.inMinutes < 2) return 'processing';
    if (age.inMinutes < 10) return 'shipped';
    return 'delivered';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'emoji': emoji,
        'size': size,
        'price': price,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'shipName': shipName,
        'shipCity': shipCity,
        'shipAddress': shipAddress,
      };

  factory TossOrder.fromJson(Map<String, dynamic> json) => TossOrder(
        id: json['id'] as String,
        itemName: json['itemName'] as String,
        emoji: json['emoji'] as String,
        size: json['size'] as String,
        price: (json['price'] as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        shipName: json['shipName'] as String,
        shipCity: json['shipCity'] as String,
        shipAddress: json['shipAddress'] as String,
      );

  static String encodeList(List<TossOrder> orders) =>
      jsonEncode(orders.map((o) => o.toJson()).toList());

  static List<TossOrder> decodeList(String source) =>
      (jsonDecode(source) as List)
          .map((j) => TossOrder.fromJson(j as Map<String, dynamic>))
          .toList();
}
