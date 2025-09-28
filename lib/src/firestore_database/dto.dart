class FirestoreCollection {
  /// Tên của bộ sưu tập (ví dụ: "users")
  final String name;
  /// Danh sách các tài liệu trong bộ sưu tập
  final List<FirestoreDocument> documents;

  FirestoreCollection({
    required this.name,
    required this.documents,
  });
}

class FirestoreDocument {
  /// ID của tài liệu (ví dụ: "user_123")
  final String id;
  /// Dữ liệu/Trường bên trong tài liệu
  final Object? data;
  /// Bộ sưu tập con bên trong tài liệu (nếu có)
  final List<FirestoreCollection>? subcollections;

  FirestoreDocument({
    required this.id,
    required this.data,
    this.subcollections,
  });
}