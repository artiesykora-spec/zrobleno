import 'package:flutter/material.dart';

const green = Color(0xFF69D49A);
const purple = Color(0xFF7662A8);
const orange = Color(0xFFF09A4E);
const sunYellow = Color(0xFFFFD45C);
const panel = Color(0xFF25243A);

const gameInk = Color(0xFF342B38);
const gamePaper = Color(0xFFF4E9D0);
const gamePaperShadow = Color(0xFFD6C09B);
const gamePlum = Color(0xFF3D315D);
const gameBlue = Color(0xFF4F78A9);
const gameCoral = Color(0xFFE56F61);
const gameMint = Color(0xFF70B98C);

ThemeData appTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF171B2D),
      colorScheme: const ColorScheme.dark(
        primary: sunYellow,
        secondary: green,
        tertiary: orange,
        surface: panel,
      ),
      useMaterial3: true,
      fontFamily: 'ZroblenoMono',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w900),
        titleLarge: TextStyle(fontWeight: FontWeight.w900),
        titleMedium: TextStyle(fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF4D4866), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF302D45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: sunYellow, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sunYellow,
        foregroundColor: gameInk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: sunYellow,
          foregroundColor: gameInk,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

class GradientTitle extends StatelessWidget {
  const GradientTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFE58D),
          shadows: const [
            Shadow(color: Color(0xAA251E36), offset: Offset(2, 3)),
          ],
        ),
      );
}

class PaperPanel extends StatelessWidget {
  const PaperPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = gamePaper,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2636), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66211C2B),
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: gameInk),
        child: IconTheme.merge(
          data: const IconThemeData(color: gameInk),
          child: child,
        ),
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: content,
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    this.color = green,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gameInk, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x77221C2C), offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gameInk),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: gameInk,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: gameInk,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
