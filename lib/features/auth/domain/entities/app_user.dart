import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_parser.dart';
import '../../../../core/utils/enum_parser.dart';
import '../../../../core/utils/map_utils.dart';

enum UserRole { user, moderator, admin }
enum UserStatus { active, suspended, banned, deleted }

class AppUser extends Equatable {
  final String uid;
  final String phone;
  final String? displayName;
  final String? photoUrl;
  final String? city;
  final String? township;
  final UserRole role;
  final UserStatus status;
  final int trustScore;
  final double ratingAverage;
  final int reviewCount;
  final bool notificationEnabled;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeen;

  const AppUser({required this.uid, required this.phone, this.displayName, this.photoUrl, this.city, this.township, this.role = UserRole.user, this.status = UserStatus.active, this.trustScore = 0, this.ratingAverage = 0, this.reviewCount = 0, this.notificationEnabled = true, this.isOnline = false, required this.createdAt, required this.updatedAt, this.lastSeen});

  bool get isAdmin => role == UserRole.admin;
  bool get canUseApp => status == UserStatus.active;

  AppUser copyWith({String? displayName, String? photoUrl, String? city, String? township, bool? notificationEnabled, bool? isOnline, DateTime? updatedAt, DateTime? lastSeen}) => AppUser(uid: uid, phone: phone, displayName: displayName ?? this.displayName, photoUrl: photoUrl ?? this.photoUrl, city: city ?? this.city, township: township ?? this.township, role: role, status: status, trustScore: trustScore, ratingAverage: ratingAverage, reviewCount: reviewCount, notificationEnabled: notificationEnabled ?? this.notificationEnabled, isOnline: isOnline ?? this.isOnline, createdAt: createdAt, updatedAt: updatedAt ?? this.updatedAt, lastSeen: lastSeen ?? this.lastSeen);

  Map<String, dynamic> toMap() => {'uid': uid, 'phone': phone, 'displayName': displayName, 'photoUrl': photoUrl, 'city': city, 'township': township, 'role': role.name, 'status': status.name, 'trustScore': trustScore, 'ratingAverage': ratingAverage, 'reviewCount': reviewCount, 'notificationEnabled': notificationEnabled, 'isOnline': isOnline, 'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(), 'lastSeen': lastSeen?.toIso8601String()};

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(uid: MapUtils.stringValue(map, 'uid'), phone: MapUtils.stringValue(map, 'phone'), displayName: map['displayName'] as String?, photoUrl: map['photoUrl'] as String?, city: map['city'] as String?, township: map['township'] as String?, role: EnumParser.fromName(values: UserRole.values, name: map['role'] as String?, fallback: UserRole.user), status: EnumParser.fromName(values: UserStatus.values, name: map['status'] as String?, fallback: UserStatus.active), trustScore: MapUtils.intValue(map, 'trustScore'), ratingAverage: MapUtils.doubleValue(map, 'ratingAverage'), reviewCount: MapUtils.intValue(map, 'reviewCount'), notificationEnabled: MapUtils.boolValue(map, 'notificationEnabled', fallback: true), isOnline: MapUtils.boolValue(map, 'isOnline'), createdAt: DateParser.fromValue(map['createdAt']) ?? DateTime.now(), updatedAt: DateParser.fromValue(map['updatedAt']) ?? DateTime.now(), lastSeen: DateParser.fromValue(map['lastSeen']));

  @override
  List<Object?> get props => [uid, phone, displayName, photoUrl, city, township, role, status, trustScore, ratingAverage, reviewCount, notificationEnabled, isOnline, createdAt, updatedAt, lastSeen];
}
