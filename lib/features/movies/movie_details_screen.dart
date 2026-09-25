import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/movie.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'showtime_selection_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  bool _isSynopsisExpanded = false;

  void _showTrailerDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Official Trailer', style: AppTypography.headingMedium),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PlazaImage(
                      imageUrl: widget.movie.backdropUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 200,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: AppGradients.sunsetPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.movie.title} • Official Theatrical Trailer (4K Ultra HD)',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GlassButton(
                text: 'Close Preview',
                variant: GlassButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Backdrop & Poster Area
                Stack(
                  children: [
                    // Backdrop with blur/gradient fade
                    SizedBox(
                      height: 440,
                      width: double.infinity,
                      child: PlazaImage(
                        imageUrl: movie.backdropUrl,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Gradient overlays for seamless liquid transition
                    Container(
                      height: 440,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x70070A11),
                            Color(0x30070A11),
                            Color(0xE0070A11),
                            AppColors.background,
                          ],
                          stops: [0.0, 0.4, 0.8, 1.0],
                        ),
                      ),
                    ),

                    // Top Bar (Back button, Share)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassFillMedium,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.glassBorderSubtle,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListenableBuilder(
                                  listenable: PlazaGlobalState.instance,
                                  builder: (context, _) {
                                    final isFav = PlazaGlobalState.instance.isFavorite(movie.id);
                                    return GestureDetector(
                                      onTap: () {
                                        PlazaGlobalState.instance.toggleFavorite(movie.id);
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isFav
                                                  ? 'Removed ${movie.title} from favorites'
                                                  : 'Added ${movie.title} to favorites',
                                            ),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.glassFillMedium,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isFav
                                                    ? AppColors.alertRed.withValues(alpha: 0.5)
                                                    : AppColors.glassBorderSubtle,
                                              ),
                                            ),
                                            child: Icon(
                                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              size: 18,
                                              color: isFav ? AppColors.alertRed : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sharing link for ${movie.title}...'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.glassFillMedium,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.glassBorderSubtle,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.share_outlined,
                                          size: 18,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Play Trailer Center Floating Button
                    if (movie.trailerYoutubeId.isNotEmpty)
                      Positioned(
                        top: 190,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _showTrailerDialog,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0x60000000),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0x60FFFFFF),
                                      width: 1.0,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x40000000),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          gradient: AppGradients.sunsetPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Watch Trailer',
                                        style: AppTypography.labelMedium.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Movie Info Card Overlap
                    Positioned(
                      bottom: 0,
                      left: 20,
                      right: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Floating Poster thumbnail
                          Container(
                            width: 110,
                            height: 155,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.glassBorder, width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x80000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: PlazaImage(
                                imageUrl: movie.posterUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Title, Rating, Certificate
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  movie.title,
                                  style: AppTypography.headingLarge.copyWith(fontSize: 22),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0x30FFB300),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0x60FFB300),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${movie.rating.toStringAsFixed(1)}/5',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: AppColors.accentGold,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${movie.votesCount ~/ 1000}k votes)',
                                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${movie.certificate} • ${movie.duration} • ${movie.primaryLanguage.label}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Genres & Formats Horizontal Badges
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...movie.genres.map(
                            (g) => GlassPill(
                              label: g,
                              backgroundColor: AppColors.glassFillMedium,
                            ),
                          ),
                          ...movie.formats.map(
                            (f) => GlassPill(
                              label: f.label,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                              borderColor: AppColors.primary.withValues(alpha: 0.4),
                              textColor: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Synopsis Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Synopsis', style: AppTypography.headingSmall),
                        const SizedBox(height: 8),
                        Text(
                          movie.synopsis,
                          style: AppTypography.bodyMedium.copyWith(
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: _isSynopsisExpanded ? null : 3,
                          overflow: _isSynopsisExpanded ? null : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSynopsisExpanded = !_isSynopsisExpanded;
                            });
                          },
                          child: Text(
                            _isSynopsisExpanded ? 'Read less' : 'Read more',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Cast & Crew Carousel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Top Cast & Crew', style: AppTypography.headingSmall),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: movie.cast.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Director card
                        return Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 14),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.glassFillMedium,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.glassBorderSubtle),
                                ),
                                child: const Icon(
                                  Icons.movie_filter_outlined,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                movie.director,
                                style: AppTypography.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Director',
                                style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final cast = movie.cast[index - 1];
                      return Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 14),
                        child: Column(
                          children: [
                            PlazaImage(
                              imageUrl: cast.imageUrl,
                              width: 64,
                              height: 64,
                              borderRadius: 32,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cast.name,
                              style: AppTypography.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              cast.role,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 120), // Bottom bar padding
              ],
            ),
          ),

          // Floating Glass Bottom CTA Dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: MediaQuery.of(context).padding.bottom > 0
                        ? MediaQuery.of(context).padding.bottom + 8
                        : 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE0090D18),
                    border: const Border(
                      top: BorderSide(color: AppColors.glassBorder, width: 1.0),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      final isComingSoonOnly = movie.isComingSoon && !movie.isNowShowing;
                      if (isComingSoonOnly) {
                        return Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('STATUS', style: AppTypography.labelSmall),
                                const SizedBox(height: 2),
                                Text(
                                  'Releasing Soon',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: GlassButton(
                                text: 'Advance Booking Soon',
                                icon: Icons.notifications_active_outlined,
                                variant: GlassButtonVariant.secondary,
                                height: 52,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Advance bookings for ${movie.title} will open soon! We\'ll notify you.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      final startingPrice = movie.startingPrice > 0 ? movie.startingPrice.toInt() : 150;
                      return Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('TICKETS FROM', style: AppTypography.labelSmall),
                              const SizedBox(height: 2),
                              Text(
                                '₹$startingPrice',
                                style: AppTypography.priceTag.copyWith(
                                  fontSize: 22,
                                  color: AppColors.accentAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: GlassButton(
                              text: 'Book Tickets',
                              icon: Icons.confirmation_number_rounded,
                              variant: GlassButtonVariant.primary,
                              height: 52,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShowtimeSelectionScreen(movie: movie),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
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
