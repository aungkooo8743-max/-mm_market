import 'package:equatable/equatable.dart';
import '../entities/app_user.dart';
import '../../../../core/utils/date_parser.dart';
import '../../../../core/utils/map_utils.dart';

/// A serialisable data-transfer model for a user record.
///
/// [UserModel] lives in the **domain/models** layer and is used to carry
/// user data across the repository boundary (e.g. Firestore ↔ domain).
/// It intentionally mirrors the fields required by [AppUser] so that
/// conversion between the two is lossless.
///
/// Fields that are specific to [AppUser]'s rich domain logic (roles,
/// trust score, etc.) are preserved with safe defaults so that a
/// [UserModel] can always be promoted to a full [AppUser].
class UserModel extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  // Extended fields — kept in sync with AppUser for lossless conversion.
  final String? photoUrl;
  final String? phone;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.photoUrl,
    this.phone,
    this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // JSON / Map serialisation
  // ---------------------------------------------------------------------------

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: MapUtils.stringValue(json, 'id'),
        email: MapUtils.stringValue(json, 'email'),
        displayName: MapUtils.stringValue(json, 'displayName'),
        createdAt:
            DateParser.fromValue(json['createdAt']) ?? DateTime.now(),
        photoUrl: json['photoUrl'] as String?,
        phone: json['phone'] as String?,
        updatedAt: DateParser.fromValue(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (phone != null) 'phone': phone,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  // ---------------------------------------------------------------------------
  // Domain conversion helpers
  // ---------------------------------------------------------------------------

  /// Promotes this [UserModel] to a full [AppUser] domain entity.
  AppUser toAppUser() {
    final now = updatedAt ?? createdAt;
    return AppUser(
      uid: id,
      phone: phone ?? '',
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Demotes an [AppUser] domain entity to a lightweight [UserModel].
  factory UserModel.fromAppUser(AppUser user) => UserModel(
        id: user.uid,
        email: '',          // AppUser is phone-based; email field left empty.
        displayName: user.displayName ?? '',
        createdAt: user.createdAt,
        photoUrl: user.photoUrl,
        phone: user.phone,
        updatedAt: user.updatedAt,
      );

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    String? photoUrl,
    String? phone,
    DateTime? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt ?? this.createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
        phone: phone ?? this.phone,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, email, displayName, createdAt, photoUrl, phone, updatedAt];
}
