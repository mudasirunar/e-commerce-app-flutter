import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/user_profile.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';

/// Service managing Cloud Firestore reads and permitted writes.
class FirestoreService {
  final FirebaseFirestore? _firestore;

  FirestoreService([this._firestore]);

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  // ==================== USER PROFILE ====================

  /// Fetches a user's profile from `users/{uid}`.
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!, uid);
  }

  /// Realtime stream of a user's profile.
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, uid);
    });
  }

  /// Saves or updates the user profile document.
  Future<void> saveUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Updates allowed delivery fields (defaultAddress and phone).
  Future<void> updateDeliveryProfile({
    required String uid,
    required String defaultAddress,
    required String phone,
  }) async {
    await _db.collection('users').doc(uid).update({
      'defaultAddress': defaultAddress.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== CATEGORIES ====================

  /// Fetches active categories sorted by sortOrder.
  Future<List<Category>> getCategories() async {
    final query = await _db
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .get();

    final categories = query.docs
        .map((doc) => Category.fromMap(doc.data(), doc.id))
        .toList();

    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  /// Realtime stream of active categories.
  Stream<List<Category>> watchCategories() {
    return _db
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Category.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  // ==================== PRODUCTS ====================

  /// Fetches active products, optionally filtered by categoryId.
  Future<List<Product>> getProducts({String? categoryId}) async {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    final result = await query.get();
    return result.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Realtime stream of active products.
  Stream<List<Product>> watchProducts({String? categoryId}) {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Fetches a single product by ID.
  Future<Product?> getProductById(String productId) async {
    final doc = await _db.collection('products').doc(productId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Product.fromMap(doc.data()!, doc.id);
  }

  // ==================== CART ====================

  /// Realtime stream of customer cart items from `users/{uid}/cart`.
  Stream<List<CartItem>> watchCart(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Adds or updates item quantity in customer cart.
  Future<void> setCartItem({
    required String uid,
    required String productId,
    required int quantity,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(productId);

    if (quantity <= 0) {
      await docRef.delete();
    } else {
      await docRef.set({
        'productId': productId,
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Deletes an item from customer cart.
  Future<void> removeCartItem({
    required String uid,
    required String productId,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  /// Clears all items in customer cart (e.g. after successful checkout).
  Future<void> clearCart(String uid) async {
    final cartRef = _db.collection('users').doc(uid).collection('cart');
    final snapshot = await cartRef.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ==================== ORDERS ====================

  /// Realtime stream of customer's own orders sorted by createdAt descending.
  Stream<List<OrderModel>> watchCustomerOrders(String uid) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) {
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return orders;
    });
  }

  /// Realtime stream of all orders for Admin view.
  Stream<List<OrderModel>> watchAllOrdersAdmin() {
    return _db.collection('orders').snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) {
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return orders;
    });
  }

  /// Fetches a specific order by ID.
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrderModel.fromMap(doc.data()!, doc.id);
  }
}
