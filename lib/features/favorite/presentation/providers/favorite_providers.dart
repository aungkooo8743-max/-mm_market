import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/repositories/favorite_repository.dart';
final favoriteRepositoryProvider=Provider<FavoriteRepository>((ref)=>sl<FavoriteRepository>());
final myFavoritesProvider=StreamProvider<List<Favorite>>((ref){final user=ref.watch(currentUserProvider); if(user==null)return const Stream.empty(); return ref.watch(favoriteRepositoryProvider).watchMyFavorites(user.uid);});
final isFavoriteProvider=FutureProvider.family<bool,String>((ref,productId){final user=ref.watch(currentUserProvider); if(user==null)return false; return ref.watch(favoriteRepositoryProvider).isFavorite(userId:user.uid,productId:productId);});
final favoriteControllerProvider=StateNotifierProvider<FavoriteController, FavoriteControllerState>((ref)=>FavoriteController(ref));
class FavoriteController extends StateNotifier<FavoriteControllerState>{ final Ref ref; FavoriteController(this.ref):super(const FavoriteControllerState()); Future<void> toggle(String productId) async{final user=ref.read(currentUserProvider); if(user==null){state=state.copyWith(errorMessage:'Login required');return;} state=state.copyWith(isLoading:true,errorMessage:null); try{await ref.read(favoriteRepositoryProvider).toggleFavorite(userId:user.uid,productId:productId); ref.invalidate(isFavoriteProvider(productId)); ref.invalidate(myFavoritesProvider); state=state.copyWith(isLoading:false,success:true);}catch(e){state=state.copyWith(isLoading:false,errorMessage:e.toString());}}}
class FavoriteControllerState{final bool isLoading,success; final String? errorMessage; const FavoriteControllerState({this.isLoading=false,this.success=false,this.errorMessage}); FavoriteControllerState copyWith({bool? isLoading,bool? success,String? errorMessage})=>FavoriteControllerState(isLoading:isLoading??this.isLoading,success:success??this.success,errorMessage:errorMessage);}
