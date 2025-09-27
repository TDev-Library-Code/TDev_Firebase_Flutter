import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tdev_flutter_firebase/src/realtime_database/error.dart';

class RealtimeService {
  static DatabaseReference? _db;

  // Init ======================================================================
  /// Khởi tạo Firebase và Realtime Database.
  ///
  /// Gọi hàm này 1 lần duy nhất trước khi dùng các hàm khác.
  ///
  /// ```dart
  /// await RealtimeService.init(options: DefaultFirebaseOptions.currentPlatform);
  /// ```
  static Future<void> init({FirebaseOptions? options}) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      _db = FirebaseDatabase.instance.ref();
    } catch (e) {
      throw RealtimeException("Lỗi khi init Firebase", e);
    }
  }

  // Get safe db reference =====================================================
  static DatabaseReference get _safeDb {
    if (_db == null) {
      throw RealtimeException("RealtimeService chưa init(), nhớ gọi init() trước!");
    }
    return _db!;
  }

  // Set Data ==================================================================
  /// Ghi đè dữ liệu tại [path].
  ///
  /// ```dart
  /// await RealtimeService.setData("users/123", {"name": "Mày", "age": 20});
  /// ```
  static Future<void> setData(String path, Map<String, dynamic> data) async {
    try {
      await _safeDb.child(path).set(data);
    } catch (e) {
      throw RealtimeException("Không thể setData tại path: $path", e);
    }
  }

  // Push Data =================================================================
  /// Thêm mới dữ liệu với id tự sinh tại [path].
  ///
  /// Trả về `key` vừa được Firebase tạo.
  ///
  /// ```dart
  /// final id = await RealtimeService.pushData("users", {"name": "Tèo", "age": 25});
  /// print(id); // vd: "-Nabcd1234"
  /// ```
  static Future<String> pushData(String path, Map<String, dynamic> data) async {
    try {
      final newRef = _safeDb.child(path).push();
      await newRef.set(data);
      return newRef.key!;
    } catch (e) {
      throw RealtimeException("Không thể pushData tại path: $path", e);
    }
  }

  // Update Data ===============================================================
  /// Cập nhật một phần dữ liệu tại [path].
  ///
  /// ```dart
  /// await RealtimeService.updateData("users/123", {"age": 30});
  /// ```
  static Future<void> updateData(String path, Map<String, dynamic> data) async {
    try {
      await _safeDb.child(path).update(data);
    } catch (e) {
      throw RealtimeException("Không thể updateData tại path: $path", e);
    }
  }

  // Delete Data ===============================================================
  /// Xoá node tại [path].
  ///
  /// ```dart
  /// await RealtimeService.deleteData("users/123");
  /// ```
  static Future<void> deleteData(String path) async {
    try {
      await _safeDb.child(path).remove();
    } catch (e) {
      throw RealtimeException("Không thể deleteData tại path: $path", e);
    }
  }

  //  Get Data ==================================================================
  /// Lấy dữ liệu một lần tại [path].
  ///
  /// Trả về giá trị raw (có thể là `Map`, `List`, `String`, ...).
  ///
  /// ```dart
  /// final user = await RealtimeService.getData("users/123");
  /// print(user); // { "name": "Mày", "age": 20 }
  /// ```
  static Future<dynamic> getData(String path) async {
    try {
      final snapshot = await _safeDb.child(path).get();
      return snapshot.exists ? snapshot.value : null;
    } catch (e) {
      throw RealtimeException("Không thể getData tại path: $path", e);
    }
  }

  //  Get List =================================================================
  /// Lấy danh sách dữ liệu tại [path].
  ///
  /// Chỉ nên dùng khi node đó chứa nhiều object con (kiểu Map của Map).
  /// Trả về `List<Map<String, dynamic>>`.
  ///
  /// ```dart
  /// final users = await RealtimeService.getList("users");
  /// print(users);
  /// // [
  /// //   { "name": "A", "age": 20 },
  /// //   { "name": "B", "age": 25 }
  /// // ]
  /// ```
  static Future<List<Map<String, dynamic>>> getList(String path) async {
    try {
      final snapshot = await _safeDb.child(path).get();
      if (!snapshot.exists) return [];

      if (snapshot.value is! Map) {
        throw RealtimeException("Dữ liệu tại path $path không phải dạng Map");
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw RealtimeException("Không thể getList tại path: $path", e);
    }
  }

  // Stream - Listen ===========================================================
  /// Lắng nghe thay đổi realtime tại [path].
  ///
  /// Trả về `Stream<dynamic>`, mỗi lần data thay đổi thì emit giá trị mới.
  ///
  /// ```dart
  /// RealtimeService.listen("users").listen((data) {
  ///   print("Có thay đổi: $data");
  /// });
  /// ```
  static Stream<dynamic> listen(String path) {
    try {
      return _safeDb.child(path).onValue.map((event) => event.snapshot.value);
    } catch (e) {
      throw RealtimeException("Không thể listen tại path: $path", e);
    }
  }

  //  Stream Events ============================================================
  /// Lắng nghe realtime tại [path], tự động gọi callback tương ứng khi
  /// child được thêm, sửa hoặc xoá.
  ///
  /// Trả về danh sách `StreamSubscription`, có thể dùng `.cancel()` để
  /// ngừng lắng nghe.
  ///
  /// ```dart
  /// final subs = RealtimeService.onStreamEvent(
  ///   "users",
  ///   onAdded: (snapshot) {
  ///     print("Child mới: ${snapshot.value}");
  ///   },
  ///   onChanged: (snapshot) {
  ///     print("Child thay đổi: ${snapshot.value}");
  ///   },
  ///   onRemoved: (snapshot) {
  ///     print("Child bị xoá: ${snapshot.key}");
  ///   },
  /// );
  ///
  /// // Khi không cần lắng nghe nữa
  /// for (var sub in subs) {
  ///   sub.cancel();
  /// }
  /// ```

  static List<StreamSubscription> onStreamEvent(
      String path, {
        void Function(DataSnapshot snapshot)? onAdded,
        void Function(DataSnapshot snapshot)? onChanged,
        void Function(DataSnapshot snapshot)? onRemoved,
      }) {
    final ref = _safeDb.child(path);
    final subs = <StreamSubscription>[];

    if (onAdded != null) {
      subs.add(ref.onChildAdded.listen((event) => onAdded(event.snapshot)));
    }
    if (onChanged != null) {
      subs.add(ref.onChildChanged.listen((event) => onChanged(event.snapshot)));
    }
    if (onRemoved != null) {
      subs.add(ref.onChildRemoved.listen((event) => onRemoved(event.snapshot)));
    }

    return subs;
  }
}
