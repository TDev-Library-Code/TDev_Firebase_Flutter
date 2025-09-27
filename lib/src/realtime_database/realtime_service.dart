import 'package:firebase_database/firebase_database.dart';

class RealtimeService {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Ghi đè dữ liệu tại path
  static Future<void> setData(String path, Map<String, dynamic> data) async {
    await _db.child(path).set(data);
  }

  /// Lấy dữ liệu tại path
  static Future<DataSnapshot> getData(String path) async {
    return await _db.child(path).get();
  }

  /// Update 1 phần dữ liệu tại path
  static Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _db.child(path).update(data);
  }

  /// Xoá dữ liệu tại path
  static Future<void> deleteData(String path) async {
    await _db.child(path).remove();
  }

  /// Lắng nghe thay đổi real-time
  static Stream<DatabaseEvent> listen(String path) {
    return _db.child(path).onValue;
  }
}
