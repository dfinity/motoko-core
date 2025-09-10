/// A mutable priority queue of elements.
/// Always returns the element with the highest priority first,
/// as determined by a user-provided comparison function.
///
/// Typical use cases include:
/// * Task scheduling (highest-priority task first)
/// * Event simulation
/// * Pathfinding algorithms (e.g. Dijkstra, A*)
///
/// Example:
/// ```motoko
/// import PriorityQueue "mo:core/PriorityQueue";
///
/// persistent actor {
///   let pq = PriorityQueue.empty<Nat>();
///   PriorityQueue.push(pq, Nat.compare, 5);
///   PriorityQueue.push(pq, Nat.compare, 10);
///   PriorityQueue.push(pq, Nat.compare, 3);
///   assert PriorityQueue.pop(pq, Nat.compare) == ?10;
///   assert PriorityQueue.pop(pq, Nat.compare) == ?5;
///   assert PriorityQueue.pop(pq, Nat.compare) == ?3;
///   assert PriorityQueue.pop(pq, Nat.compare) == null;
/// }
/// ```
///
/// Internally implemented as a binary heap stored in a core library `List`.
///
/// Performance:
/// * Runtime: `O(log n)` for `push` and `pop` (amortized).
/// * Runtime: `O(1)` for `peek`, `clear`, `size`, and `isEmpty`.
/// * Space: `O(n)`, where `n` is the number of stored elements.
///
/// Implementation note (due to `List`):
/// * There is an additive memory overhead of `O(sqrt(n))`.
/// * For `push` and `pop`, the amortized time is `O(log n)`,  
///   but the worst case can involve an extra `O(sqrt(n))` step.
import List "List";
import Types "Types";
import Order "Order";
import Prim "mo:⛔";

module {
  public type PriorityQueue<T> = Types.PriorityQueue<T>;

  /// Returns an empty priority queue.
  ///
  /// Example:
  /// ```motoko
  /// let pq = PriorityQueue.empty<Nat>();
  /// assert PriorityQueue.isEmpty(pq);
  /// ```
  ///
  /// Runtime: `O(1)`. Space: `O(1)`.
  public func empty<T>() : PriorityQueue<T> = {
    heap = List.empty<T>()
  };

  /// Returns a priority queue containing a single element.
  ///
  /// Example:
  /// ```motoko
  /// let pq = PriorityQueue.singleton(42);
  /// assert PriorityQueue.peek(pq) == ?42;
  /// ```
  ///
  /// Runtime: `O(1)`. Space: `O(1)`.
  public func singleton<T>(element : T) : PriorityQueue<T> = {
    heap = List.singleton(element)
  };

  /// Returns the number of elements in the priority queue.
  ///
  /// Runtime: `O(1)`.
  public func size<T>(priorityQueue : PriorityQueue<T>) : Nat =
    List.size(priorityQueue.heap);

    /// Returns `true` iff the priority queue is empty.
  ///
  /// Example:
  /// ```motoko
  /// let pq = PriorityQueue.empty<Nat>();
  /// assert PriorityQueue.isEmpty(pq);
  /// PriorityQueue.push(pq, Nat.compare, 5);
  /// assert not PriorityQueue.isEmpty(pq);
  /// ```
  ///
  /// Runtime: `O(1)`. Space: `O(1)`.
  public func isEmpty<T>(priorityQueue : PriorityQueue<T>) : Bool =
    List.isEmpty(priorityQueue.heap);

  /// Removes all elements from the priority queue.
  ///
  /// Example:
  /// ```motoko
  /// let pq = PriorityQueue.empty<Nat>();
  /// PriorityQueue.push(pq, Nat.compare, 5);
  /// PriorityQueue.push(pq, Nat.compare, 10);
  /// assert not PriorityQueue.isEmpty(pq);
  /// PriorityQueue.clear(pq);
  /// assert PriorityQueue.isEmpty(pq);
  /// ```
  ///
  /// Runtime: `O(1)`. Space: `O(1)`.
  public func clear<T>(priorityQueue : PriorityQueue<T>) =
    List.clear(priorityQueue.heap);

  /// Inserts a new element into the priority queue.
  ///
  /// `compare` – comparison function that defines priority ordering.
  ///
  /// Example:
  /// ```motoko
  /// let pq = PriorityQueue.empty<Nat>();
  /// PriorityQueue.push(pq, Nat.compare, 5);
  /// PriorityQueue.push(pq, Nat.compare, 10);
  /// assert PriorityQueue.peek(pq) == ?10;
  /// ```
  ///
  /// Runtime: `O(log n)`. Space: `O(1)`.
  public func push<T>(
    priorityQueue : PriorityQueue<T>,
    compare : (T, T) -> Order.Order,
    element : T
  ) {
    let heap = priorityQueue.heap;
    List.add(heap, element);
    var index = List.size(heap) - 1;
    while (index > 0) {
      switch (compare(List.at(heap, index), List.at(heap, (index - 1) / 2))) {
        case (#greater) {
          swapHeapElements(heap, index, (index - 1) / 2);
          index := (index - 1) / 2
        };
        case _ return
      }
    }
  };

  /// Returns the element with the highest priority, without removing it.
  /// Returns `null` if the queue is empty.
  ///
  /// Example:
  /// ```motoko
  /// let pq = PriorityQueue.singleton(42);
  /// assert PriorityQueue.peek(pq) == ?42;
  /// ```
  ///
  /// Runtime: `O(1)`. Space: `O(1)`.
  public func peek<T>(priorityQueue : PriorityQueue<T>) : ?T =
    List.get(priorityQueue.heap, 0);

  /// Removes and returns the element with the highest priority.
  /// Returns `null` if the queue is empty.
  ///
  /// `compare` – comparison function that defines priority ordering.
  ///
  /// Example:
  /// ```motoko
  /// let pq = PriorityQueue.empty<Nat>();
  /// PriorityQueue.push(pq, Nat.compare, 5);
  /// PriorityQueue.push(pq, Nat.compare, 10);
  /// assert PriorityQueue.pop(pq, Nat.compare) == ?10;
  /// ```
  ///
  /// Runtime: `O(log n)`. Space: `O(1)`.
  public func pop<T>(
    priorityQueue : PriorityQueue<T>,
    compare : (T, T) -> Order.Order
  ) : ?T {
    let heap = priorityQueue.heap;
    if (List.isEmpty(heap)) {
      return null
    };
    let lastIndex = List.size(heap) - 1;
    swapHeapElements(heap, 0, lastIndex);
    var index = 0;
    label lbl loop {
      var best = index;
      let left = 2 * index + 1;
      if (left < lastIndex and compare(List.at(heap, left), List.at(heap, best)) == #greater) {
        best := left
      };
      let right = left + 1;
      if (right < lastIndex and compare(List.at(heap, right), List.at(heap, best)) == #greater) {
        best := right
      };
      if (best == index) {
        break lbl
      };
      swapHeapElements(heap, index, best);
      index := best
    };
    List.removeLast(heap)
  };

  /// Swaps two elements in the heap at the given indices.
  /// Internal helper function.
  func swapHeapElements<T>(heap : Types.List<T>, id1 : Nat, id2 : Nat) {
    let aux = List.at(heap, id1);
    List.put(heap, id1, List.at(heap, id2));
    List.put(heap, id2, aux)
  }
}
