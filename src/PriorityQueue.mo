import List "List";
import Types "Types";
import Order "Order";
import Prim "mo:⛔";

module {
  public type PriorityQueue<T> = Types.PriorityQueue<T>;

  // Remove if not needed.
  let INTERNAL_ERROR = "PriorityQueue: internal error";

  public func empty<T>() : PriorityQueue<T> = {
    var heap = List.empty<T>()
  };

  public func singleton<T>(element : T) : PriorityQueue<T> = {
    var heap = List.singleton(element)
  };

  public func size<T>(priorityQueue : PriorityQueue<T>) : Nat = List.size(priorityQueue.heap);

  public func isEmpty<T>(priorityQueue : PriorityQueue<T>) : Bool = List.isEmpty(priorityQueue.heap);

  public func clear<T>(priorityQueue : PriorityQueue<T>) = List.clear(priorityQueue.heap);

  public func push<T>(priorityQueue : PriorityQueue<T>, compare : (T, T) -> Order.Order, element : T) {
    let heap = priorityQueue.heap;
    List.add(heap, element);
    var index = List.size(heap) - 1; // How do you silence this error?
    while (index > 0) {
      switch (compare(element[index], element[(index - 1) / 2])) {
        case (#greater) swapHeapElements(heap, index, (index - 1) / 2);
        case _ return
      }
    };
    Prim.trap(INTERNAL_ERROR); // unreachable.
  };

  public func peek<T>(priorityQueue : PriorityQueue<T>) : ?T {
    let heap = priorityQueue.heap;
    if (List.isEmpty(heap)) {
      null
    } else {
      ?heap[0]
    }
  };

  public func pop<T>(priorityQueue : PriorityQueue<T>, compare : (T, T) -> Order.Order) : ?T {
    let heap = priorityQueue.heap;
    if (List.isEmpty(heap)) {
      return null
    };
    let lastIndex = List.size(heap) - 1; // How do we silence this error.
    swapHeapElements(heap, 0, lastIndex);
    var index = 0;
    label lbl loop {
      var best = index;
      let left = 2 * index + 1;
      if (left < lastIndex and compare(heap[left], heap[best]) == #greater) {
        best := left
      };
      let right = left + 1;
      if (right < lastIndex and compare(heap[right], heap[best]) == #greater) {
        best := right
      };
      if (best == index) {
        break lbl
      };
      swapHeapElements(heap, index, best)
    };
    let ?top = List.removeLast(heap) else Prim.trap(INTERNAL_ERROR); // unreachable.
    top
  };

  func swapHeapElements<T>(heap : List<T>, id1 : Nat, id2 : Nat) {
    let aux = heap[id1];
    heap[id1] := heap[id2];
    heap[id2] := aux
  }
}
