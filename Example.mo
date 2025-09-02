import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Stack "mo:core/Stack";
import PureList "mo:core/pure/List";
import { debugPrint } "mo:prim";

persistent actor Actor {
  let stack = Stack.new(Nat);
  let list = PureList.new(Text);

  public func main() : async () {
    assert stack.isEmpty();
    stack.push(123);
    debugPrint(stack.toText());
    assert stack.get(0) == ?123;
    assert stack.pop() == ?123;

    assert list.isEmpty();
    list.push("item");
    debugPrint(list.toText());
    assert list.get(0) == ?"item";
    assert list.pop() == ?"item"
  }
};
await Actor.main()
