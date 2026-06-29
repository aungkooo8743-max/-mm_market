import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/sources/auth_data_source.dart';
import '../../features/auth/data/sources/firebase_auth_data_source.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/chat/data/repositories/chat_media_repository_impl.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_media_repository.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/favorite/data/repositories/favorite_repository_impl.dart';
import '../../features/favorite/domain/repositories/favorite_repository.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/product/data/repositories/product_image_repository_impl.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_image_repository.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/profile/data/repositories/user_profile_repository_impl.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../features/report/data/repositories/report_repository_impl.dart';
import '../../features/report/domain/repositories/report_repository.dart';
import '../../features/review/data/repositories/review_repository_impl.dart';
import '../../features/review/domain/repositories/review_repository.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../services/connectivity_service.dart';
import '../services/firebase/fcm_token_sync_service.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/firestore_service.dart';
import '../services/firebase/messaging_service.dart';
import '../services/firebase/storage_service.dart';
import '../services/logger_service.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<FirebaseAuth>()) return;

  // Firebase instances
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  // Offline persistence: cache up to unlimited Firestore data on-device so
  // users can browse previously loaded products when Myanmar internet drops.
  sl.registerLazySingleton<FirebaseFirestore>(() {
    final fs = FirebaseFirestore.instance;
    fs.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return fs;
  });
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
  sl.registerLazySingleton<Connectivity>(Connectivity.new);

  // Core services
  sl.registerLazySingleton<LoggerService>(() => const LoggerService());
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService(sl<FirebaseFirestore>()));
  sl.registerLazySingleton<StorageService>(() => StorageService(sl<FirebaseStorage>()));
  sl.registerLazySingleton<MessagingService>(() => MessagingService(sl<FirebaseMessaging>()));
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService(sl<FirebaseAuth>(), sl<GoogleSignIn>()));
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService(sl<Connectivity>()));
  sl.registerLazySingleton<FcmTokenSyncService>(() => FcmTokenSyncService(
    messagingService: sl<MessagingService>(),
    firestoreService: sl<FirestoreService>(),
  ));

  // Auth data source
  sl.registerLazySingleton<AuthDataSource>(
    () => FirebaseAuthDataSource(auth: sl<FirebaseAuth>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    authService: sl<FirebaseAuthService>(),
    firestoreService: sl<FirestoreService>(),
    fcmTokenSyncService: sl<FcmTokenSyncService>(),
  ));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl<FirestoreService>()));
  sl.registerLazySingleton<ProductImageRepository>(() => ProductImageRepositoryImpl(sl<StorageService>()));
  sl.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl(sl<FirestoreService>()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(
    firestoreService: sl<FirestoreService>(),
    storageService: sl<StorageService>(),
  ));
  sl.registerLazySingleton<ChatMediaRepository>(() => ChatMediaRepositoryImpl(sl<StorageService>()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(sl<FirestoreService>()));
  sl.registerLazySingleton<UserProfileRepository>(() => UserProfileRepositoryImpl(
    firestoreService: sl<FirestoreService>(),
    storageService: sl<StorageService>(),
  ));
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl<FirestoreService>()));
  sl.registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(sl<FirestoreService>()));
  sl.registerLazySingleton<ReportRepository>(() => ReportRepositoryImpl(
    firestoreService: sl<FirestoreService>(),
    storageService: sl<StorageService>(),
  ));
}
