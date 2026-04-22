import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care_app/core/storage/in_memory_cache.dart';

void main() {
  late InMemoryCache<int> cache;

  setUp(() {
    cache = InMemoryCache();
  });

  test('should save and return data', () {
    cache.save(42);

    expect(cache.data, 42);
  });

  test('should clear data', () {
    cache.save(42);
    cache.clear();

    expect(cache.data, null);
  });
}