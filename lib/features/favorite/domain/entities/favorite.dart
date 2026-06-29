import 'package:equatable/equatable.dart';
import '../../../../core/utils/date_parser.dart';
import '../../../../core/utils/map_utils.dart';
class Favorite extends Equatable { final String id,userId,productId; final DateTime createdAt; const Favorite({required this.id,required this.userId,required this.productId,required this.createdAt}); factory Favorite.fromMap(String id, Map<String,dynamic> map)=>Favorite(id:id,userId:MapUtils.stringValue(map,'userId'),productId:MapUtils.stringValue(map,'productId'),createdAt:DateParser.fromValue(map['createdAt'])??DateTime.now()); Map<String,dynamic> toMap()=>{'userId':userId,'productId':productId,'createdAt':createdAt.toIso8601String()}; @override List<Object?> get props=>[id,userId,productId,createdAt]; }
