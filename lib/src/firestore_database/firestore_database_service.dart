import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreNode {
  final String? id;
  final Object? data;

  FirestoreNode({this.id, this.data});

  @override
  String toString() => 'FirestoreNode(id: $id, data: $data)';
}

class FirestoreException implements Exception {
  final String message;
  final dynamic error;
  FirestoreException(this.message, [this.error]);

  @override
  String toString() => 'FirestoreException: $message ${error ?? ''}';
}

// =================================================================

class FirestoreService {
  static FirebaseFirestore? _db;

  // Init ======================================================================
  /// Khởi tạo Firebase và Firestore Database.
  ///
  /// Gọi hàm này 1 lần duy nhất trước khi dùng các hàm khác.
  static Future<void> init({FirebaseOptions? options}) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      _db = FirebaseFirestore.instance;
    } catch (e) {
      throw FirestoreException("Lỗi khi init Firebase", e);
    }
  }

  // Get safe db reference =====================================================
  static FirebaseFirestore get _safeDb {
    if (_db == null) {
      throw FirestoreException("FirestoreService chưa init(), nhớ gọi init() trước!");
    }
    return _db!;
  }

  // Set Data ==================================================================
  /// Ghi đè hoặc tạo mới một Document tại đường dẫn [collectionPath]/[documentId].
  ///
  /// Note: Sử dụng `set` sẽ **ghi đè hoàn toàn** Document đã tồn tại.
  ///
  /// ```dart
  /// await FirestoreService.set("users/user_123", {"name": "An", "age": 30});
  /// ```
  static Future<void> set(String collectionPath, String documentId, Map<String, dynamic> data) async {
    try {
      await _safeDb.collection(collectionPath).doc(documentId).set(data);
    } catch (e) {
      throw FirestoreException("Không thể set Document tại: $collectionPath/$documentId", e);
    }
  }

  // Add Data =================================================================
  /// Thêm mới một Document với **ID tự sinh** vào Collection tại [collectionPath].
  ///
  /// Note: Trả về **ID** của Document vừa được tạo.
  ///
  /// ```dart
  /// final id = await FirestoreService.add("users", {"name": "Bình", "city": "Hà Nội"});
  /// print(id); // vd: "abcXYZ123"
  /// ```
  static Future<String> add(String collectionPath, Map<String, dynamic> data) async {
    try {
      final docRef = await _safeDb.collection(collectionPath).add(data);
      return docRef.id;
    } catch (e) {
      throw FirestoreException("Không thể thêm Document mới vào Collection: $collectionPath", e);
    }
  }

  // Update Data ===============================================================
  /// Cập nhật một phần dữ liệu của Document tại [collectionPath]/[documentId].
  ///
  /// Note: Nó sẽ tạo thêm các Field có trong `data` nếu chưa có và **không xóa** các Field
  /// con khác không có trong `data`.
  ///
  /// ```dart
  /// await FirestoreService.update("users/user_123", {"age": 35, "status": "active"});
  /// ```
  static Future<void> update(String collectionPath, String documentId, Map<String, dynamic> data) async {
    try {
      await _safeDb.collection(collectionPath).doc(documentId).update(data);
    } catch (e) {
      throw FirestoreException("Không thể update Document tại: $collectionPath/$documentId", e);
    }
  }

  // Delete Data ===============================================================
  /// Xoá Document tại [collectionPath]/[documentId].
  ///
  /// ```dart
  /// await FirestoreService.delete("users/user_123");
  /// ```
  static Future<void> delete(String collectionPath, String documentId) async {
    try {
      await _safeDb.collection(collectionPath).doc(documentId).delete();
    } catch (e) {
      throw FirestoreException("Không thể delete Document tại: $collectionPath/$documentId", e);
    }
  }

  // Get Document ==============================================================
  /// Lấy dữ liệu một lần của Document tại [collectionPath]/[documentId].
  ///
  /// Trả về một đối tượng `FirestoreNode`.
  ///
  /// ```dart
  /// final userNode = await FirestoreService.getDocument("users", "user_123");
  /// print(userNode?.data); // { "name": "An", "age": 35, ... }
  /// ```
  static Future<FirestoreNode?> getDocument(String collectionPath, String documentId) async {
    try {
      final snapshot = await _safeDb.collection(collectionPath).doc(documentId).get();
      if (!snapshot.exists) return null;

      return FirestoreNode(
        id: snapshot.id,
        data: snapshot.data(),
      );
    } catch (e) {
      throw FirestoreException("Không thể get Document tại: $collectionPath/$documentId", e);
    }
  }

  // Get Collection/List =======================================================
  /// Lấy tất cả Document trong Collection tại [collectionPath] một lần.
  ///
  /// Có thể áp dụng [queryBuilder] để thêm các điều kiện lọc, sắp xếp.
  /// Trả về `List<FirestoreNode>`.
  ///
  /// ```dart
  /// final activeUsers = await FirestoreService.getCollection("users",
  ///   queryBuilder: (query) => query.where("status", isEqualTo: "active").limit(10)
  /// );
  /// ```
  static Future<List<FirestoreNode>> getCollection(
      String collectionPath, {
        Query Function(Query query)? queryBuilder,
      }) async {
    try {
      Query query = _safeDb.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => FirestoreNode(
        id: doc.id,
        data: doc.data(),
      )).toList();
    } catch (e) {
      throw FirestoreException("Không thể get Collection tại path: $collectionPath", e);
    }
  }

  // Stream Document - Listen ==================================================
  /// Lắng nghe thay đổi realtime của một Document tại [collectionPath]/[documentId].
  ///
  /// Trả về `Stream<FirestoreNode?>`, emit giá trị mới mỗi khi data thay đổi.
  ///
  /// ```dart
  /// FirestoreService.streamDocument("users", "user_123").listen((node) {
  ///   print("User data thay đổi: ${node?.data}");
  /// });
  /// ```
  static Stream<FirestoreNode?> streamDocument(String collectionPath, String documentId) {
    try {
      return _safeDb.collection(collectionPath).doc(documentId).snapshots().map((snapshot) {
        if (!snapshot.exists) return null;
        return FirestoreNode(id: snapshot.id, data: snapshot.data());
      });
    } catch (e) {
      throw FirestoreException("Không thể stream Document tại: $collectionPath/$documentId", e);
    }
  }

  // Stream Collection - Listen List ===========================================
  /// Lắng nghe thay đổi realtime của Collection tại [collectionPath].
  ///
  /// Có thể áp dụng [queryBuilder] để thêm các điều kiện lọc, sắp xếp.
  /// Trả về `Stream<List<FirestoreNode>>`.
  ///
  /// ```dart
  /// FirestoreService.streamCollection("users").listen((list) {
  ///   print("Danh sách user thay đổi: ${list.length}");
  /// });
  /// ```
  static Stream<List<FirestoreNode>> streamCollection(
      String collectionPath, {
        Query Function(Query query)? queryBuilder,
      }) {
    try {
      Query query = _safeDb.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => FirestoreNode(
          id: doc.id,
          data: doc.data(),
        )).toList();
      });
    } catch (e) {
      throw FirestoreException("Không thể stream Collection tại path: $collectionPath", e);
    }
  }
}