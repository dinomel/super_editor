import 'dart:ui';

extension ColorExtension on Color {
  String get toHexString =>
      '#${value.toRadixString(16).substring(2).toUpperCase()}';
}

extension StringExtension on String {
  Color get colorFromHex =>
      Color(int.tryParse(replaceFirst('#', '0xff')) ?? 0xFFFFFFFF);
}
