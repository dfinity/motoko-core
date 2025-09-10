import Set "Set";
import Order "Order";
import Nat "Nat";
import { Tuple2 } "Tuples";

module {
  public type PriorityQueue<T> = {
    set : Set.Set<(T, Nat)>;
    var counter : Nat
  };

  public func empty<T>() : PriorityQueue<T> = {
    set = Set.empty<(T, Nat)>();
    var counter = 0
  };

  public func singleton<T>(element : T) : PriorityQueue<T> = {
    set = Set.singleton((element, 0));
    var counter = 1
  };

  public func size<T>(priorityQueue : PriorityQueue<T>) : Nat = Set.size(priorityQueue.set);

  public func isEmpty<T>(priorityQueue : PriorityQueue<T>) : Bool = Set.isEmpty(priorityQueue.set);

  public func clear<T>(priorityQueue : PriorityQueue<T>) = Set.clear(priorityQueue.set);

  public func push<T>(priorityQueue : PriorityQueue<T>, compare : (T, T) -> Order.Order, element : T) {
    Set.add(priorityQueue.set, Tuple2.makeCompare(compare, Nat.compare), (element, priorityQueue.counter));
    priorityQueue.counter += 1
  };

  public func peek<T>(priorityQueue : PriorityQueue<T>) : ?T = do ? {
    let (element, _) = Set.max(priorityQueue.set)!;
    element
  };

  public func pop<T>(priorityQueue : PriorityQueue<T>, compare : (T, T) -> Order.Order) : ?T = do ? {
    let (element, nonce) = Set.max(priorityQueue.set)!;
    Set.remove(priorityQueue.set, Tuple2.makeCompare(compare, Nat.compare), (element, nonce));
    element
  }
}
