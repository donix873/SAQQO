import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// A labelled synthetic scene for rehearsals without provider credentials.
/// It is never used as a real map or navigation geometry.
class PresentationMap extends StatelessWidget {
  const PresentationMap({super.key});
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _Scene())),
      Positioned(
        top: 18,
        left: 18,
        right: 18,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xDD152236),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AppLocalizations.of(context)!.demoMap,
            style: const TextStyle(
              fontFamily: "SaqgoSans",
              color: Color(0xFF28D6D0),
            ),
          ),
        ),
      ),
    ],
  );
}

class _Scene extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF09111E),
    );
    final block = Paint()..color = const Color(0xFF152638);
    for (var y = 0; y < size.height; y += 110) {
      for (var x = 0; x < size.width; x += 100) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 8, y + 8, 70, 75),
            const Radius.circular(12),
          ),
          block,
        );
      }
    }
    final road = Paint()
      ..color = const Color(0xFF34485B)
      ..strokeWidth = 10;
    for (var y = 80.0; y < size.height; y += 110) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 30), road);
    }
    for (var x = 70.0; x < size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x + 50, size.height), road);
    }
    final route = Path()
      ..moveTo(size.width * .2, size.height * .7)
      ..lineTo(size.width * .25, size.height * .5)
      ..lineTo(size.width * .7, size.height * .45)
      ..lineTo(size.width * .65, size.height * .25);
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF3A8BFF)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
    for (final point in [
      Offset(size.width * .25, size.height * .5),
      Offset(size.width * .65, size.height * .25),
    ]) {
      canvas.drawCircle(point, 13, Paint()..color = const Color(0xFF9263EE));
      canvas.drawCircle(point, 6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
