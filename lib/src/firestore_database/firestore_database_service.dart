import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tdev_flutter_firebase/src/firestore_database/dto.dart';
import 'package:tdev_flutter_firebase/src/firestore_database/error.dart';

typedef QueryBuilder = Query Function(Query query);

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
  /// Trả về một đối tượng `FirestoreDocument?`.
  static Future<FirestoreDocument?> getDocument(String collectionPath, String documentId) async {
    try {
      final snapshot = await _safeDb.collection(collectionPath).doc(documentId).get();
      if (!snapshot.exists) return null;

      // Chuyển đổi từ DocumentSnapshot sang FirestoreDocument
      return FirestoreDocument(
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
  /// Trả về `List<FirestoreDocument>`.
  static Future<List<FirestoreDocument>> getCollection(
      String collectionPath, {
        QueryBuilder? queryBuilder,
      }) async {
    try {
      Query query = _safeDb.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => FirestoreDocument(
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
  /// Trả về `Stream<FirestoreDocument?>`.
  static Stream<FirestoreDocument?> streamDocument(String collectionPath, String documentId) {
    try {
      return _safeDb.collection(collectionPath).doc(documentId).snapshots().map((snapshot) {
        if (!snapshot.exists) return null;
        return FirestoreDocument(id: snapshot.id, data: snapshot.data());
      });
    } catch (e) {
      throw FirestoreException("Không thể stream Document tại: $collectionPath/$documentId", e);
    }
  }

  // Stream Collection - Listen List ===========================================
  /// Lắng nghe thay đổi realtime của Collection tại [collectionPath].
  ///
  /// Trả về `Stream<List<FirestoreDocument>>`.
  static Stream<List<FirestoreDocument>> streamCollection(
      String collectionPath, {
        QueryBuilder? queryBuilder,
      }) {
    try {
      Query query = _safeDb.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => FirestoreDocument(
          id: doc.id,
          data: doc.data(),
        )).toList();
      });
    } catch (e) {
      throw FirestoreException("Không thể stream Collection tại path: $collectionPath", e);
    }
  }
}