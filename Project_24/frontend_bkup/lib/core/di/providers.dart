import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
