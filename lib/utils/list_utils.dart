import 'dart:math';

/// Splits [items] into chunks of at most [size] elements while preserving order.
///
/// Throws an [ArgumentError] if [size] is less than or equal to zero.
List<List<T>> chunkList<T>(List<T> items, {required int size}) {
  if (size <= 0) {
    throw ArgumentError.value(size, 'size', 'Chunk size must be positive');
  }
  if (items.isEmpty) {
    return <List<T>>[];
  }
  final chunks = <List<T>>[];
  for (var i = 0; i < items.length; i += size) {
    final end = min(i + size, items.length);
    chunks.add(items.sublist(i, end));
  }
  return chunks;
}
