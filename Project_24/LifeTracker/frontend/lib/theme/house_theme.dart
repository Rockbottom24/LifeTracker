import 'package:flutter/material.dart';

class HouseTheme {
  const HouseTheme({
    required this.key,
    required this.name,
    required this.motto,
    required this.accent,
    required this.bannerGradient,
    required this.icon,
    required this.sigil,
  });

  final String key;
  final String name;
  final String motto;
  final Color accent;
  final List<Color> bannerGradient;
  final IconData icon;
  final String sigil;

  String get displayName => 'House $name';
  String get profileLabel => name;

  static const HouseTheme stark = HouseTheme(
    key: 'stark',
    name: 'Stark',
    motto: 'Winter is Coming',
    accent: Color(0xFF9FB2C8),
    bannerGradient: [Color(0xFF0C1118), Color(0xFF273244), Color(0xFF6E819B)],
    icon: Icons.shield_outlined,
    sigil: '⟡',
  );

  static const HouseTheme targaryen = HouseTheme(
    key: 'targaryen',
    name: 'Targaryen',
    motto: 'Fire and Blood',
    accent: Color(0xFFB86A4B),
    bannerGradient: [Color(0xFF170B0B), Color(0xFF4B1E1B), Color(0xFF8D4835)],
    icon: Icons.auto_awesome_outlined,
    sigil: '♔',
  );

  static const HouseTheme lannister = HouseTheme(
    key: 'lannister',
    name: 'Lannister',
    motto: 'Hear Me Roar',
    accent: Color(0xFFC7A24B),
    bannerGradient: [Color(0xFF15120C), Color(0xFF45361A), Color(0xFF8F6E21)],
    icon: Icons.workspace_premium_outlined,
    sigil: '✦',
  );

  static const HouseTheme baratheon = HouseTheme(
    key: 'baratheon',
    name: 'Baratheon',
    motto: 'Ours Is the Fury',
    accent: Color(0xFFB98645),
    bannerGradient: [Color(0xFF14110B), Color(0xFF4B391B), Color(0xFF7C5A22)],
    icon: Icons.flash_on_outlined,
    sigil: '⚡',
  );

  static const HouseTheme tyrell = HouseTheme(
    key: 'tyrell',
    name: 'Tyrell',
    motto: 'Growing Strong',
    accent: Color(0xFF93B56B),
    bannerGradient: [Color(0xFF10150D), Color(0xFF33401F), Color(0xFF6C8450)],
    icon: Icons.local_florist_outlined,
    sigil: '❋',
  );

  static const HouseTheme greyjoy = HouseTheme(
    key: 'greyjoy',
    name: 'Greyjoy',
    motto: 'We Do Not Sow',
    accent: Color(0xFF6D91A3),
    bannerGradient: [Color(0xFF0D1316), Color(0xFF22343C), Color(0xFF4D6A77)],
    icon: Icons.waves_outlined,
    sigil: '☸',
  );

  static const HouseTheme martell = HouseTheme(
    key: 'martell',
    name: 'Martell',
    motto: 'Unbowed, Unbent, Unbroken',
    accent: Color(0xFFCC7C43),
    bannerGradient: [Color(0xFF140E09), Color(0xFF4F2A15), Color(0xFF9E5D24)],
    icon: Icons.wb_sunny_outlined,
    sigil: '☉',
  );

  static const HouseTheme arryn = HouseTheme(
    key: 'arryn',
    name: 'Arryn',
    motto: 'As High as Honor',
    accent: Color(0xFF8EA1C7),
    bannerGradient: [Color(0xFF0D1119), Color(0xFF223050), Color(0xFF6A7EAC)],
    icon: Icons.terrain_outlined,
    sigil: '△',
  );

  static const HouseTheme tully = HouseTheme(
    key: 'tully',
    name: 'Tully',
    motto: 'Family, Duty, Honor',
    accent: Color(0xFF729DB1),
    bannerGradient: [Color(0xFF0B1214), Color(0xFF20323B), Color(0xFF4F7281)],
    icon: Icons.water_outlined,
    sigil: '≈',
  );

  static const List<HouseTheme> houses = [
    stark,
    targaryen,
    lannister,
    baratheon,
    tyrell,
    greyjoy,
    martell,
    arryn,
    tully,
  ];

  static HouseTheme fromKey(String? key) {
    final normalized = key?.trim().toLowerCase();
    for (final house in houses) {
      if (house.key == normalized) return house;
    }
    return stark;
  }
}
