import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/food_suggestion.dart';
import '../services/dish_image_service.dart';
import '../theme/app_theme.dart';
import 'pressable_scale.dart';

/// The dish card, shared by the results screen, the chat, and favorites.
///
/// Full-bleed by design: the photograph runs edge to edge and the dish
/// name sits on it over a scrim, rather than the photo being a banner
/// stuck above a separate white box. Less frame, more food — the content
/// is the thing worth looking at, and every border, shadow and gutter
/// between the viewer and it is chrome to be justified.
class SuggestionCard extends StatefulWidget {
  final FoodSuggestion suggestion;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard> {
  DishPhoto? _photo;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final photo = await DishImageService.instance.photoFor(
      canonicalName: widget.suggestion.canonicalName,
      displayName: widget.suggestion.name,
      cuisineType: widget.suggestion.cuisineType,
    );
    if (!mounted || photo == null) return;
    setState(() => _photo = photo);
  }

  void _copy() {
    final s = widget.suggestion;
    final text = StringBuffer(s.name);
    if (s.description.isNotEmpty) text.write('\n${s.description}');
    Clipboard.setData(ClipboardData(text: text.toString()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(S.copiedToClipboard(s.name)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  void _toggleFavorite() {
    HapticFeedback.mediumImpact();
    widget.onToggleFavorite?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = widget.suggestion;
    final visual =
        CuisineVisual.forDish(suggestion.name, suggestion.cuisineType);
    final hasPhoto = _photo != null;

    return PressableScale(
      pressScale: 1.0,
      hoverScale: 1.012,
      haptic: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.07),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 218,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: visual.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  if (!hasPhoto) _Motif(visual: visual, dish: suggestion.name),
                  if (hasPhoto) _FadeInPhoto(url: _photo!.url),
                  // Two-stop scrim: light at the top so the pill and
                  // controls read, heavy at the bottom so the title stays
                  // legible over an unpredictable photograph.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.black.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.68),
                        ],
                        stops: const [0.0, 0.38, 1.0],
                      ),
                    ),
                  ),
                  if (suggestion.cuisineType.isNotEmpty)
                    Positioned(
                      left: 16,
                      top: 14,
                      child: _Pill(text: suggestion.cuisineType),
                    ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Row(
                      children: [
                        _GlassButton(
                          icon: Icons.copy_outlined,
                          tooltip: S.copyDish,
                          onTap: _copy,
                        ),
                        if (widget.onToggleFavorite != null) ...[
                          const SizedBox(width: 8),
                          _GlassButton(
                            icon: widget.isFavorite
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            tooltip: widget.isFavorite
                                ? S.savedTooltip
                                : S.saveThisDish,
                            onTap: _toggleFavorite,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        if (hasPhoto) ...[
                          const SizedBox(height: 4),
                          Text(
                            _photo!.credit,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (suggestion.nutritionTags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestion.nutritionTags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sage.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.isDark
                                        ? const Color(0xFFA8BE93)
                                        : const Color(0xFF4E5F41),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  if (suggestion.goalFit.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _IconLine(
                      icon: Icons.flag_outlined,
                      color: AppColors.sage,
                      text: suggestion.goalFit,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.charcoal.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                  if (suggestion.whyItFits.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _IconLine(
                      icon: Icons.auto_awesome,
                      color: AppColors.terracotta,
                      text: suggestion.whyItFits,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.isDark
                            ? AppColors.gold
                            : AppColors.terracottaDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scattered low-opacity glyphs, so a card with no photograph reads as a
/// designed surface rather than a flat block of colour.
class _Motif extends StatelessWidget {
  final CuisineVisual visual;
  final String dish;
  const _Motif({required this.visual, required this.dish});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final m in CuisineVisual.motifFor(dish))
              Positioned(
                left: m.left * constraints.maxWidth,
                top: m.top * constraints.maxHeight,
                child: Opacity(
                  opacity: m.opacity,
                  child: Text(
                    visual.emoji,
                    style: TextStyle(fontSize: m.size),
                  ),
                ),
              ),
            Positioned(
              right: -8,
              top: 18,
              child: Text(
                visual.emoji,
                style: const TextStyle(fontSize: 104),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A translucent circular control that sits over photography. Uses a
/// scrim rather than a solid fill so the image stays visible behind it.
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressScale: 0.84,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final TextStyle? style;

  const _IconLine({
    required this.icon,
    required this.color,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// Fades the photograph in over the gradient once decoded, so a slow
/// image resolves as a soft reveal rather than a hard pop. Any decode
/// failure renders nothing and leaves the gradient showing.
class _FadeInPhoto extends StatelessWidget {
  final String url;
  const _FadeInPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}
