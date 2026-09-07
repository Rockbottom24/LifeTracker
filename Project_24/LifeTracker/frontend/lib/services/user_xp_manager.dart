import 'package:shared_preferences/shared_preferences.dart';

class UserXpManager {
  static const _kXpKey = 'user_cumulative_xp';

  /// Returns total cumulative XP from SharedPreferences (never resets).
  static Future<int> getXp() async {
    final sp = await SharedPreferences.getInstance();
    int xp = sp.getInt(_kXpKey) ?? 0;
    if (xp == 0) {
      xp = 150; // Initial baseline
      await sp.setInt(_kXpKey, xp);
    }
    return xp;
  }

  /// Adds XP when a quest or milestone is completed.
  static Future<int> addXp(int amount) async {
    final sp = await SharedPreferences.getInstance();
    final current = sp.getInt(_kXpKey) ?? 150;
    final updated = (current + amount).clamp(0, 999999999);
    await sp.setInt(_kXpKey, updated);
    return updated;
  }

  /// Deducts XP if quest completion is undone.
  static Future<int> deductXp(int amount) async {
    final sp = await SharedPreferences.getInstance();
    final current = sp.getInt(_kXpKey) ?? 150;
    final updated = (current - amount).clamp(0, 999999999);
    await sp.setInt(_kXpKey, updated);
    return updated;
  }

  /// Level tier progression logic:
  /// - Level 1 to 3: +1,000 XP per level (L1: 0, L2: 1,000, L3: 2,000)
  /// - Level 3 to 5: +2,500 XP per level (L4: 4,500, L5: 7,000)
  /// - Level 5 to 8: +10,000 XP per level (L6: 17,000, L7: 27,000, L8: 37,000)
  /// - Level 8 to 12: +20,000 XP per level (L9: 57,000, L10: 77,000, L11: 97,000, L12: 117,000)
  /// - Level 12 to 18: +50,000 XP per level (L13: 167,000, L14: 217,000, L15: 267,000, L16: 317,000, L17: 367,000, L18: 417,000)
  /// - Level 18+: +100,000 XP per level
  static int getLevel(int xp) {
    if (xp < 0) return 1;
    if (xp < 2000) {
      return (xp ~/ 1000) + 1;
    } else if (xp < 7000) {
      return 3 + ((xp - 2000) ~/ 2500);
    } else if (xp < 37000) {
      return 5 + ((xp - 7000) ~/ 10000);
    } else if (xp < 117000) {
      return 8 + ((xp - 37000) ~/ 20000);
    } else if (xp < 417000) {
      return 12 + ((xp - 117000) ~/ 50000);
    } else {
      return 18 + ((xp - 417000) ~/ 100000);
    }
  }

  /// Calculates rank title for a given level.
  static String getRank(int level) {
    if (level >= 20) return 'King';
    if (level >= 16) return 'Hand of the King';
    if (level >= 12) return 'Warden';
    if (level >= 8) return 'Lord';
    if (level >= 5) return 'Knight';
    if (level >= 3) return 'Squire';
    return 'Smallfolk';
  }

  /// Formats XP display:
  /// - Reaches 1,000 -> 1k, 1.5k, 10k
  /// - Reaches 1,000,000 -> 1M, 2.5M
  static String formatXp(int xp) {
    if (xp >= 1000000) {
      double m = xp / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      double k = xp / 1000;
      return k % 1 == 0 ? '${k.toInt()}k' : '${k.toStringAsFixed(1)}k';
    } else {
      return '$xp';
    }
  }
}
