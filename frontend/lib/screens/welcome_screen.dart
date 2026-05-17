import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.explorerGradient(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
            child: Column(
              children: [
                const AnimatedReveal(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _BrandMark(),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedReveal(
                                delay: const Duration(milliseconds: 80),
                                child: SizedBox(
                                  height: constraints.maxHeight < 560
                                      ? 220
                                      : 310,
                                  child: const _MountainIllustration(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              AnimatedReveal(
                                delay: const Duration(milliseconds: 160),
                                child: Text(
                                  'Out There,\nGo Explore',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(fontSize: 42),
                                ),
                              ),
                              const SizedBox(height: 14),
                              AnimatedReveal(
                                delay: const Duration(milliseconds: 240),
                                child: Text(
                                  'Create a group poll, weigh everyone\'s top destinations, and pick the trip your crew can rally around.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    pushAppPage(context, const LoginScreen());
                  },
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Log In / Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepTeal.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.travel_explore_rounded, color: AppTheme.teal),
        ),
        const SizedBox(width: 10),
        Text('TravelPick', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _MountainIllustration extends StatelessWidget {
  const _MountainIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MountainPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDFFBF2), Colors.white],
      ).createShader(Offset.zero & size);
    final sunPaint = Paint()..color = AppTheme.amber.withValues(alpha: 0.75);
    final backMountain = Paint()..color = AppTheme.mint;
    final frontMountain = Paint()..color = AppTheme.teal;
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    final pathPaint = Paint()
      ..color = AppTheme.coral.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.04, 0, size.width * 0.92, size.height),
      const Radius.circular(34),
    );
    canvas.drawRRect(rect, skyPaint);

    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.24),
      size.width * 0.11,
      sunPaint,
    );

    final backPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..lineTo(size.width * 0.34, size.height * 0.28)
      ..lineTo(size.width * 0.62, size.height * 0.72)
      ..close()
      ..moveTo(size.width * 0.4, size.height * 0.72)
      ..lineTo(size.width * 0.64, size.height * 0.36)
      ..lineTo(size.width * 0.93, size.height * 0.72)
      ..close();
    canvas.drawPath(backPath, backMountain);

    final frontPath = Path()
      ..moveTo(size.width * 0.05, size.height * 0.82)
      ..lineTo(size.width * 0.43, size.height * 0.38)
      ..lineTo(size.width * 0.78, size.height * 0.82)
      ..close()
      ..moveTo(size.width * 0.28, size.height * 0.82)
      ..lineTo(size.width * 0.68, size.height * 0.32)
      ..lineTo(size.width * 0.96, size.height * 0.82)
      ..close();
    canvas.drawPath(frontPath, frontMountain);

    final snowPath = Path()
      ..moveTo(size.width * 0.43, size.height * 0.38)
      ..lineTo(size.width * 0.34, size.height * 0.51)
      ..lineTo(size.width * 0.47, size.height * 0.47)
      ..lineTo(size.width * 0.53, size.height * 0.54)
      ..close()
      ..moveTo(size.width * 0.68, size.height * 0.32)
      ..lineTo(size.width * 0.57, size.height * 0.47)
      ..lineTo(size.width * 0.72, size.height * 0.43)
      ..lineTo(size.width * 0.77, size.height * 0.52)
      ..close();
    canvas.drawPath(snowPath, snowPaint);

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.91)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.78,
        size.width * 0.5,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.53,
        size.width * 0.66,
        size.height * 0.45,
      );
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
