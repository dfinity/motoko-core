import Order "../Order";
import Iter "../Iter";
import ImperativeMap "../Map";
import PureMap "../pure/Map";
import Runtime "../Runtime";

module {
  type PersistentCompare<K> = stable (K, K) -> Order.Order;
  type TransientCompare<K> = (K, K) -> Order.Order;

  public class Map<K, V>(comparison : PersistentCompare<K>) {
    let inner = ImperativeMap.empty<K, V>();

    public func toPure() : PureMap.Map<K, V> {
      PureMap.fromIter(ImperativeMap.entries(inner), comparison : TransientCompare<K>)
    };

    public func toImperative() : ImperativeMap.Map<K, V> {
      ImperativeMap.clone(inner)
    };

    public func isEmpty() : Bool {
      ImperativeMap.isEmpty(inner)
    };

    public func size() : Nat {
      ImperativeMap.size(inner)
    };

    public func add(key : K, value : V) {
      ImperativeMap.add(inner, comparison : TransientCompare<K>, key, value)
    };

    public func containsKey(key : K) : Bool {
      ImperativeMap.containsKey(inner, comparison : TransientCompare<K>, key)
    };

    public func get(key : K) : ?V {
      ImperativeMap.get(inner, comparison : TransientCompare<K>, key)
    };

    public func remove(key : K) {
      ImperativeMap.remove(inner, comparison : TransientCompare<K>, key)
    };

    public func clone() : Map<K, V> {
      fromImperative(inner, comparison)
    };

    public func clear() {
      ImperativeMap.clear(inner)
    };

    public func equal(other : Map<K, V>, equalValue : (V, V) -> Bool) : Bool {
      ImperativeMap.equal<K, V>(inner, other.internal(), comparison : TransientCompare<K>, equalValue)
    };

    public func compare(other : Map<K, V>, compareValue : (V, V) -> Order.Order) : Order.Order {
      ImperativeMap.compare(inner, other.internal(), comparison : TransientCompare<K>, compareValue)
    };

    public func maxEntry() : ?(K, V) {
      ImperativeMap.maxEntry(inner)
    };

    public func minEntry() : ?(K, V) {
      ImperativeMap.minEntry(inner)
    };

    public func entries() : Iter.Iter<(K, V)> {
      ImperativeMap.entries(inner)
    };

    public func reverseEntries() : Iter.Iter<(K, V)> {
      ImperativeMap.reverseEntries(inner)
    };

    public func keys() : Iter.Iter<K> {
      ImperativeMap.keys(inner)
    };

    public func values() : Iter.Iter<V> {
      ImperativeMap.values(inner)
    };

    public func forEach(operation : (K, V) -> ()) {
      for (entry in entries()) {
        operation(entry)
      }
    };

    public func filter(criterion : (K, V) -> Bool) : Map<K, V> {
      fromImperative(ImperativeMap.filter(inner, comparison : TransientCompare<K>, criterion), comparison)
    };

    // type error [M0200], cannot decide type constructor equality
    // public func map<R>(project : (K, V) -> R) : Map<K, R> {
    //   fromImperative<K, R>(ImperativeMap.map<K, V, R>(inner, project), compare)
    // };

    public func all(predicate : (K, V) -> Bool) : Bool {
      ImperativeMap.all(inner, predicate)
    };

    public func any(predicate : (K, V) -> Bool) : Bool {
      ImperativeMap.any(inner, predicate)
    };

    public func toText(keyFormat : K -> Text, valueFormat : V -> Text) : Text {
      ImperativeMap.toText(inner, keyFormat, valueFormat)
    };

    public func internal() : ImperativeMap.Map<K, V> {
      inner
    }
  };

  public func fromImperative<K, V>(map : ImperativeMap.Map<K, V>, compare : PersistentCompare<K>) : Map<K, V> {
    fromIter(ImperativeMap.entries(map), compare)
  };

  public func fromIter<K, V>(iter : Iter.Iter<(K, V)>, compare : PersistentCompare<K>) : Map<K, V> {
    let result = Map<K, V>(compare);
    for ((key, value) in iter) {
      result.add(key, value)
    };
    result
  };

  public func empty<K, V>(compare : PersistentCompare<K>) : Map<K, V> {
    Map<K, V>(compare)
  };

  public func singleton<K, V>(compare : PersistentCompare<K>, key : K, value : V) : Map<K, V> {
    let result = Map<K, V>(compare);
    result.add(key, value);
    result
  }
}
