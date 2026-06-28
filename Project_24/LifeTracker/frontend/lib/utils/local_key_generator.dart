import 'dart:math';

class LocalKeyGenerator {
  LocalKeyGenerator._();

  static final _random = Random();

  static String nextKey(String prefix) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(0xFFFFFF);
    return '$prefix-$stamp-$suffix';
  }
}
