import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../core/services/image_cache_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MM Market — ImageFullscreenViewer  v3.3.6
//
// Features:
//  • Pinch-to-zoom on every image (PhotoView)
//  • Swipe left/right to navigate between images (PhotoViewGallery)
//  • Double-tap to zoom in/out
//  • Animated dot indicator + counter badge
//  • Graceful error widget if image fails to load
//  • Uses MmMarketCacheManager for instant rendering from cache
//  • Status bar hidden in fullscreen; restored on close
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen image viewer with pinch-to-zoom and swipe navigation.
///
/// Open via [ImageFullscreenViewer.show]:
/// ```dart
/// ImageFullscreenViewer.show(
///   context,
///   images: product.imageUrls,
///   initialIndex: tappedIndex,
/// );
/// ```
class ImageFullscreenViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageFullscreenViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  /// Convenience method to push the viewer as a full-screen route.
  static Future<void> show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ImageFullscreenViewer(
          images: images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<ImageFullscreenViewer> createState() => _ImageFullscreenViewerState();
}

class _ImageFullscreenViewerState extends State<ImageFullscreenViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Hide status bar for immersive fullscreen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI on close
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Photo gallery with pinch-to-zoom ─────────────────────────────
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            builder: (context, index) {
              final url = widget.images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(
                  url,
                  cacheManager: ImageCacheService.cacheManager,
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes: PhotoViewHeroAttributes(tag: 'product_image_$index'),
                errorBuilder: (_, __, ___) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          size: 64, color: Colors.white54),
                      SizedBox(height: 12),
                      Text('Image failed to load',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              );
            },
            loadingBuilder: (_, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? null
                    : event.cumulativeBytesLoaded /
                        (event.expectedTotalBytes ?? 1),
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),

          // ── Close button ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                shape: const CircleBorder(),
              ),
            ),
          ),

          // ── Image counter badge ───────────────────────────────────────────
          if (widget.images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

          // ── Dot indicator ─────────────────────────────────────────────────
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentIndex ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
