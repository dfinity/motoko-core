import Set "mo:core/object-oriented/Set";
import Nat "mo:core/Nat";

persistent actor Actor {
  let set = Set.Set<Nat>(Nat.compare);

  public func main() : async () {
    assert set.isEmpty();
    set.add(1);
    assert set.contains(1);
    set.remove(1);
    assert not set.contains(1);
  }
};
await Actor.main();
