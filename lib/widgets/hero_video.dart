import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/hero_video_service.dart';

/// A muted, looping video behind the home hero, with the existing
/// gradient as both the loading state and the permanent fallback.
///
/// Decorative by design: no controls, no sound, and it stops the moment
/// the widget leaves the tree so a decode loop is never left running
/// behind another tab. If anything fails — no key, no network, an
/// unsupported codec — [fallback] is what the user sees, and they see it
/// immediately rather than after a timeout.
class HeroVideo extends StatefulWidget {
  final Widget fallback;

  /// Fixed height, or null to expand into whatever the parent gives it —
  /// which is how the full-bleed home background uses it.
  final double? height;

  /// Darkening applied over the footage once it is playing. Stock food
  /// footage is unpredictable: bright plates, white tablecloths, blown
  /// highlights. Light text needs a scrim heavy enough to survive the
  /// worst frame, not the average one.
  final double scrimTop;
  final double scrimBottom;

  const HeroVideo({
    super.key,
    required this.fallback,
    this.height = 260,
    this.scrimTop = 0.30,
    this.scrimBottom = 0.55,
  });

  @override
  State<HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<HeroVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = await HeroVideoService.instance.heroClip();
    if (url == null || !mounted) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.height == null ? null : double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.fallback,
          if (_ready && _controller != null)
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 600),
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          // Scrim so headline text stays legible over unpredictable footage.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: _ready ? widget.scrimTop : 0.0),
                  Colors.black.withValues(alpha: _ready ? widget.scrimBottom : 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
