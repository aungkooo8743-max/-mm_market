import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'crashlytics_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MM Market — Advanced Image Cache Service  v3.3.6
//
// Responsibilities:
//  1. Custom CacheManager with 30-day TTL and 500-file cap.
//  2. Proactive precaching: call [precacheProductImages] after a product list
//     loads so images are warm in cache before the user scrolls to them.
//  3. Graceful error handling: cache misses are logged to Crashlytics as
//     non-fatal events (not shown to the user).
//  4. Cache management helpers: clear on logout, warm on app start.
// ─────────────────────────────────────────────────────────────────────────────

/// Custom [CacheManager] tuned for MM Market product images.
///
/// - Max age: 30 days (product images rarely change after upload).
/// - Max objects: 500 files (~500 × avg 200 KB ≈ 100 MB on-device).
class MmMarketCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'mm_market_image_cache';

  static final MmMarketCacheManager _instance = MmMarketCacheManager._();
  factory MmMarketCacheManager() => _instance;

  MmMarketCacheManager._()
      : super(
          Config(
            _key,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 500,
            repo: JsonCacheInfoRepository(databaseName: _key),
            fileService: HttpFileService(),
          ),
        );
}

/// Singleton service that wraps proactive image caching for MM Market.
class ImageCacheService {
  const ImageCacheService._();

  /// The shared [MmMarketCacheManager] instance.
  static MmMarketCacheManager get cacheManager => MmMarketCacheManager();

  // ── Proactive precaching ──────────────────────────────────────────────────

  /// Precaches a list of image URLs in the background.
  ///
  /// Call this immediately after a product list is fetched so images are
  /// warm in the local disk cache before the user scrolls to them.
  /// Errors are silently logged to Crashlytics — never thrown to the caller.
  static Future<void> precacheProductImages(
    BuildContext context,
    List<String?> imageUrls, {
    int maxConcurrent = 4,
  }) async {
    final valid = imageUrls
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();

    if (valid.isEmpty) return;

    // Batch into groups of [maxConcurrent] to avoid saturating the network.
    for (var i = 0; i < valid.length; i += maxConcurrent) {
      final batch = valid.skip(i).take(maxConcurrent).toList();
      await Future.wait(
        batch.map((url) => _precacheSingle(context, url)),
        eagerError: false,
      );
    }
  }

  static Future<void> _precacheSingle(BuildContext context, String url) async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(url, cacheManager: cacheManager),
        context,
      );
    } catch (e, st) {
      // Non-fatal: image precache failure should never crash the app.
      unawaited(CrashlyticsService.recordError(
        e, st,
        reason: 'imagePrecacheFailed',
        context: {'url': url.length > 80 ? url.substring(0, 80) : url},
      ));
      debugPrint('[ImageCacheService] precache failed for $url: $e');
    }
  }

  // ── Cache management ──────────────────────────────────────────────────────

  /// Warms the cache for a single URL (fire-and-forget).
  static void warmSingle(String? url) {
    if (url == null || url.isEmpty) return;
    unawaited(
      cacheManager.downloadFile(url).catchError((Object e) {
        debugPrint('[ImageCacheService] warmSingle failed: $e');
        return Future<FileInfo>.error(e);
      }),
    );
  }

  /// Clears the entire image cache.
  /// Call on sign-out to free disk space and protect user privacy.
  static Future<void> clearCache() async {
    try {
      await cacheManager.emptyCache();
      CrashlyticsService.log('ImageCacheService: cache cleared');
    } catch (e, st) {
      unawaited(CrashlyticsService.recordError(
        e, st,
        reason: 'imageCacheClearFailed',
      ));
    }
  }

  // ── Widget builder ────────────────────────────────────────────────────────

  /// Returns a [CachedNetworkImage] configured with the custom cache manager,
  /// a shimmer placeholder, and a graceful error icon.
  static Widget buildProductImage({
    required String? imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFFBDBDBD)),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: cacheManager,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, url, error) {
        final err = error;
        unawaited(CrashlyticsService.recordError(
          err,
          null,
          reason: 'cachedImageLoadFailed',
          context: {'url': url.length > 80 ? url.substring(0, 80) : url},
        ));
        return const Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFFBDBDBD)),
        );
      },
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}
