import Nat "mo:core/Nat";
import Stack "mo:core/Stack";
import PureList "mo:core/pure/List";
import { debugPrint } "mo:prim";

persistent actor Actor {
  let stack = Stack.new<Nat>(Nat);
  let list = PureList.new<Nat>(Nat);

  public func main() : async () {
    assert stack.isEmpty();
    stack.push(123);
    debugPrint(stack.toText());
    assert stack.get(0) == ?123;
    assert stack.pop() == ?123;

    assert list.isEmpty();
    list.pushFront(123);
    debugPrint(list.toText());
    assert list.get(0) == ?123;
    assert list.popFront() == ?123
  }
};
await Actor.main()
