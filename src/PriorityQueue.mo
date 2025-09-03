import List "List";
import Types "Types";
import Order "Order";

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

  public func isEmpty<T>(priorityQueue : PriorityQueue<T>) : Bool = List.isEmpty(priorityQueue.heap);

  public func push<T>(priorityQueue : PriorityQueue<T>, compare : (T, T) -> Order.Order, element : T) {
    let heap = priorityQueue.heap;
    List.add(heap, element);
    var index = List.size(heap) - 1; // How do you silence this error?
    while (index > 0) {
      switch (compare(element[index], element[index / 2])) {
        case #greater {
          let aux = heap[index];
          heap[index] := heap[index / 2];
          heap[index / 2] := aux
        };
        case _ return
      }
    }
    // unreachable.
  }
}
