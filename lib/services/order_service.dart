import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // CREATE ORDER
  // ============================================================

  static Future<String> createOrder({
    required OrderModel order,
  }) async {
    final docRef = await _db.collection('orders').add(
      order.toMap(),
    );

    return docRef.id;
  }

  // ============================================================
  // GET SINGLE ORDER
  // ============================================================

  static Future<OrderModel?> getOrder(
      String orderId,
      ) async {
    final snapshot = await _db
        .collection('orders')
        .doc(orderId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return OrderModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  // ============================================================
  // REALTIME ORDER LISTENER
  // ============================================================

  static Stream<OrderModel?> listenToOrder(
      String orderId,
      ) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return OrderModel.fromMap(
        snapshot.id,
        snapshot.data()!,
      );
    });
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  static Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    await _db
        .collection('orders')
        .doc(orderId)
        .update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // UPDATE PAYMENT STATUS
  // ============================================================

  static Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentStatus paymentStatus,
  }) async {
    await _db
        .collection('orders')
        .doc(orderId)
        .update({
      'paymentStatus': paymentStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // UPDATE BOTH ORDER + PAYMENT STATUS
  // ============================================================

  static Future<void> updateOrderAndPaymentStatus({
    required String orderId,
    required OrderStatus status,
    required PaymentStatus paymentStatus,
  }) async {
    await _db
        .collection('orders')
        .doc(orderId)
        .update({
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // CANCEL ORDER
  // ============================================================

  static Future<void> cancelOrder({
    required String orderId,
  }) async {
    await _db
        .collection('orders')
        .doc(orderId)
        .update({
      'status': OrderStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}