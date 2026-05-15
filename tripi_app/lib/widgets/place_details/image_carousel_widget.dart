import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'fullscreen_gallery_overlay.dart';

class ImageCarouselWidget extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback? onImageSwiped;
  final VoidCallback? onFullscreenOpened;

  const ImageCarouselWidget({
    super.key,
    required this.imageUrls,
    this.onImageSwiped,
    this.onFullscreenOpened,
  });

  @override
  State<ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<ImageCarouselWidget> {
  late final PageController _pageController;
  int _currentPage = 0;
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _pageController.page ?? 0.0;
    final rounded = page.round();
    if (rounded != _currentPage || (page - _pageOffset).abs() > 0.01) {
      setState(() {
        _pageOffset = page;
        if (rounded != _currentPage) {
          _currentPage = rounded;
          widget.onImageSwiped?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: urls.isEmpty
                ? _buildPlaceholder()
                : urls.length == 1
                    ? GestureDetector(
                        onTap: () => _openFullscreen(0),
                        child: Hero(
                          tag: 'place_image_0_${widget.key}',
                          child: _buildCachedImage(urls[0]),
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: urls.length,
                        itemBuilder: (context, index) {
                          final parallax = (index - _pageOffset) * 18.0;
                          return GestureDetector(
                            onTap: () => _openFullscreen(index),
                            child: Hero(
                              tag: 'place_image_${index}_${widget.key}',
                              child: Transform.translate(
                                offset: Offset(parallax, 0),
                                child: _buildCachedImage(urls[index]),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          _buildGradient(),
          if (urls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _buildDots(urls.length),
            ),
        ],
      ),
    );
  }

  Widget _buildCachedImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 400),
      placeholder: (_, __) => _buildShimmer(),
      errorWidget: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildShimmer() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 0.9),
      duration: const Duration(milliseconds: 900),
      builder: (_, value, __) => Container(
        color: Color.lerp(
            const Color(0xFFE2E8EF), const Color(0xFFF0F4F8), value),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDDE5EF), Color(0xFFF3F6FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFADB3B5)),
      ),
    );
  }

  Widget _buildGradient() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.2),
              ],
              stops: const [0.0, 0.25, 0.75, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots(int count) {
    return Semantics(
      label: 'Image ${_currentPage + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 14 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  void _openFullscreen(int index) {
    widget.onFullscreenOpened?.call();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: FullscreenGalleryOverlay(
            imageUrls: widget.imageUrls,
            initialIndex: index,
            heroTagPrefix: '${widget.key}',
          ),
        ),
      ),
    );
  }
}
