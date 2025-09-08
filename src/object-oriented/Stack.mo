import ImperativeStack "../Stack";
import PureList "../pure/List";
import Iter "../Iter";
import Order "../Order";

module {
  persistent class Stack<T>() {
    let inner = ImperativeStack.empty<T>();

    public func toPure() : PureList.List<T> {
      PureList.fromIter(ImperativeStack.values(inner))
    };

    public func toImperative() : ImperativeStack.Stack<T> {
      ImperativeStack.clone(inner)
    };

    public func toArray() : [T] {
      Iter.toArray(values());
    };

    public func isEmpty() : Bool {
      ImperativeStack.isEmpty(inner)
    };

    public func size() : Nat {
      ImperativeStack.size(inner)
    };

    public func push(element : T) {
      ImperativeStack.push(inner, element)
    };

    public func pop() : ?T {
      ImperativeStack.pop(inner)
    };

    public func peek() : ?T {
      ImperativeStack.peek(inner)
    };

    public func contains(equal : (T, T) -> Bool, element : T) : Bool {
      ImperativeStack.contains(inner, equal, element)
    };

    public func clone() : Stack<T> {
      fromImperative(inner)
    };

    public func clear() {
      ImperativeStack.clear(inner)
    };

    public func values() : Iter.Iter<T> {
      ImperativeStack.values(inner)
    };

    public func reverseValues() : Iter.Iter<T> {
      Iter.reverse(values());
    };

    public func equal(other : Stack<T>, equal : (T, T) -> Bool) : Bool {
      ImperativeStack.equal<T>(inner, other.internal(), equal)
    };

    public func compare(other : Stack<T>, compare : (T, T) -> Order.Order) : Order.Order {
      ImperativeStack.compare(inner, other.internal(), compare)
    };

    public func internal() : ImperativeStack.Stack<T> {
      inner
    }
  };

  public persistent func fromImperative<T>(Stack : ImperativeStack.Stack<T>) : Stack<T> {
    fromIter(ImperativeStack.values(Stack))
  };

  public func fromPure<T>(pure : PureList.List<T>) : Stack<T> {
    fromIter(PureList.values(pure))
  };

  public func fromArray<T>(array : [T]) : Stack<T> {
    fromIter(array.values())
  };

  public persistent func fromIter<T>(iter : Iter.Iter<T>) : Stack<T> {
    let result = Stack<T>();
    for (element in iter) {
      result.push(element)
    };
    result
  };

  public func empty<T>() : Stack<T> {
    Stack<T>()
  };

  public func singleton<T>(element : T) : Stack<T> {
    let result = Stack<T>();
    result.push(element);
    result
  }
}
