import Map "mo:core/object-oriented/Map";
import Nat "mo:core/Nat";

persistent actor Actor {
  let map = Map.Map<Nat, Text>(Nat.compare);

  public func main() : async () {
    assert map.isEmpty();
    map.add(1, "One");
    assert map.get(1) == ?"One";
    map.remove(1);
    assert map.get(1) == null;
  }
};
await Actor.main()
