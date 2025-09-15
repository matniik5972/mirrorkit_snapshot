import 'package:flutter/material.dart';

/// Widget d'image optimisé pour les items du garde-manger
/// Utilise cacheWidth et filterQuality pour de meilleures performances
class PantryOptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PantryOptimizedImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder ?? _buildPlaceholder();
    }

    return FadeInImage(
      image: NetworkImage(imageUrl!),
      placeholder: MemoryImage(
        // Placeholder transparent 1x1 pixel
        Uint8List.fromList([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
          0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
          0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
          0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
        ]),
      ),
      imageErrorBuilder: (context, error, stackTrace) => errorWidget ?? _buildErrorWidget(),
      fit: fit,
      width: width,
      height: height,
      // Optimisations de performance
      image: NetworkImage(
        imageUrl!,
        // Cache optimisé pour les vignettes
        headers: const {'Cache-Control': 'max-age=3600'},
      ),
      // Configuration optimisée pour les performances
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 32,
      ),
    );
  }
}

/// Extension pour optimiser les images existantes
extension ImageOptimization on Image {
  static Widget optimized({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Optimisations de performance
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      filterQuality: FilterQuality.medium,
      // Headers pour le cache
      headers: const {'Cache-Control': 'max-age=3600'},
      // Gestion d'erreur
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error_outline, color: Colors.grey),
      ),
    );
  }
}

