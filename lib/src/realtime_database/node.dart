class Node {
  final String key;
  final Object? value;

  Node({
    required this.key,
    required this.value
  });

  Map<String, dynamic> toMap() {
    if (value is Map) {
      return {
        "key": key,
        ...Map<String, dynamic>.from(value as Map),
      };
    }
    return {
      "key": key,
      "value": value,
    };
  }
}