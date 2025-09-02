import Nat "mo:core/Nat";
import Stack "mo:core/Stack";
import { debugPrint } "mo:prim";

persistent actor Actor {
  let stack = Stack.new<Nat>(Nat);

  public func main() : async () {
    assert stack.isEmpty();
    stack.push(123);
    debugPrint(stack.toText());

    assert stack.get(0) == ?123;
    assert stack.pop() == ?123
  }
};
await Actor.main()
