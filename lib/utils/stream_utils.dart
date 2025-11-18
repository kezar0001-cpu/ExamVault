import 'dart:async';

/// Emits a combined list every time any of the [streams] emit a new list.
///
/// If [streams] is empty it returns a stream that immediately emits an empty
/// list. When a single stream is provided it is returned directly to avoid an
/// extra layer of wrapping.
Stream<List<T>> combineLatestListStreams<T>(List<Stream<List<T>>> streams) {
  if (streams.isEmpty) {
    return Stream<List<T>>.value(const []);
  }
  if (streams.length == 1) {
    return streams.first;
  }

  return Stream<List<T>>.multi((controller) {
    final latestValues = List<List<T>>.generate(streams.length, (_) => <T>[]);
    final subscriptions = <StreamSubscription<List<T>>>[];
    var completedCount = 0;

    void emitCombined() {
      controller.add(latestValues.expand((list) => list).toList());
    }

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      final subscription = streams[index].listen(
        (event) {
          latestValues[index] = event;
          emitCombined();
        },
        onError: controller.addError,
        onDone: () {
          completedCount++;
          if (completedCount == streams.length) {
            controller.close();
          }
        },
      );
      subscriptions.add(subscription);
    }

    controller
      ..onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
  });
}
