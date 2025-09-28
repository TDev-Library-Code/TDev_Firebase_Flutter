import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tdev_flutter_firebase/src/realtime_database/node.dart';
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
  /// Ghi đè dữ liệu tại [path]. Thường dùng cho trường hợp ghi đè một object.
  ///
  /// ++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ///
  /// Note: `node` sẽ bị `xóa tất cả` và ghi lại hoàn toàn vì vậy các `node` đã có trong
  /// firebase nhưng `không có` trong [data] sẽ bị mất.
  ///
  /// +++++++++++++++++++++++++++++++++++++++++++++++++++++
  ///
  /// ```dart
  /// await RealtimeService.setData("users/123", {"name": "Mày", "age": 20});
  /// ```
  static Future<void> set(String path, Object? data) async {
    try {
      await _safeDb.child(path).set(data);
    } catch (e) {
      throw RealtimeException("Không thể setData tại path: $path", e);
    }
  }

  // Push Data =================================================================
  /// Thêm mới dữ liệu với id tự sinh tại [path]. Thường dùng cho trường hợp thêm
  /// dữ liệu mới vào một danh sách.
  ///
  /// Dữ liệu được thêm vào danh sách với `node id` tự sinh (kiểu `-Nabcd1234`).
  /// ++++++++++++++++++++++++++++++++++++++++++++++++++++
  ///
  /// Node: lưu lại `id` trả về để có thể sửa/xoá sau này.
  ///
  ///++++++++++++++++++++++++++++++++++++++++++++++++++++
  /// ```dart
  /// final id = await RealtimeService.pushData("users", {"name": "Tèo", "age": 25});
  /// print(id); // vd: "-Nabcd1234"
  /// ```
  static Future<String> push(String path, Object? data) async {
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
  /// Thường dùng cho trường hợp cập nhật một vài trường của object.
  ///
  /// +++++++++++++++++++++++++++++++++++++++++++++++++++++
  ///
  /// Note: Nó sẽ tạo thêm các `node` có trong `data` nếu `chưa có` và `không xoá` các `node`
  /// con khác `không có` trong `data`.
  ///
  /// +++++++++++++++++++++++++++++++++++++++++++++++++++++
  ///
  /// ```dart
  /// await RealtimeService.updateData("users/123", {"age": 30});
  /// ```
  static Future<void> update(String path, Map<String, Object?> data) async {
    try {
      await _safeDb.child(path).update(data);
    } catch (e) {
      throw RealtimeException("Không thể updateData tại path: $path", e);
    }
  }

  // Delete Data ===============================================================
  /// Xoá node tại [path].
  ///
  /// +++++++++++++++++++++++++++++++++++++++++++++++++++++
  ///
  /// Note: Nhớ xóa đúng `node` cần thiết tránh xóa `node` cha gây mất dữ liệu.
  ///
  /// +++++++++++++++++++++++++++++++++++++++++++++++++++++
  /// ```dart
  /// await RealtimeService.deleteData("users/123");
  /// ```
  static Future<void> delete(String path) async {
    try {
      await _safeDb.child(path).remove();
    } catch (e) {
      throw RealtimeException("Không thể deleteData tại path: $path", e);
    }
  }

  //  Get Data =================================================================
  /// Lấy dữ liệu một lần tại [path].
  ///
  /// Trả về giá trị raw (có thể là `Map`, `List`, `String`, ...).
  ///
  /// ```dart
  /// final user = await RealtimeService.getData("users/123");
  /// print(user); // { "name": "Mày", "age": 20 }
  /// ```
  static Future<Node> getNode(String path) async {
    try {
      final snapshot = await _safeDb.child(path).get();
      return Node(
          key: snapshot.key,
          value: snapshot.value
      );
    } catch (e) {
      throw RealtimeException("Không thể getData tại path: $path", e);
    }
  }

  //  Get List =================================================================
  /// Lấy danh sách dữ liệu tại [path]. Dùng khi dữ liệu `node` là một `list`
  ///
  ///
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
  static Future<List<Node>> getListNode(String path) async {
    try {
      final snapshot = await _safeDb.child(path).get();
      if (!snapshot.exists) return [];

      if (snapshot.value is! Map) {
        throw RealtimeException("Dữ liệu tại path $path không phải dạng Map");
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((e) => Node(
        key: e.key,
        value: e.value,
      )).toList();
    } catch (e) {
      throw RealtimeException("Không thể getList tại path: $path", e);
    }
  }

  // Stream - Listen ===========================================================
  /// Lắng nghe `node` thay đổi realtime tại [path].
  ///
  /// ```dart
  /// RealtimeService.listen("users").listen((node) {
  ///   print("Có thay đổi: node");
  /// });
  /// ```
  static Stream<Node> streamNode(String path) {
    try {
      return _safeDb.child(path).onValue.map((event) => Node(key: event.snapshot.key, value: event.snapshot.value));
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
  /// final subs = RealtimeService.streamNodeEvent(
  ///   "users",
  ///   onAdded: (node) {
  ///     print("Child mới: ${snapshot.value}");
  ///   },
  ///   onChanged: (node) {
  ///     print("Child thay đổi: ${snapshot.value}");
  ///   },
  ///   onRemoved: (node) {
  ///     print("Child bị xoá: ${snapshot.key}");
  ///   },
  /// );
  ///
  /// // Khi không cần lắng nghe nữa
  /// for (var sub in subs) {
  ///   sub.cancel();
  /// }
  /// ```
  static List<StreamSubscription> streamNodeEvent(
      String path, {
        void Function(Node node)? onAdded,
        void Function(Node node)? onChanged,
        void Function(Node node)? onRemoved,
      }) {
    final ref = _safeDb.child(path);
    final subs = <StreamSubscription>[];

    if (onAdded != null) {
      subs.add(ref.onChildAdded.listen((event) => onAdded(Node(key: event.snapshot.key, value: event.snapshot.value))));
    }
    if (onChanged != null) {
      subs.add(ref.onChildChanged.listen((event) => onChanged(Node(key: event.snapshot.key, value: event.snapshot.value))));
    }
    if (onRemoved != null) {
      subs.add(ref.onChildRemoved.listen((event) => onRemoved(Node(key: event.snapshot.key, value: event.snapshot.value))));
    }

    return subs;
  }
}
