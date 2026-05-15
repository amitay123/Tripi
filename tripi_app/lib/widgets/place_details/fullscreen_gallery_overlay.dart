import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullscreenGalleryOverlay extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;

  const FullscreenGalleryOverlay({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix = '',
  });

  @override
  State<FullscreenGalleryOverlay> createState() =>
      _FullscreenGalleryOverlayState();
}

class _FullscreenGalleryOverlayState extends State<FullscreenGalleryOverlay>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _bgController;
  int _currentIndex = 0;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _bgController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgOpacity =
        ((1.0 - (_dragOffset.abs() / 300.0)) * _bgController.value)
            .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      body: GestureDetector(
        onVerticalDragUpdate: (d) {
          setState(() => _dragOffset += d.delta.dy);
        },
        onVerticalDragEnd: (d) {
          if (_dragOffset.abs() > 100 ||
              d.velocity.pixelsPerSecond.dy.abs() > 500) {
            Navigator.pop(context);
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.imageUrls.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  return Hero(
                    tag:
                        'place_image_${index}_${widget.heroTagPrefix}',
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrls[index],
                          fit: BoxFit.contain,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white38,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Close
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: Semantics(
                  button: true,
                  label: 'Close fullscreen',
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
              // Counter
              if (widget.imageUrls.length > 1)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  left: 0,
                  right: 0,
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              // Swipe hint
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: const Text(
                  'Swipe down to close',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
