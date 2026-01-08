import 'package:pure_state/pure_state.dart';

/// Priority queue implementation using a binary heap.
///
/// Elements are ordered by a comparison function, with higher priority
/// elements (according to the comparison) being processed first.
///
/// Used internally by [PureStore] to process actions in priority order.
class PurePriorityQueue<E> {
  /// Creates a new priority queue with the given comparison function.
  ///
  /// The comparison function should return:
  /// - Negative value if a has higher priority than b
  /// - Zero if a and b have equal priority
  /// - Positive value if b has higher priority than a
  PurePriorityQueue(this._compare);

  /// Comparison function for ordering elements.
  final int Function(E a, E b) _compare;

  /// Internal heap storage.
  final List<E> _heap = [];

  /// Adds an element to the queue.
  ///
  /// The element will be placed according to its priority.
  void add(E element) {
    _heap.add(element);
    _bubbleUp(_heap.length - 1);
  }

  /// Removes and returns the highest priority element.
  ///
  /// Throws [StateError] if the queue is empty.
  E removeFirst() {
    if (_heap.isEmpty) {
      throw StateError('Queue is empty, cannot remove element');
    }

    if (_heap.length == 1) {
      return _heap.removeLast();
    }

    final first = _heap.first;
    _heap[0] = _heap.removeLast();
    _bubbleDown(0);
    return first;
  }

  /// Gets the highest priority element without removing it.
  ///
  /// Throws [StateError] if the queue is empty.
  E get first {
    if (_heap.isEmpty) {
      throw StateError('Queue is empty');
    }
    return _heap.first;
  }

  /// Whether the queue is empty.
  bool get isEmpty => _heap.isEmpty;

  /// Whether the queue is not empty.
  bool get isNotEmpty => _heap.isNotEmpty;

  /// Number of elements in the queue.
  int get length => _heap.length;

  /// Removes all elements from the queue.
  void clear() {
    _heap.clear();
  }

  /// Moves an element up the heap to maintain heap property.
  void _bubbleUp(int index) {
    if (index == 0) return;

    final parentIndex = (index - 1) ~/ 2;
    if (_compare(_heap[index], _heap[parentIndex]) < 0) {
      _swap(index, parentIndex);
      _bubbleUp(parentIndex);
    }
  }

  /// Moves an element down the heap to maintain heap property.
  void _bubbleDown(int index) {
    final leftChild = 2 * index + 1;
    final rightChild = 2 * index + 2;
    var smallest = index;

    if (leftChild < _heap.length &&
        _compare(_heap[leftChild], _heap[smallest]) < 0) {
      smallest = leftChild;
    }

    if (rightChild < _heap.length &&
        _compare(_heap[rightChild], _heap[smallest]) < 0) {
      smallest = rightChild;
    }

    if (smallest != index) {
      _swap(index, smallest);
      _bubbleDown(smallest);
    }
  }

  /// Swaps two elements in the heap.
  void _swap(int i, int j) {
    final temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }
}
