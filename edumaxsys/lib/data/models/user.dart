/// User Model
/// 
/// Represents a User entity with fields that match the Laravel backend.
/// Includes additional fields for offline-first sync functionality.
class User {
  final int? id;
  final String name;
  final String email;
  final String? password;
  final String? profilePhotoPath;
  final String? profilePhotoUrl;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Offline-first sync fields
  final int syncStatus;
  final String? localId;
  final DateTime? lastSyncedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.password,
    this.profilePhotoPath,
    this.profilePhotoUrl,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 1, // 0 = pending, 1 = synced, 2 = failed
    this.localId,
    this.lastSyncedAt,
  });

  /// Create User from JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String?,
      profilePhotoPath: json['profile_photo_path'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.tryParse(json['email_verified_at'] as String)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      syncStatus: json['sync_status'] as int? ?? 1,
      localId: json['local_id'] as String?,
      lastSyncedAt: json['last_synced_at'] != null 
          ? DateTime.tryParse(json['last_synced_at'] as String)
          : null,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profile_photo_path': profilePhotoPath,
      'profile_photo_url': profilePhotoUrl,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'local_id': localId,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Convert User to JSON for API (excluding local sync fields)
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'email': email,
      if (password != null) 'password': password,
    };
  }

  /// Create User from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String?,
      profilePhotoPath: map['profile_photo_path'] as String?,
      profilePhotoUrl: map['profile_photo_url'] as String?,
      emailVerifiedAt: map['email_verified_at'] != null 
          ? DateTime.tryParse(map['email_verified_at'] as String)
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      syncStatus: map['sync_status'] as int? ?? 1,
      localId: map['local_id'] as String?,
      lastSyncedAt: map['last_synced_at'] != null 
          ? DateTime.tryParse(map['last_synced_at'] as String)
          : null,
    );
  }

  /// Convert User to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profile_photo_path': profilePhotoPath,
      'profile_photo_url': profilePhotoUrl,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'local_id': localId,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? profilePhotoPath,
    String? profilePhotoUrl,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    String? localId,
    DateTime? lastSyncedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localId: localId ?? this.localId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.localId == localId;
  }

  @override
  int get hashCode => id.hashCode ^ localId.hashCode;
}
