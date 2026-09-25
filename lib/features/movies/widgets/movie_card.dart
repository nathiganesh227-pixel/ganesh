import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/plaza_global_state.dart';
import '../../../core/models/movie.dart';
import '../../../core/widgets/glass_pill.dart';
import '../../../core/widgets/plaza_image.dart';
import '../movie_details_screen.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool compact;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width,
    this.height,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.isFavorite(movie.id);

        return GestureDetector(
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailsScreen(movie: movie),
                  ),
                );
              },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poster Stack
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PlazaImage(
                          imageUrl: movie.posterUrl,
                          fit: BoxFit.cover,
                        ),

                        // Atmospheric Glass Vignette
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.glassBorderSubtle,
                              width: 1.0,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x30070A11),
                                Colors.transparent,
                                Color(0xA0070A11),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),

                        // Top Badges: Rating & Favorite Heart
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Rating badge
                              if (movie.rating > 0)
                                GlassPill(
                                  label: '${movie.rating.toStringAsFixed(1)} ★',
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  backgroundColor: const Color(0xB0070A11),
                                  textColor: AppColors.accentGold,
                                )
                              else
                                const SizedBox.shrink(),

                              // Favorite button
                              GestureDetector(
                                onTap: () {
                                  PlazaGlobalState.instance.toggleFavorite(movie.id);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0x60000000),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isFav
                                              ? AppColors.primary
                                              : const Color(0x40FFFFFF),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 16,
                                        color: isFav ? AppColors.primary : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Tag: Format / Certificate / Coming Soon
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (movie.formats.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x90000000),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0x30FFFFFF), width: 0.8),
                                  ),
                                  child: Text(
                                    movie.formats.first.label,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 9.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),

                              if (movie.isComingSoon && !movie.isNowShowing)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.sunsetPrimary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Soon',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 9.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x60000000),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    movie.certificate,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 9.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  movie.title,
                  style: AppTypography.headingSmall.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Language & Genre
                Text(
                  '${movie.primaryLanguage.label}${movie.genres.isNotEmpty ? ' • ${movie.genres.first}' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Starting Price / Release Date
                if (movie.isNowShowing && movie.startingPrice > 0)
                  Text(
                    '₹${movie.startingPrice.toInt()} onwards',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentAmber,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else if (movie.isComingSoon)
                  Text(
                    'Releases ${_formatDate(movie.releaseDate)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
