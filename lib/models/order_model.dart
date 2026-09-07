import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  accepted,
  modified,
  rejected,
  paid,
  preparing,
  pickedUp,
  delivered,
  cancelled,
}

enum PaymentStatus {
  pending,
  paid,
  refunded,
}

class OrderItem {
  final String postId;
  final String foodName;
  final int quantity;
  final double price;

  OrderItem({
    required this.postId,
    required this.foodName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'foodName': foodName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      postId: map['postId'] ?? '',
      foodName: map['foodName'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}

class OrderModel {
  final String id;
  final String chatId;
  final String customerId;
  final String chefId;

  final List<OrderItem> items;

  final double subtotal;
  final double deliveryCharge;
  final double total;

  final OrderStatus status;
  final PaymentStatus paymentStatus;

  final String address;
  final String customerPhone;

  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.chatId,
    required this.customerId,
    required this.chefId,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.address,
    required this.customerPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'customerId': customerId,
      'chefId': chefId,

      'items': items.map((e) => e.toMap()).toList(),

      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'total': total,

      'status': status.name,
      'paymentStatus': paymentStatus.name,

      'address': address,
      'customerPhone': customerPhone,

      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory OrderModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    return OrderModel(
      id: id,

      chatId: map['chatId'] ?? '',
      customerId: map['customerId'] ?? '',
      chefId: map['chefId'] ?? '',

      items: (map['items'] as List? ?? [])
          .map(
            (e) => OrderItem.fromMap(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),

      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryCharge: (map['deliveryCharge'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),

      status: OrderStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),

      paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),

      address: map['address'] ?? '',
      customerPhone: map['customerPhone'] ?? '',

      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  // ============================================================
  // FIRESTORE DATE HELPER
  // ============================================================

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}