/// Pending Sync Model
/// 
/// This model tracks changes that need to be synced with the server.
/// Similar to PowerSync's concept of tracking pending operations.
class PendingSync {
  final int? id;
  final String tableName;
  final String operation; // CREATE, UPDATE, DELETE
  final String recordId;
  final String? data; // JSON string of the record data
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  PendingSync({
    this.id,
    required this.tableName,
    required this.operation,
    required this.recordId,
    this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  /// Create from JSON
  factory PendingSync.fromJson(Map<String, dynamic> json) {
    return PendingSync(
      id: json['id'] as int?,
      tableName: json['table_name'] as String,
      operation: json['operation'] as String,
      recordId: json['record_id'] as String,
      data: json['data'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'operation': operation,
      'record_id': recordId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  /// Create from database map
  factory PendingSync.fromMap(Map<String, dynamic> map) {
    return PendingSync(
      id: map['id'] as int?,
      tableName: map['table_name'] as String,
      operation: map['operation'] as String,
      recordId: map['record_id'] as String,
      data: map['data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'operation': operation,
      'record_id': recordId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  /// Create a copy with updated fields
  PendingSync copyWith({
    int? id,
    String? tableName,
    String? operation,
    String? recordId,
    String? data,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
  }) {
    return PendingSync(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      operation: operation ?? this.operation,
      recordId: recordId ?? this.recordId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  String toString() {
    return 'PendingSync(id: $id, table: $tableName, operation: $operation, recordId: $recordId)';
  }
}
