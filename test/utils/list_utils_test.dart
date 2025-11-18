import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_atpl_app/utils/list_utils.dart';

void main() {
  group('chunkList', () {
    test('returns empty list when there are no items', () {
      expect(chunkList<int>(const [], size: 3), isEmpty);
    });

    test('preserves order and splits into chunks of requested size', () {
      final chunks = chunkList<int>(List.generate(11, (index) => index), size: 4);
      expect(chunks.length, 3);
      expect(chunks[0], [0, 1, 2, 3]);
      expect(chunks[1], [4, 5, 6, 7]);
      expect(chunks[2], [8, 9, 10]);
    });

    test('throws when chunk size is not positive', () {
      expect(() => chunkList([1, 2, 3], size: 0), throwsArgumentError);
    });
  });
}
