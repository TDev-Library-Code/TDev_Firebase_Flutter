import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeService {
  static DatabaseReference? _db;

  /// Khởi tạo Firebase và Realtime Database
  static Future<void> init({FirebaseOptions? options}) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }

    _db = FirebaseDatabase.instance.ref();
  }

  /// Ghi đè dữ liệu tại path
  static Future<void> setData(String path, Map<String, dynamic> data) async {
    await _db!.child(path).set(data);
  }

  /// Thêm mới với id tự sinh
  static Future<String> pushData(String path, Map<String, dynamic> data) async {
    final newRef = _db!.child(path).push();
    await newRef.set(data);
    return newRef.key!;
  }

  /// Cập nhật 1 phần dữ liệu tại path
  static Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _db!.child(path).update(data);
  }

  /// Xoá node
  static Future<void> deleteData(String path) async {
    await _db!.child(path).remove();
  }

  /// Lấy dữ liệu một lần
  static Future<dynamic> getData(String path) async {
    final snapshot = await _db!.child(path).get();
    return snapshot.exists ? snapshot.value : null;
  }

  /// Lấy danh sách dữ liệu
  static Future<List<Map<String, dynamic>>> getList(String path) async {
    final snapshot = await _db!.child(path).get();
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    return data.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Lắng nghe thay đổi realtime
  static Stream<dynamic> listen(String path) {
    return _db!.child(path).onValue.map((event) => event.snapshot.value);
  }
}
