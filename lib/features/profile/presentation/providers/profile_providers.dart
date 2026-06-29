import 'package:flutter_riverpod/flutter_riverpod.dart'; import '../../../../core/di/injection.dart'; import '../../../auth/presentation/providers/auth_providers.dart'; import '../../domain/entities/user_profile.dart'; import '../../domain/repositories/user_profile_repository.dart'; import 'profile_controller.dart'; import 'profile_controller_state.dart';
final userProfileRepositoryProvider=Provider<UserProfileRepository>((ref)=>sl<UserProfileRepository>());
final currentUserProfileProvider=StreamProvider<UserProfile?>((ref){final user=ref.watch(currentUserProvider); if(user==null)return const Stream.empty(); return ref.watch(userProfileRepositoryProvider).watchProfile(user.uid);});
final userProfileProvider=FutureProvider.family<UserProfile?,String>((ref,id)=>ref.watch(userProfileRepositoryProvider).getProfile(id));
final profileControllerProvider=StateNotifierProvider<ProfileController,ProfileControllerState>((ref)=>ProfileController(ref));
