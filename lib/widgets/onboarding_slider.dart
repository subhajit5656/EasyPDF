import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../app_theme.dart';

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SlideData(this.icon, this.title, this.subtitle);
}

/// Auto-sliding illustration carousel shown above the auth buttons on the
/// Login screen (PRD 3.1). Uses icon-based placeholders — swap the
/// `icon` builder for real illustration assets whenever design provides them.
class OnboardingSlider extends StatefulWidget {
  const OnboardingSlider({super.key});

  @override
  State<OnboardingSlider> createState() => _OnboardingSliderState();
}

class _OnboardingSliderState extends State<OnboardingSlider> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  static const _slides = [
    _SlideData(
      Icons.picture_as_pdf_rounded,
      'Image to PDF',
      'Turn photos into clean, shareable PDFs in seconds',
    ),
    _SlideData(
      Icons.document_scanner_rounded,
      'Scan Documents',
      'Auto crop & scan pages straight from your camera',
    ),
    _SlideData(
      Icons.image_rounded,
      'PDF to Image',
      'Coming soon: pull images back out of any PDF',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_index + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = _slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        slide.icon,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      slide.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slide.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _controller,
          count: _slides.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: AppTheme.primary,
            dotColor: Color(0xFFDDE1EE),
            dotHeight: 8,
            dotWidth: 8,
          ),
        ),
      ],
    );
  }
}
