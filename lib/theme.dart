import 'package:flutter/material.dart';

const green = Color(0xFF61E7A7);
const purple = Color(0xFF9B78FF);
const orange = Color(0xFFFF9F43);
const panel = Color(0xFF17171C);

ThemeData appTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF09090B),
  colorScheme: const ColorScheme.dark(primary: green, secondary: purple, tertiary: orange, surface: panel),
  useMaterial3: true,
  fontFamily: 'sans-serif',
  cardTheme: CardThemeData(color: panel, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFF29292F)))),
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF202026), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: green))),
  navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFF101014), indicatorColor: Color(0x3361E7A7), labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: green, foregroundColor: Colors.black),
);

class GradientTitle extends StatelessWidget {
  const GradientTitle(this.text, {super.key});
  final String text;
  @override Widget build(BuildContext context) => ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [green, purple]).createShader(b), child: Text(text, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)));
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.icon, required this.value, required this.label, this.color = green, super.key});
  final IconData icon; final String value, label; final Color color;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const Spacer(), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.white60))])));
}
