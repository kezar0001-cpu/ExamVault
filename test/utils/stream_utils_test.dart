import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_atpl_app/utils/stream_utils.dart';

void main() {
  group('combineLatestListStreams', () {
    test('emits empty list when no streams are provided', () async {
      final result = await combineLatestListStreams<int>([]).first;
      expect(result, isEmpty);
    });

    test('combines emissions from multiple streams', () async {
      final controllerA = StreamController<List<int>>();
      final controllerB = StreamController<List<int>>();
      addTearDown(() async {
        await controllerA.close();
        await controllerB.close();
      });

      final combined = combineLatestListStreams<int>([
        controllerA.stream,
        controllerB.stream,
      ]);

      // Capture the first three emissions.
      final expectation = expectLater(
        combined.take(3),
        emitsInOrder([
          equals(<int>[1]),
          equals(<int>[1, 10, 11]),
          equals(<int>[2, 3, 10, 11]),
        ]),
      );

      controllerA.add([1]);
      await Future<void>.delayed(const Duration(milliseconds: 1));
      controllerB.add([10, 11]);
      await Future<void>.delayed(const Duration(milliseconds: 1));
      controllerA.add([2, 3]);
      await expectation;
    });
  });
}
