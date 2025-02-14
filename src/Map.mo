/// An imperative key-value map based on order/comparison of the keys.
/// The map data structure type is stable and can be used for orthogonal persistence.
///
/// Example:
/// ```motoko
/// import Map "mo:base/Map";
/// import Nat "mo:base/Nat";
///
/// persistent actor {
///   let numberNames = Map.empty<Nat, Text>();
///   Map.add(numberNames, Nat.compare, 0, "Zero");
///   Map.add(numberNames, Nat.compare, 1, "One");
///   Map.add(numberNames, Nat.compare, 2, "Two");
/// }
/// ```
///
/// The internal implementation is a B-tree with order 32.
///
/// Performance:
/// * Runtime: `O(log(n))` worst case cost per insertion, removal, and retrieval operation.
/// * Space: `O(n)` for storing the entire map.
/// `n` denotes the number of key-value entries stored in the map.

// Data structure implementation is courtesy of Byron Becker.
// Source: https://github.com/canscale/StableHeapBTreeMap
// Copyright (c) 2022 Byron Becker.
// Distributed under Apache 2.0 license.
// With adjustments by the Motoko team.

import Types "Types";
import Order "Order";
import VarArray "VarArray";
import Runtime "Runtime";
import Stack "Stack";
import Option "Option";
import BTreeHelper "internal/BTreeHelper";

module {
  let btreeOrder = 32; // Should be >= 4 and <= 512.

  public type Map<K, V> = Types.Map<K, V>;

  type Node<K, V> = Types.Map.Node<K, V>;
  type Data<K, V> = Types.Map.Data<K, V>;
  type Internal<K, V> = Types.Map.Internal<K, V>;
  type Leaf<K, V> = Types.Map.Leaf<K, V>;

  // /// Convert the mutable key-value map to an immutable key-value map.
  // ///
  // /// Example:
  // /// ```motoko
  // /// import Map "mo:base/Map";
  // /// import PureMap "mo:base/pure/Map";
  // /// import Nat "mo:base/Nat";
  // ///
  // /// persistent actor {
  // ///   let map = Map.empty<Nat, Text>();
  // ///   Map.add(map, Nat.compare, 0, "Zero");
  // ///   Map.add(map, Nat.compare, 1, "One");
  // ///   Map.add(map, Nat.compare, 2, "Two");
  // ///   let pureMap = Map.toPure(map);
  // ///   assert(PureMap.get(pureMap, 0) == Map.get(map, 0));
  // /// }
  // /// ```
  // ///
  // /// Runtime: `O(n * log(n))`.
  // /// Space: `O(n)` retained memory plus garbage, see the note below.
  // /// where `n` denotes the number of key-value entries stored in the map and
  // /// assuming that the `compare` function implements an `O(1)` comparison.
  // ///
  // /// Note: Creates `O(n * log(n))` temporary objects that will be collected as garbage.
  // public func toPure<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order) : PureMap.Map<K, V> {
  //   PureMap.fromIter(entries(map), compare)
  // };

  // /// Convert an immutable key-value map to a mutable key-value map.
  // ///
  // /// Example:
  // /// ```motoko
  // /// import PureMap "mo:base/pure/Map";
  // /// import Map "mo:base/Map";
  // /// import Nat "mo:base/Nat";
  // ///
  // /// persistent actor {
  // ///   var pureMap = PureMap.empty<Nat, Text>();
  // ///   pureMap := PureMap.add(pureMap, Nat.compare, 0, "Zero");
  // ///   pureMap := PureMap.add(pureMap, Nat.compare, 1, "One");
  // ///   pureMap := PureMap.add(pureMap, Nat.compare, 2, "Two");
  // ///   let mutableMap = Map.fromPure(pureMap);
  // ///   assert(Map.get(mutableMap, 0) == Map.get(pureMap, 0));
  // /// }
  // /// ```
  // ///
  // /// Runtime: `O(n * log(n))`.
  // /// Space: `O(n)`.
  // /// where `n` denotes the number of key-value entries stored in the map and
  // /// assuming that the `compare` function implements an `O(1)` comparison.
  // public func fromPure<K, V>(map : PureMap.Map<K, V>) : Map<K, V> {
  //   fromIter(PureMap.entries(map), compare)
  // };

  /// Create a copy of the mutable key-value map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  ///
  /// persistent actor {
  ///   let originalMap = Map.empty<Nat, Text>();
  ///   Map.add(originalMap, Nat.compare, 0, "Zero");
  ///   Map.add(originalMap, Nat.compare, 1, "One");
  ///   Map.add(originalMap, Nat.compare, 2, "Two");
  ///   let clonedMap = Map.clone(originalMap);
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(n)`.
  /// where `n` denotes the number of key-value entries stored in the map.
  public func clone<K, V>(map : Map<K, V>) : Map<K, V> {
    {
      var root = cloneNode(map.root);
      var size = map.size
    }
  };

  /// Create a new empty mutable key-value map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Debug.print(Nat.toText(Map.size(map))); // prints `0`
  /// }
  /// ```
  ///
  /// Runtime: `O(1)`.
  /// Space: `O(1)`.
  public func empty<K, V>() : Map<K, V> {
    {
      var root = #leaf({
        data = {
          kvs = VarArray.repeat<?(K, V)>(null, btreeOrder - 1);
          var count = 0
        }
      });
      var size = 0
    }
  };

  /// Create a new mutable key-value map with a single entry.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let cityCodes = Map.singleton<Text, Nat>("Zurich", 8000);
  ///   Debug.print(debug_show(Map.size(cityCodes))); // prints `1`
  /// }
  /// ```
  ///
  /// Runtime: `O(1)`.
  /// Space: `O(1)`.
  public func singleton<K, V>(key : K, value : V) : Map<K, V> {
    let kvs = VarArray.repeat<?(K, V)>(null, btreeOrder - 1);
    kvs[0] := ?(key, value);
    { var root =
       #leaf { data = { kvs; var count = 1 } };
      var size = 1
    }
  };

  /// Delete all the entries in the key-value map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///   Debug.print(debug_show(Map.size(map))); // prints `3`
  ///
  ///   Map.clear(map);
  ///   Debug.print(debug_show(Map.size(map))); // prints `0`
  /// }
  /// ```
  ///
  /// Runtime: `O(1)`.
  /// Space: `O(1)`.
  public func clear<K, V>(map : Map<K, V>) {
    let emptyMap = empty<K, V>();
    map.root := emptyMap.root;
    map.size := 0
  };

  /// Determines whether a key-value map is empty.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   Debug.print(debug_show(Map.isEmpty(map))); // prints `false`
  ///   Map.clear(map);
  ///   Debug.print(debug_show(Map.isEmpty(map))); // prints `true`
  /// }
  /// ```
  ///
  /// Runtime: `O(1)`.
  /// Space: `O(1)`.
  public func isEmpty<K, V>(map : Map<K, V>) : Bool {
    map.size == 0
  };

  /// Return the number of entries in a key-value map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   Debug.print(Nat.toText(Map.size(map))); // prints `3`
  /// }
  /// ```
  ///
  /// Runtime: `O(1)`.
  /// Space: `O(1)`.
  public func size<K, V>(map : Map<K, V>) : Nat {
    map.size
  };

  /// Test whether two imperative maps have equal entries.
  /// Both maps have to be constructed by the same comparison function.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  /// import Text "mo:base/Text";
  ///
  /// persistent actor {
  ///   let map1 = Map.empty<Nat, Text>();
  ///   Map.add(map1, Nat.compare, 0, "Zero");
  ///   Map.add(map1, Nat.compare, 1, "One");
  ///   Map.add(map1, Nat.compare, 2, "Two");
  ///   let map2 = Map.clone(map1);
  ///
  ///   assert(Map.equal(map1, map2, Nat.equal, Text.equal));
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(1)`.
  public func equal<K, V>(map1 : Map<K, V>, map2 : Map<K, V>, equalKeys : (K, K) -> Bool, equalValues : (V, V) -> Bool) : Bool {
    if (size(map1) != size(map2)) {
       return false;
    };
    let iterator1 = entries(map1);
    let iterator2 = entries(map2);
    loop {
      let next1 = iterator1.next();
      let next2 = iterator2.next();
      switch (next1, next2) {
        case (null, null) {
          return true
        };
        case (?(key1, value1), ?(key2, value2)) {
          if (not equalKeys(key1, key2) or not equalValues(value1, value2)) {
            return false
          }
        };
        case _ { return false }
      }
    }
  };

  /// Tests whether the map contains the provided key.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Bool "mo:base/Bool";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   Debug.print(Bool.toText(Map.containsKey(map, Nat.compare, 1))); // prints `true`
  ///   Debug.print(Bool.toText(Map.containsKey(map, Nat.compare, 3))); // prints `false`
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(1)`.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func containsKey<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, key : K) : Bool {
    Option.isSome(get(map, compare, key))
  };

  /// Get the value associated with key in the given map if present and `null` otherwise.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   Debug.print(debug_show(Map.get(map, Nat.compare, 1))); // prints `?"One"`
  ///   Debug.print(debug_show(Map.get(map, Nat.compare, 3))); // prints `null`
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(1)`.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func get<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, key : K) : ?V {
    switch (map.root) {
      case (#internal(internalNode)) {
        getFromInternal(internalNode, compare, key)
      };
      case (#leaf(leafNode)) { getFromLeaf(leafNode, compare, key) }
    }
  };

  /// Insert a new key-value entry in the map.
  /// Traps if the key is already present in the map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Debug.print(debug_show(Iter.toArray(Map.entries(map))));
  ///   // [(0, "zero"), (1, "One")]
  ///   Map.add(map, Nat.compare, 0, "Nil");
  ///   // traps
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(log(n))`.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func add<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, key : K, value : V) {
    switch (swap(map, compare, key, value)) {
      case null {};
      case (?value) Runtime.trap("Map.add(): key is already present")
    }
  };

  /// Given `map` ordered by `compare`, add a new mapping from `key` to `value`.
  /// Replaces any existing entry with key `key`.
  /// Returns the modified map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/pure/Map";
  /// import Nat "mo:base/Nat";
  /// import Iter "mo:base/Iter";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///
  ///   Map.put(map, Nat.compare, 0, "Zero");
  ///   Map.put(map, Nat.compare, 1, "One");
  ///   Map.put(map, Nat.compare, 0, "Nil");
  ///
  ///   Debug.print(debug_show(Iter.toArray(Map.entries(map))));
  ///   // [(0, "Nil"), (1, "One")]
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(log(n))`.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func put<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, key : K, value : V) {
    ignore swap(map, compare, key, value)
  };

  /// Given `map` ordered by `compare`, add a new mapping from `key` to `value`.  /// Traps if `map` contains an existing entry for `key`.
  /// Returns the modified map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/pure/Map";
  /// import Nat "mo:base/Nat";
  /// import Iter "mo:base/Iter";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.update(map, Nat.compare, 0, "Nil");
  ///   Debug.print(debug_show(Iter.toArray(Map.entries(map))));
  ///   // [(0, "Nil")]
  ///   Map.update(map, Nat.compare, 1, "One");
  ///   // traps
  ///
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(log(n))`.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func update<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, key : K, value : V) {
    switch (swap(map, compare, key, value)) {
      case (?_) {};
      case _ Runtime.trap("Map.update(): key not present")
    }
  };

  /// Associates the value with the key in the map.
  /// If the key is not yet present in the map, a new key-value pair is added and `null` is returned.
  /// Otherwise, if the key is already present, the value is overwritten and the previous value is returned.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 1, "ONE");
  ///
  ///   let oldZero = Map.swap(map, Nat.compare, 0, "Zero"); // inserts new key-value pair.
  ///   Debug.print(debug_show(oldZero)); // prints `null`, key was inserted.
  ///
  ///   let oldOne = Map.swap(map, Nat.compare, 1, "One");   // overwrites value for existing key.
  ///   Debug.print(debug_show(oldOne)); // prints `?"ONE"`, previous value.
  ///   Debug.print(debug_show(Map.get(map, Nat.compare, 1))); // prints `?"One"`, new value.
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(log(n))`.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func swap<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, key : K, value : V) : ?V {
    let insertResult = switch (map.root) {
      case (#leaf(leafNode)) {
        leafInsertHelper<K, V>(leafNode, btreeOrder, compare, key, value)
      };
      case (#internal(internalNode)) {
        internalInsertHelper<K, V>(internalNode, btreeOrder, compare, key, value)
      }
    };

    switch (insertResult) {
      case (#insert(ov)) {
        switch (ov) {
          // if inserted a value that was not previously there, increment the tree size counter
          case null { map.size += 1 };
          case _ {}
        };
        ov
      };
      case (#promote({ kv; leftChild; rightChild })) {
        let kvs = VarArray.repeat<?(K,V)>(null, btreeOrder - 1);
	kvs[0] := ?kv;
	let children = VarArray.repeat<?Node<K,V>>(null, btreeOrder);
	children[0] := ?leftChild;
	children[1] := ?rightChild;
        map.root := #internal {
          data = {
            kvs;
            var count = 1
          };
          children
        };
        // promotion always comes from inserting a new element, so increment the tree size counter
        map.size += 1;

        null
      }
    }
  };

  /// Overwrites the value of an existing key and returns the previous value.
  /// If the key does not exist, it has no effect and returns `null`.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Null");
  ///
  ///   let oldZero = Map.replaceIfExists(map, Nat.compare, 0, "Zero"); // overwrites the value for existing key.
  ///   Debug.print(debug_show(oldZero)); // prints `?"Null"`, previous value.
  ///   Debug.print(debug_show(Map.get(map, Nat.compare, 0))); // prints `?"Zero"`, new value.
  ///
  ///   let oldOne = Map.replaceIfExists(map, Nat.compare, 1, "One");  // no effect, key is absent
  ///   Debug.print(debug_show(oldOne)); // prints `null`, key was absent.
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(log(n))`.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func replaceIfExists<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, key : K, value : V) : ?V {
    // TODO: Could be optimized in future
    if (containsKey(map, compare, key)) {
      swap(map, compare, key, value)
    } else {
      null
    }
  };

  /// Delete an existing entry by its key in the map.
  /// Traps if the key does not exist in the map.
  ///
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   Map.delete(map, Nat.compare, 0);
  ///   Debug.print(debug_show(Map.containsKey(map, Nat.compare, 0))); // prints `false`.
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(log(n))` including garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  ///
  /// Note: Creates `O(log(n))` objects that will be collected as garbage.
  public func delete<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, key : K) {
    let deleted = switch (map.root) {
      case (#leaf(leafNode)) {
        // TODO: think about how this can be optimized so don't have to do two steps (search and then insert)?
        switch (NodeUtil.getKeyIndex<K, V>(leafNode.data, compare, key)) {
          case (#keyFound(deleteIndex)) {
            leafNode.data.count -= 1;
            let (_, deletedValue) = BTreeHelper.deleteAndShift<(K, V)>(leafNode.data.kvs, deleteIndex);
            map.size -= 1;
            ?deletedValue
          };
          case _ { null }
        }
      };
      case (#internal(internalNode)) {
        let deletedValueResult = switch (internalDeleteHelper(internalNode, btreeOrder, compare, key, false)) {
          case (#delete(value)) { value };
          case (#mergeChild({ internalChild; deletedValue })) {
            if (internalChild.data.count > 0) {
              map.root := #internal(internalChild)
            }
            // This case will be hit if the BTree has order == 4
            // In this case, the internalChild has no keys (last key was merged with new child), so need to promote that merged child (its only child)
            else {
              map.root := switch (internalChild.children[0]) {
                case (?node) { node };
                case null {
                  Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.delete(), element deletion failed, due to a null replacement node error")
                }
              }
            };
            deletedValue
          }
        };
        switch (deletedValueResult) {
          // if deleted a value from the BTree, decrement the size
          case (?deletedValue) { map.size -= 1 };
          case null {}
        };
        deletedValueResult
      }
    };
    if (Option.isNull(deleted)) {
      Runtime.trap("Key is not present")
    }
  };

  /// Retrieves the key-value pair from the map with the maximum key.
  /// If the map is empty, returns `null`.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   Debug.print(debug_show(Map.maxEntry(map))); // prints `?(2, "Two")`.
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(1)`.
  /// where `n` denotes the number of key-value entries stored in the map.
  public func maxEntry<K, V>(map : Map<K, V>) : ?(K, V) {
    reverseEntries(map).next()
  };

  /// Retrieves the key-value pair from the map with the minimum key.
  /// If the map is empty, returns `null`.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   Debug.print(debug_show(Map.minEntry(map))); // prints `?(0, "Zero")`.
  /// }
  /// ```
  ///
  /// Runtime: `O(log(n))`.
  /// Space: `O(1)`.
  /// where `n` denotes the number of key-value entries stored in the map.
  public func minEntry<K, V>(map : Map<K, V>) : ?(K, V) {
    entries(map).next()
  };

  /// Returns an iterator over the key-value pairs in the map,
  /// traversing the entries in the ascending order of the keys.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   for (entry in Map.entries(map)) {
  ///      Debug.print(debug_show(entry));
  ///   }
  ///   // prints:
  ///   // `(0, "Zero")`
  ///   // `(1, "One")`
  ///   // `(2, "Two")`
  /// }
  /// ```
  /// Cost of iteration over all elements:
  /// Runtime: `O(n)`.
  /// Space: `O(1)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func entries<K, V>(map : Map<K, V>) : Types.Iter<(K, V)> {
    switch (map.root) {
      case (#leaf(leafNode)) { return leafEntries(leafNode) };
      case (#internal(internalNode)) { internalEntries(internalNode) }
    }
  };

  /// Returns an iterator over the key-value pairs in the map,
  /// traversing the entries in the descending order of the keys.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   for (entry in Map.reverseEntries(map)) {
  ///      Debug.print(debug_show(entry));
  ///   }
  ///   // prints:
  ///   // `(2, "Two")`
  ///   // `(1, "One")`
  ///   // `(0, "Zero")`
  /// }
  /// ```
  /// Cost of iteration over all elements:
  /// Runtime: `O(n)`.
  /// Space: `O(1)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func reverseEntries<K, V>(map : Map<K, V>) : Types.Iter<(K, V)> {
    switch (map.root) {
      case (#leaf(leafNode)) { return reverseLeafEntries(leafNode) };
      case (#internal(internalNode)) { reverseInternalEntries(internalNode) }
    }
  };

  /// Returns an iterator over the keys in the map,
  /// traversing all keys in ascending order.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   for (key in Map.keys(map)) {
  ///      Debug.print(Nat.toText(key));
  ///   }
  ///   // prints:
  ///   // `0`
  ///   // `1`
  ///   // `2`
  /// }
  /// ```
  /// Cost of iteration over all elements:
  /// Runtime: `O(n)`.
  /// Space: `O(1)`.
  public func keys<K, V>(map : Map<K, V>) : Types.Iter<K> {
    object {
      let iterator = entries(map);

      public func next() : ?K {
        switch (iterator.next()) {
          case null null;
          case (?(key, _)) ?key
        }
      }
    }
  };

  /// Returns an iterator over the values in the map,
  /// traversing the values in the ascending order of the keys to which they are associated.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   for (value in Map.values(map)) {
  ///      Debug.print(value);
  ///   }
  ///   // prints:
  ///   // `Zero`
  ///   // `One`
  ///   // `Two`
  /// }
  /// ```
  /// Cost of iteration over all elements:
  /// Runtime: `O(n)`.
  /// Space: `O(1)`.
  public func values<K, V>(map : Map<K, V>) : Types.Iter<V> {
    object {
      let iterator = entries(map);

      public func next() : ?V {
        switch (iterator.next()) {
          case null null;
          case (?(_, value)) ?value
        }
      }
    }
  };

  /// Create a mutable key-value map with the entries obtained from an iterator.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Iter "mo:base/Iter";
  ///
  /// persistent actor {
  ///   let iterator = Iter.fromArray([(0, "Zero"), (1, "One"), (2, "Two")]);
  ///   let map = Map.fromIter<Nat, Text>(iterator, Nat.compare);
  /// }
  /// ```
  ///
  /// Runtime: `O(n * log(n))`.
  /// Space: `O(n)`.
  /// where `n` denotes the number of key-value entries returned by the iterator and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func fromIter<K, V>(iter : Types.Iter<(K, V)>, compare : (K, K) -> Order.Order) : Map<K, V> {
    let map = empty<K, V>();
    for ((key, value) in iter) {
      add(map, compare, key, value)
    };
    map
  };

  /// Apply an operation on each key-value pair contained in the map.
  /// The operation is applied in ascending order of the keys.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   Map.forEach<Nat, Text>(map, func (key, value) {
  ///     Debug.print("key=" # Nat.toText(key) # ", value='" # value # "'");
  ///   })
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(1)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func forEach<K, V>(map : Map<K, V>, operation : (K, V) -> ()) {
    for (entry in entries(map)) {
      operation(entry)
    }
  };

  /// Filter entries in a new map.
  /// Create a copy of the mutable map that only contains the key-value pairs
  /// that fulfil the criterion function.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  ///
  /// persistent actor {
  ///   let numberNames = Map.empty<Nat, Text>();
  ///   Map.add(numberNames, Nat.compare, 0, "Zero");
  ///   Map.add(numberNames, Nat.compare, 1, "One");
  ///   Map.add(numberNames, Nat.compare, 2, "Two");
  ///
  ///   let evenNumbers = Map.filter<Nat, Text>(numberNames, Nat.compare, func (key, value) {
  ///     key % 2 == 0
  ///   });
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(n)`.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  public func filter<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order, criterion : (K, V) -> Bool) : Map<K, V> {
    let result = empty<K, V>();
    for ((key, value) in entries(map)) {
      if (criterion(key, value)) {
        add(result, compare, key, value)
      }
    };
    result
  };

  // TODO: remove redundant compare function by copying structure of map, not rebuilding it.
  /// Project all values of the map in a new map.
  /// Apply a mapping function to the values of each entry in the map and
  /// collect the mapped entries in a new mutable key-value map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Text "mo:base/Text";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let numberNames = Map.empty<Nat, Text>();
  ///   Map.add(numberNames, Nat.compare, 0, "Zero");
  ///   Map.add(numberNames, Nat.compare, 1, "One");
  ///   Map.add(numberNames, Nat.compare, 2, "Two");
  ///
  ///   let lowerCaseNames = Map.map<Nat, Text, Text>(numberNames, func (key, value) {
  ///     Text.toLower(value)
  ///   });
  ///   for (entry in Map.entries(lowerCaseNames)) {
  ///      Debug.print(debug_show(entry));
  ///   }
  ///   // prints:
  ///   // `(0, "zero")`
  ///   // `(1, "one")`
  ///   // `(2, "two")`
  /// }
  /// ```
  ///
  /// Runtime: `O(n * log(n))`.
  /// Space: `O(n)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that the `compare` function implements an `O(1)` comparison.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func map<K, V1, V2>(map : Map<K, V1>, project : (K, V1) -> V2) : Map<K, V2> {
    {
      var root = mapNode(map.root, project);
      var size = map.size
    }
  };

  /// Iterate all entries in ascending order of the keys,
  /// and accumulate the entries by applying the combine function, starting from a base value.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   let text = Map.foldLeft<Nat, Text, Text>(
  ///      map,
  ///      "",
  ///      func (accumulator, key, value) {
  ///        let separator = if (accumulator != "") { ", " } else { "" };
  ///        accumulator # separator # Nat.toText(key) # " is " # value
  ///      }
  ///   );
  ///   Debug.print(text);
  ///   // prints `0 is Zero, 1 is One, 2 is Two`
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(1)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func foldLeft<K, V, A>(
    map : Map<K, V>,
    base : A,
    combine : (A, K, V) -> A
  ) : A {
    var accumulator = base;
    for ((key, value) in entries(map)) {
      accumulator := combine(accumulator, key, value)
    };
    accumulator
  };

  /// Iterate all entries in descending order of the keys,
  /// and accumulate the entries by applying the combine function, starting from a base value.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   let text = Map.foldRight<Nat, Text, Text>(
  ///      map,
  ///      "",
  ///      func (key, value, accumulator) {
  ///        let separator = if (accumulator != "") { ", " } else { "" };
  ///        accumulator # separator # Nat.toText(key) # " is " # value
  ///      }
  ///   );
  ///   Debug.print(text);
  ///   // prints `2 is Two, 1 is One, 0 is Zero`
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(1)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func foldRight<K, V, A>(
    map : Map<K, V>,
    base : A,
    combine : (K, V, A) -> A
  ) : A {
    var accumulator = base;
    for ((key, value) in reverseEntries(map)) {
      accumulator := combine(key, value, accumulator)
    };
    accumulator
  };

  /// Check whether all entries in the map fulfil a predicate function, i.e.
  /// the predicate function returns `true` for all entries in the map.
  /// Returns `true` for an empty map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   let belowTen = Map.all<Nat, Text>(map, func (key, _) {
  ///     key < 10
  ///   }); // `true`
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(1)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func all<K, V>(map : Map<K, V>, predicate : (K, V) -> Bool) : Bool {
    for (entry in entries(map)) {
      if (not predicate(entry)) {
        return false
      }
    };
    true
  };

  /// Check whether at least one entry in the map fulfils the predicate function, i.e.
  /// the predicate function returns `true` for at least one entry in the map.
  /// Returns `false` for an empty map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   let aboveTen = Map.any<Nat, Text>(map, func (key, _) {
  ///     key > 10
  ///   }); // `false`
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(1)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func any<K, V>(map : Map<K, V>, predicate : (K, V) -> Bool) : Bool {
    for (entry in entries(map)) {
      if (predicate(entry)) {
        return true
      }
    };
    false
  };

  /// Filter all entries in the map by also applying a projection to the value.
  /// Apply a mapping function `project` to all entries in the map and collect all
  /// entries, for which the function returns a non-null new value. Collect all
  /// non-discarded entries with the key and new value in a new mutable map.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Text "mo:base/Text";
  /// import Debug "mo:base/Debug";
  ///
  /// persistent actor {
  ///   let numberNames = Map.empty<Nat, Text>();
  ///   Map.add(numberNames, Nat.compare, 0, "Zero");
  ///   Map.add(numberNames, Nat.compare, 1, "One");
  ///   Map.add(numberNames, Nat.compare, 2, "Two");
  ///
  ///   let evenNumbers = Map.filterMap<Nat, Text, Text>(numberNames, Nat.compare, func (key, value) {
  ///     if (key % 2 == 0) {
  ///        ?Text.toLower(value)
  ///     } else {
  ///        null // discard odd numbers
  ///     }
  ///   });
  ///   for (entry in Map.entries(evenNumbers)) {
  ///      Debug.print(debug_show(entry));
  ///   }
  ///   // prints:
  ///   // `(0, "zero")`
  ///   // `(2, "two")`
  /// }
  /// ```
  ///
  /// Runtime: `O(n * log(n))`.
  /// Space: `O(n)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func filterMap<K, V1, V2>(map : Map<K, V1>, compare : (K, K) -> Order.Order, project : (K, V1) -> ?V2) : Map<K, V2> {
    let result = empty<K, V2>();
    for ((key, value1) in entries(map)) {
      switch (project(key, value1)) {
        case null {};
        case (?value2) add(result, compare, key, value2)
      }
    };
    result
  };

  /// Internal sanity check function.
  /// Can be used to check that key/value pairs have been inserted with a consistent key comparison function.
  /// Traps if the internal map structure is invalid.
  public func assertValid<K, V>(map : Map<K, V>, compare : (K, K) -> Order.Order) {
    func checkIteration(iterator : Types.Iter<(K, V)>, order : Order.Order) {
      switch (iterator.next()) {
        case null {};
        case (?first) {
          var previous = first;
          loop {
            switch (iterator.next()) {
              case null return;
              case (?next) {
                if (compare(previous.0, next.0) != order) {
                  Runtime.trap("Invalid order")
                };
                previous := next
              }
            }
          }
        }
      }
    };
    checkIteration(entries(map), #less);
    checkIteration(reverseEntries(map), #greater)
  };

  /// Generate a textual representation of all the entries in the map.
  /// Primarily to be used for testing and debugging.
  /// The keys and values are formatted according to `keyFormat` and `valueFormat`.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  ///
  /// persistent actor {
  ///   let map = Map.empty<Nat, Text>();
  ///   Map.add(map, Nat.compare, 0, "Zero");
  ///   Map.add(map, Nat.compare, 1, "One");
  ///   Map.add(map, Nat.compare, 2, "Two");
  ///
  ///   let text = Map.toText<Nat, Text>(map, Nat.toText, func (value) { value });
  ///   // `{(0, Zero), (1, One), (2, Two)}`
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(n)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that `keyFormat` and `valueFormat` have runtime and space costs of `O(1)`.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func toText<K, V>(map : Map<K, V>, keyFormat : K -> Text, valueFormat : V -> Text) : Text {
    var text = "{";
    var sep = "";
    for ((key, value) in entries(map)) {
      text #= sep # "(" # keyFormat(key) # ", " # valueFormat(value) # ")";
      sep := ", "
    };
    text #= "}";
    text
  };

  /// Compare two maps by primarily comparing keys and secondarily values.
  /// Both maps must have been created by the same key comparison function.
  /// The two maps are iterated by the ascending order of their creation and
  /// order is determined by the following rules:
  /// Less:
  /// `map1` is less than `map2` if:
  ///  * the pairwise iteration hits a entry pair `entry1` and `entry2` where
  ///    `entry1` is less than `entry2` and all preceding entry pairs are equal, or,
  ///  * `map1` is  a strict prefix of `map2`, i.e. `map2` has more entries than `map1`
  ///     and all entries of `map1` occur at the beginning of iteration `map2`.
  /// `entry1` is less than `entry2` if:
  ///  * the key of `entry1` is less than the key of `entry2`, or
  ///  * `entry1` and `entry2` have equal keys and the value of `entry1` is less than
  ///    the value of `entry2`.
  /// Equal:
  /// `map1` and `map2` have same series of equal entries by pairwise iteration.
  /// Greater:
  /// `map1` is neither less nor equal `map2`.
  ///
  /// Example:
  /// ```motoko
  /// import Map "mo:base/Map";
  /// import Nat "mo:base/Nat";
  /// import Text "mo:base/Text";
  ///
  /// persistent actor {
  ///   let map1 = Map.empty<Nat, Text>();
  ///   Map.add(map1, Nat.compare, 0, "Zero");
  ///   Map.add(map1, Nat.compare, 1, "One");
  ///
  ///   let map2 = Map.empty<Nat, Text>();
  ///   Map.add(map2, Nat.compare, 0, "Zero");
  ///   Map.add(map2, Nat.compare, 2, "Two");
  ///
  ///   let orderLess = Map.compare(map1, map2, Nat.compare, Text.compare);
  ///   // `#less`
  ///   let orderEqual = Map.compare(map1, map1, Nat.compare, Text.compare);
  ///   // `#equal`
  ///   let orderGreater = Map.compare(map2, map1, Nat.compare, Text.compare);
  ///   // `#greater`
  /// }
  /// ```
  ///
  /// Runtime: `O(n)`.
  /// Space: `O(1)` retained memory plus garbage, see below.
  /// where `n` denotes the number of key-value entries stored in the map and
  /// assuming that `compareKey` and `compareValue` have runtime and space costs of `O(1)`.
  ///
  /// Note: Creates `O(log(n))` temporary objects that will be collected as garbage.
  public func compare<K, V>(map1 : Map<K, V>, map2 : Map<K, V>, compareKey : (K, K) -> Order.Order, compareValue : (V, V) -> Order.Order) : Order.Order {
    let iterator1 = entries(map1);
    let iterator2 = entries(map2);
    loop {
      switch (iterator1.next(), iterator2.next()) {
        case (null, null) return #equal;
        case (null, _) return #less;
        case (_, null) return #greater;
        case (?(key1, value1), ?(key2, value2)) {
          let keyComparison = compareKey(key1, key2);
          if (keyComparison != #equal) {
            return keyComparison
          };
          let valueComparison = compareValue(value1, value2);
          if (valueComparison != #equal) {
            return valueComparison
          }
        }
      }
    }
  };

  func leafEntries<K, V>({ data } : Leaf<K, V>) : Types.Iter<(K, V)> {
    var i : Nat = 0;
    object {
      public func next() : ?(K, V) {
        if (i >= data.count) {
          return null
        } else {
          let res = data.kvs[i];
          i += 1;
          return res
        }
      }
    }
  };

  func reverseLeafEntries<K, V>({ data } : Leaf<K, V>) : Types.Iter<(K, V)> {
    var i : Nat = data.count;
    object {
      public func next() : ?(K, V) {
        if (i == 0) {
          return null
        } else {
          let res = data.kvs[i - 1];
          i -= 1;
          return res
        }
      }
    }
  };

  // Cursor type that keeps track of the current node and the current key-value index in the node
  type NodeCursor<K, V> = { node : Node<K, V>; kvIndex : Nat };

  func internalEntries<K, V>(internal : Internal<K, V>) : Types.Iter<(K, V)> {
    object {
      // The nodeCursorStack keeps track of the current node and the current key-value index in the node
      // We use a stack here to push to/pop off the next node cursor to visit
      let nodeCursorStack = initializeForwardNodeCursorStack(internal);

      public func next() : ?(K, V) {
        // pop the next node cursor off the stack
        var nodeCursor = Stack.pop(nodeCursorStack);
        switch (nodeCursor) {
          case null { return null };
          case (?{ node; kvIndex }) {
            switch (node) {
              // if a leaf node, iterate through the leaf node's next key-value pair
              case (#leaf(leafNode)) {
                let lastKV = leafNode.data.count - 1 : Nat;
                if (kvIndex > lastKV) {
                  Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.internalEntries(), leaf kvIndex out of bounds")
                };

                let currentKV = switch (leafNode.data.kvs[kvIndex]) {
                  case (?kv) { kv };
                  case null {
                    Runtime.trap(
                      "UNREACHABLE_ERROR: file a bug report! In Map.internalEntries(), null key-value pair found in leaf node."
                      # "leafNode.data.count=" # debug_show (leafNode.data.count) # ", kvIndex=" # debug_show (kvIndex)
                    )
                  }
                };
                // if not at the last key-value pair, push the next key-value index of the leaf onto the stack and return the current key-value pair
                if (kvIndex < lastKV) {
                  Stack.push(
                    nodeCursorStack,
                    {
                      node = #leaf(leafNode);
                      kvIndex = kvIndex + 1 : Nat
                    }
                  )
                };

                // return the current key-value pair
                ?currentKV
              };
              // if an internal node
              case (#internal(internalNode)) {
                let lastKV = internalNode.data.count - 1 : Nat;
                // Developer facing message in case of a bug
                if (kvIndex > lastKV) {
                  Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.internalEntries(), internal kvIndex out of bounds")
                };

                let currentKV = switch (internalNode.data.kvs[kvIndex]) {
                  case (?kv) { kv };
                  case null {
                    Runtime.trap(
                      "UNREACHABLE_ERROR: file a bug report! In Map.internalEntries(), null key-value pair found in internal node. " #
                      "internal.data.count=" # debug_show (internalNode.data.count) # ", kvIndex=" # debug_show (kvIndex)
                    )
                  }
                };

                let nextCursor = {
                  node = #internal(internalNode);
                  kvIndex = kvIndex + 1 : Nat
                };
                // if not the last key-value pair, push the next key-value index of the internal node onto the stack
                if (kvIndex < lastKV) {
                  Stack.push(nodeCursorStack, nextCursor)
                };
                // traverse the next child's min subtree and push the resulting node cursors onto the stack
                // then return the current key-value pair of the internal node
                traverseMinSubtreeIter(nodeCursorStack, nextCursor);
                ?currentKV
              }
            }
          }
        }
      }
    }
  };

  func reverseInternalEntries<K, V>(internal : Internal<K, V>) : Types.Iter<(K, V)> {
    object {
      // The nodeCursorStack keeps track of the current node and the current key-value index in the node
      // We use a stack here to push to/pop off the next node cursor to visit
      let nodeCursorStack = initializeReverseNodeCursorStack(internal);

      public func next() : ?(K, V) {
        // pop the next node cursor off the stack
        var nodeCursor = Stack.pop(nodeCursorStack);
        switch (nodeCursor) {
          case null { return null };
          case (?{ node; kvIndex }) {
            let firstKV = 0 : Nat;
            assert (kvIndex > firstKV);
            switch (node) {
              // if a leaf node, reverse iterate through the leaf node's next key-value pair
              case (#leaf(leafNode)) {
                let currentKV = switch (leafNode.data.kvs[kvIndex - 1]) {
                  case (?kv) { kv };
                  case null {
                    Runtime.trap(
                      "UNREACHABLE_ERROR: file a bug report! In Map.reverseInternalEntries(), null key-value pair found in leaf node."
                      # "leafNode.data.count=" # debug_show (leafNode.data.count) # ", kvIndex=" # debug_show (kvIndex)
                    )
                  }
                };
                // if not at the last key-value pair, push the previous key-value index of the leaf onto the stack and return the current key-value pair
                if (kvIndex - 1 : Nat > firstKV) {
                  Stack.push(
                    nodeCursorStack,
                    {
                      node = #leaf(leafNode);
                      kvIndex = kvIndex - 1 : Nat
                    }
                  )
                };

                // return the current key-value pair
                ?currentKV
              };
              // if an internal node
              case (#internal(internalNode)) {
                let currentKV = switch (internalNode.data.kvs[kvIndex - 1]) {
                  case (?kv) { kv };
                  case null {
                    Runtime.trap(
                      "UNREACHABLE_ERROR: file a bug report! In Map.reverseInternalEntries(), null key-value pair found in internal node. " #
                      "internal.data.count=" # debug_show (internalNode.data.count) # ", kvIndex=" # debug_show (kvIndex)
                    )
                  }
                };

                let previousCursor = {
                  node = #internal(internalNode);
                  kvIndex = kvIndex - 1 : Nat
                };
                // if not the first key-value pair, push the previous key-value index of the internal node onto the stack
                if (kvIndex - 1 : Nat > firstKV) {
                  Stack.push(nodeCursorStack, previousCursor)
                };
                // traverse the previous child's max subtree and push the resulting node cursors onto the stack
                // then return the current key-value pair of the internal node
                traverseMaxSubtreeIter(nodeCursorStack, previousCursor);
                ?currentKV
              }
            }
          }
        }
      }
    }
  };

  func initializeForwardNodeCursorStack<K, V>(internal : Internal<K, V>) : Stack.Stack<NodeCursor<K, V>> {
    let nodeCursorStack = Stack.empty<NodeCursor<K, V>>();
    let nodeCursor : NodeCursor<K, V> = {
      node = #internal(internal);
      kvIndex = 0
    };

    // push the initial cursor to the stack
    Stack.push(nodeCursorStack, nodeCursor);
    // then traverse left
    traverseMinSubtreeIter(nodeCursorStack, nodeCursor);
    nodeCursorStack
  };

  func initializeReverseNodeCursorStack<K, V>(internal : Internal<K, V>) : Stack.Stack<NodeCursor<K, V>> {
    let nodeCursorStack = Stack.empty<NodeCursor<K, V>>();
    let nodeCursor : NodeCursor<K, V> = {
      node = #internal(internal);
      kvIndex = internal.data.count
    };

    // push the initial cursor to the stack
    Stack.push(nodeCursorStack, nodeCursor);
    // then traverse left
    traverseMaxSubtreeIter(nodeCursorStack, nodeCursor);
    nodeCursorStack
  };

  // traverse the min subtree of the current node cursor, passing each new element to the node cursor stack
  func traverseMinSubtreeIter<K, V>(nodeCursorStack : Stack.Stack<NodeCursor<K, V>>, nodeCursor : NodeCursor<K, V>) {
    var currentNode = nodeCursor.node;
    var childIndex = nodeCursor.kvIndex;

    label l loop {
      switch (currentNode) {
        // If currentNode is leaf, have hit the minimum element of the subtree and already pushed it's cursor to the stack
        // so can return
        case (#leaf(_)) {
          return
        };
        // If currentNode is internal, add it's left most child to the stack and continue traversing
        case (#internal(internalNode)) {
          switch (internalNode.children[childIndex]) {
            // Push the next min (left most) child node to the stack
            case (?childNode) {
              childIndex := 0;
              currentNode := childNode;
              Stack.push(
                nodeCursorStack,
                {
                  node = currentNode;
                  kvIndex = childIndex
                }
              )
            };
            case null {
              Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.traverseMinSubtreeIter(), null child node error")
            }
          }
        }
      }
    }
  };

  // traverse the max subtree of the current node cursor, passing each new element to the node cursor stack
  func traverseMaxSubtreeIter<K, V>(nodeCursorStack : Stack.Stack<NodeCursor<K, V>>, nodeCursor : NodeCursor<K, V>) {
    var currentNode = nodeCursor.node;
    var childIndex = nodeCursor.kvIndex;

    label l loop {
      switch (currentNode) {
        // If currentNode is leaf, have hit the maximum element of the subtree and already pushed it's cursor to the stack
        // so can return
        case (#leaf(_)) {
          return
        };
        // If currentNode is internal, add it's right most child to the stack and continue traversing
        case (#internal(internalNode)) {
          assert (childIndex <= internalNode.data.count); // children are one more than data entries
          switch (internalNode.children[childIndex]) {
            // Push the next max (right most) child node to the stack
            case (?childNode) {
              childIndex := switch (childNode) {
                case (#internal(internalNode)) internalNode.data.count;
                case (#leaf(leafNode)) leafNode.data.count
              };
              currentNode := childNode;
              Stack.push(
                nodeCursorStack,
                {
                  node = currentNode;
                  kvIndex = childIndex
                }
              )
            };
            case null {
              Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.traverseMaxSubtreeIter(), null child node error")
            }
          }
        }
      }
    }
  };

  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateInternalDeleteResult<K, V> = {
    // element was deleted or not found, returning the old value (?value or null)
    #delete : ?V;
    // deleted an element, but was unable to successfully borrow and rebalance at the previous level without merging children
    // the internalChild is the merged child that needs to be rebalanced at the next level up in the BTree
    #mergeChild : {
      internalChild : Internal<K, V>;
      deletedValue : ?V
    }
  };

  func internalDeleteHelper<K, V>(internalNode : Internal<K, V>, order : Nat, compare : (K, K) -> Order.Order, deleteKey : K, skipNode : Bool) : IntermediateInternalDeleteResult<K, V> {
    let minKeys = NodeUtil.minKeysFromOrder(order);
    let keyIndex = NodeUtil.getKeyIndex<K, V>(internalNode.data, compare, deleteKey);

    // match on both the result of the node binary search, and if this node level should be skipped even if the key is found (internal kv replacement case)
    switch (keyIndex, skipNode) {
      // if key is found in the internal node
      case (#keyFound(deleteIndex), false) {
        let deletedValue = switch (internalNode.data.kvs[deleteIndex]) {
          case (?kv) { ?kv.1 };
          case null { assert false; null }
        };
        // TODO: (optimization) replace with deletion in one step without having to retrieve the maxKey first
        let replaceKV = NodeUtil.getMaxKeyValue(internalNode.children[deleteIndex]);
        internalNode.data.kvs[deleteIndex] := ?replaceKV;
        switch (internalDeleteHelper(internalNode, order, compare, replaceKV.0, true)) {
          case (#delete(_)) { #delete(deletedValue) };
          case (#mergeChild({ internalChild })) {
            #mergeChild({ internalChild; deletedValue })
          }
        }
      };
      // if key is not found in the internal node OR the key is found, but skipping this node (because deleting the in order precessor i.e. replacement kv)
      // in both cases need to descend and traverse to find the kv to delete
      case ((#keyFound(_), true) or (#notFound(_), _)) {
        let childIndex = switch (keyIndex) {
          case (#keyFound(replacedSkipKeyIndex)) { replacedSkipKeyIndex };
          case (#notFound(childIndex)) { childIndex }
        };
        let child = switch (internalNode.children[childIndex]) {
          case (?c) { c };
          case null {
            Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.internalDeleteHelper, child index of #keyFound or #notfound is null")
          }
        };
        switch (child) {
          // if child is internal
          case (#internal(internalChild)) {
            switch (internalDeleteHelper(internalChild, order, compare, deleteKey, false), childIndex == 0) {
              // if value was successfully deleted and no additional tree re-balancing is needed, return the deleted value
              case (#delete(v), _) { #delete(v) };
              // if internalChild needs rebalancing and pulling child is left most
              case (#mergeChild({ internalChild; deletedValue }), true) {
                // try to pull left-most key and child from right sibling
                switch (NodeUtil.borrowFromInternalSibling(internalNode.children, childIndex + 1, #successor)) {
                  // if can pull up sibling kv and child
                  case (#borrowed({ deletedSiblingKVPair; child })) {
                    NodeUtil.rotateBorrowedKVsAndChildFromSibling(
                      internalNode,
                      childIndex,
                      deletedSiblingKVPair,
                      child,
                      internalChild,
                      #right
                    );
                    #delete(deletedValue)
                  };
                  // unable to pull from sibling, need to merge with right sibling and push down parent
                  case (#notEnoughKeys(sibling)) {
                    // get the parent kv that will be pushed down the the child
                    let kvPairToBePushedToChild = ?BTreeHelper.deleteAndShift(internalNode.data.kvs, 0);
                    internalNode.data.count -= 1;
                    // merge the children and push down the parent
                    let newChild = NodeUtil.mergeChildrenAndPushDownParent<K, V>(internalChild, kvPairToBePushedToChild, sibling);
                    // update children of the parent
                    internalNode.children[0] := ?#internal(newChild);
                    ignore ?BTreeHelper.deleteAndShift(internalNode.children, 1);

                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue })
                    } else {
                      #delete(deletedValue)
                    }
                  }
                }
              };
              // if internalChild needs rebalancing and pulling child is > 0, so a left sibling exists
              case (#mergeChild({ internalChild; deletedValue }), false) {
                // try to pull right-most key and its child directly from left sibling
                switch (NodeUtil.borrowFromInternalSibling(internalNode.children, childIndex - 1 : Nat, #predecessor)) {
                  case (#borrowed({ deletedSiblingKVPair; child })) {
                    NodeUtil.rotateBorrowedKVsAndChildFromSibling(
                      internalNode,
                      childIndex - 1 : Nat,
                      deletedSiblingKVPair,
                      child,
                      internalChild,
                      #left
                    );
                    #delete(deletedValue)
                  };
                  // unable to pull from left sibling
                  case (#notEnoughKeys(leftSibling)) {
                    // if child is not last index, try to pull from the right child
                    if (childIndex < internalNode.data.count) {
                      switch (NodeUtil.borrowFromInternalSibling(internalNode.children, childIndex, #successor)) {
                        // if can pull up sibling kv and child
                        case (#borrowed({ deletedSiblingKVPair; child })) {
                          NodeUtil.rotateBorrowedKVsAndChildFromSibling(
                            internalNode,
                            childIndex,
                            deletedSiblingKVPair,
                            child,
                            internalChild,
                            #right
                          );
                          return #delete(deletedValue)
                        };
                        // if cannot borrow, from left or right, merge (see below)
                        case _ {}
                      }
                    };

                    // get the parent kv that will be pushed down the the child
                    let kvPairToBePushedToChild = ?BTreeHelper.deleteAndShift(internalNode.data.kvs, childIndex - 1 : Nat);
                    internalNode.data.count -= 1;
                    // merge it the children and push down the parent
                    let newChild = NodeUtil.mergeChildrenAndPushDownParent(leftSibling, kvPairToBePushedToChild, internalChild);

                    // update children of the parent
                    internalNode.children[childIndex - 1] := ?#internal(newChild);
                    ignore ?BTreeHelper.deleteAndShift(internalNode.children, childIndex);

                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue })
                    } else {
                      #delete(deletedValue)
                    }
                  }
                }
              }
            }
          };
          // if child is leaf
          case (#leaf(leafChild)) {
            switch (leafDeleteHelper(leafChild, order, compare, deleteKey), childIndex == 0) {
              case (#delete(value), _) { #delete(value) };
              // if delete child is left most, try to borrow from right child
              case (#mergeLeafData({ leafDeleteIndex }), true) {
                switch (NodeUtil.borrowFromRightLeafChild(internalNode.children, childIndex)) {
                  case (?borrowedKVPair) {
                    let kvPairToBePushedToChild = internalNode.data.kvs[childIndex];
                    internalNode.data.kvs[childIndex] := ?borrowedKVPair;

                    let deletedKV = BTreeHelper.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, leafChild.data.count - 1, leafDeleteIndex);
                    #delete(?deletedKV.1)
                  };

                  case null {
                    // can't borrow from right child, delete from leaf and merge with right child and parent kv, then push down into new leaf
                    let rightChild = switch (internalNode.children[childIndex + 1]) {
                      case (?#leaf(rc)) { rc };
                      case _ {
                        Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.internalDeleteHelper, if trying to borrow from right leaf child is null, rightChild index cannot be null or internal")
                      }
                    };
                    let (mergedLeaf, deletedKV) = mergeParentWithLeftRightChildLeafNodesAndDelete(
                      internalNode.data.kvs[childIndex],
                      leafChild,
                      rightChild,
                      leafDeleteIndex,
                      #left
                    );
                    // delete the left most internal node kv, since was merging from a deletion in left most child (0) and the parent kv was pushed into the mergedLeaf
                    ignore BTreeHelper.deleteAndShift<(K, V)>(internalNode.data.kvs, 0);
                    // update internal node children
                    BTreeHelper.replaceTwoWithElementAndShift<Node<K, V>>(internalNode.children, #leaf(mergedLeaf), 0);
                    internalNode.data.count -= 1;

                    if (internalNode.data.count < minKeys) {
                      #mergeChild({
                        internalChild = internalNode;
                        deletedValue = ?deletedKV.1
                      })
                    } else {
                      #delete(?deletedKV.1)
                    }

                  }
                }
              };
              // if delete child is middle or right most, try to borrow from left child
              case (#mergeLeafData({ leafDeleteIndex }), false) {
                // if delete child is right most, try to borrow from left child
                switch (NodeUtil.borrowFromLeftLeafChild(internalNode.children, childIndex)) {
                  case (?borrowedKVPair) {
                    let kvPairToBePushedToChild = internalNode.data.kvs[childIndex - 1];
                    internalNode.data.kvs[childIndex - 1] := ?borrowedKVPair;
                    let kvDelete = BTreeHelper.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, 0, leafDeleteIndex);
                    #delete(?kvDelete.1)
                  };
                  case null {
                    // if delete child is in the middle, try to borrow from right child
                    if (childIndex < internalNode.data.count) {
                      // try to borrow from right
                      switch (NodeUtil.borrowFromRightLeafChild(internalNode.children, childIndex)) {
                        case (?borrowedKVPair) {
                          let kvPairToBePushedToChild = internalNode.data.kvs[childIndex];
                          internalNode.data.kvs[childIndex] := ?borrowedKVPair;
                          // insert the successor at the very last element
                          let kvDelete = BTreeHelper.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, leafChild.data.count - 1, leafDeleteIndex);
                          return #delete(?kvDelete.1)
                        };
                        // if cannot borrow, from left or right, merge (see below)
                        case _ {}
                      }
                    };

                    // can't borrow from left child, delete from leaf and merge with left child and parent kv, then push down into new leaf
                    let leftChild = switch (internalNode.children[childIndex - 1]) {
                      case (?#leaf(lc)) { lc };
                      case _ {
                        Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.internalDeleteHelper, if trying to borrow from left leaf child is null, then left child index must not be null or internal")
                      }
                    };
                    let (mergedLeaf, deletedKV) = mergeParentWithLeftRightChildLeafNodesAndDelete(
                      internalNode.data.kvs[childIndex - 1],
                      leftChild,
                      leafChild,
                      leafDeleteIndex,
                      #right
                    );
                    // delete the right most internal node kv, since was merging from a deletion in the right most child and the parent kv was pushed into the mergedLeaf
                    ignore BTreeHelper.deleteAndShift<(K, V)>(internalNode.data.kvs, childIndex - 1);
                    // update internal node children
                    BTreeHelper.replaceTwoWithElementAndShift<Node<K, V>>(internalNode.children, #leaf(mergedLeaf), childIndex - 1);
                    internalNode.data.count -= 1;

                    if (internalNode.data.count < minKeys) {
                      #mergeChild({
                        internalChild = internalNode;
                        deletedValue = ?deletedKV.1
                      })
                    } else {
                      #delete(?deletedKV.1)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  };

  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateLeafDeleteResult<K, V> = {
    // element was deleted or not found, returning the old value (?value or null)
    #delete : ?V;
    // leaf had the minimum number of keys when deleting, so returns the leaf node's data and the index of the key that will be deleted
    #mergeLeafData : {
      data : Data<K, V>;
      leafDeleteIndex : Nat
    }
  };

  func leafDeleteHelper<K, V>(leafNode : Leaf<K, V>, order : Nat, compare : (K, K) -> Order.Order, deleteKey : K) : IntermediateLeafDeleteResult<K, V> {
    let minKeys = NodeUtil.minKeysFromOrder(order);

    switch (NodeUtil.getKeyIndex<K, V>(leafNode.data, compare, deleteKey)) {
      case (#keyFound(deleteIndex)) {
        if (leafNode.data.count > minKeys) {
          leafNode.data.count -= 1;
          #delete(?BTreeHelper.deleteAndShift<(K, V)>(leafNode.data.kvs, deleteIndex).1)
        } else {
          #mergeLeafData({
            data = leafNode.data;
            leafDeleteIndex = deleteIndex
          })
        }
      };
      case (#notFound(_)) {
        #delete(null)
      }
    }
  };

  // get helper if internal node
  func getFromInternal<K, V>(internalNode : Internal<K, V>, compare : (K, K) -> Order.Order, key : K) : ?V {
    switch (NodeUtil.getKeyIndex<K, V>(internalNode.data, compare, key)) {
      case (#keyFound(index)) {
        getExistingValueFromIndex(internalNode.data, index)
      };
      case (#notFound(index)) {
        switch (internalNode.children[index]) {
          // expects the child to be there, otherwise there's a bug in binary search or the tree is invalid
          case null { Runtime.trap("Internal bug: Map.getFromInternal") };
          case (?#leaf(leafNode)) { getFromLeaf(leafNode, compare, key) };
          case (?#internal(internalNode)) {
            getFromInternal(internalNode, compare, key)
          }
        }
      }
    }
  };

  // get function helper if leaf node
  func getFromLeaf<K, V>(leafNode : Leaf<K, V>, compare : (K, K) -> Order.Order, key : K) : ?V {
    switch (NodeUtil.getKeyIndex<K, V>(leafNode.data, compare, key)) {
      case (#keyFound(index)) {
        getExistingValueFromIndex(leafNode.data, index)
      };
      case _ null
    }
  };

  // get function helper that retrieves an existing value in the case that the key is found
  func getExistingValueFromIndex<K, V>(data : Data<K, V>, index : Nat) : ?V {
    switch (data.kvs[index]) {
      case null { null };
      case (?ov) { ?ov.1 }
    }
  };

  // which child the deletionIndex is referring to
  type DeletionSide = { #left; #right };

  func mergeParentWithLeftRightChildLeafNodesAndDelete<K, V>(
    parentKV : ?(K, V),
    leftChild : Leaf<K, V>,
    rightChild : Leaf<K, V>,
    deleteIndex : Nat,
    deletionSide : DeletionSide
  ) : (Leaf<K, V>, (K, V)) {
    let count = leftChild.data.count * 2;
    let (kvs, deletedKV) = BTreeHelper.mergeParentWithChildrenAndDelete<(K, V)>(
      parentKV,
      leftChild.data.count,
      leftChild.data.kvs,
      rightChild.data.kvs,
      deleteIndex,
      deletionSide
    );
    (
      {
        data = {
          kvs;
          var count = count
        }
      },
      deletedKV
    )
  };

  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateInsertResult<K, V> = {
    // element was inserted or replaced, returning the old value (?value or null)
    #insert : ?V;
    // child was full when inserting, so returns the promoted kv pair and the split left and right child
    #promote : {
      kv : (K, V);
      leftChild : Node<K, V>;
      rightChild : Node<K, V>
    }
  };

  // Helper for inserting into a leaf node
  func leafInsertHelper<K, V>(leafNode : Leaf<K, V>, order : Nat, compare : (K, K) -> Order.Order, key : K, value : V) : (IntermediateInsertResult<K, V>) {
    // Perform binary search to see if the element exists in the node
    switch (NodeUtil.getKeyIndex<K, V>(leafNode.data, compare, key)) {
      case (#keyFound(insertIndex)) {
        let previous = leafNode.data.kvs[insertIndex];
        leafNode.data.kvs[insertIndex] := ?(key, value);
        switch (previous) {
          case (?ov) { #insert(?ov.1) };
          case null { assert false; #insert(null) }; // the binary search already found an element, so this case should never happen
        }
      };
      case (#notFound(insertIndex)) {
        // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
        let maxKeys : Nat = order - 1;
        // If the leaf is full, insert, split the node, and promote the middle element
        if (leafNode.data.count >= maxKeys) {
          let (leftKVs, promotedParentElement, rightKVs) = BTreeHelper.insertOneAtIndexAndSplitArray(
            leafNode.data.kvs,
            (key, value),
            insertIndex
          );

          let leftCount = order / 2;
          let rightCount : Nat = if (order % 2 == 0) { leftCount - 1 } else {
            leftCount
          };

          (
            #promote({
              kv = promotedParentElement;
              leftChild = createLeaf<K, V>(leftKVs, leftCount);
              rightChild = createLeaf<K, V>(rightKVs, rightCount)
            })
          )
        }
        // Otherwise, insert at the specified index (shifting elements over if necessary)
        else {
          NodeUtil.insertAtIndexOfNonFullNodeData<K, V>(leafNode.data, ?(key, value), insertIndex);
          #insert(null)
        }
      }
    }
  };

  // Helper for inserting into an internal node
  func internalInsertHelper<K, V>(internalNode : Internal<K, V>, order : Nat, compare : (K, K) -> Order.Order, key : K, value : V) : IntermediateInsertResult<K, V> {
    switch (NodeUtil.getKeyIndex<K, V>(internalNode.data, compare, key)) {
      case (#keyFound(insertIndex)) {
        let previous = internalNode.data.kvs[insertIndex];
        internalNode.data.kvs[insertIndex] := ?(key, value);
        switch (previous) {
          case (?ov) { #insert(?ov.1) };
          case null { assert false; #insert(null) }; // the binary search already found an element, so this case should never happen
        }
      };
      case (#notFound(insertIndex)) {
        let insertResult = switch (internalNode.children[insertIndex]) {
          case null { assert false; #insert(null) };
          case (?#leaf(leafNode)) {
            leafInsertHelper(leafNode, order, compare, key, value)
          };
          case (?#internal(internalChildNode)) {
            internalInsertHelper(internalChildNode, order, compare, key, value)
          }
        };

        switch (insertResult) {
          case (#insert(ov)) { #insert(ov) };
          case (#promote({ kv; leftChild; rightChild })) {
            // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
            let maxKeys : Nat = order - 1;
            // if current internal node is full, need to split the internal node
            if (internalNode.data.count >= maxKeys) {
              // insert and split internal kvs, determine new promotion target kv
              let (leftKVs, promotedParentElement, rightKVs) = BTreeHelper.insertOneAtIndexAndSplitArray(
                internalNode.data.kvs,
                (kv),
                insertIndex
              );

              // calculate the element count in the left KVs and the element count in the right KVs
              let leftCount = order / 2;
              let rightCount : Nat = if (order % 2 == 0) { leftCount - 1 } else {
                leftCount
              };

              // split internal children
              let (leftChildren, rightChildren) = NodeUtil.splitChildrenInTwoWithRebalances<K, V>(
                internalNode.children,
                insertIndex,
                leftChild,
                rightChild
              );

              // send the kv to be promoted, as well as the internal children left and right split
              #promote({
                kv = promotedParentElement;
                leftChild = #internal({
                  data = { kvs = leftKVs; var count = leftCount };
                  children = leftChildren
                });
                rightChild = #internal({
                  data = { kvs = rightKVs; var count = rightCount };
                  children = rightChildren
                })
              })
            } else {
              // insert the new kvs into the internal node
              NodeUtil.insertAtIndexOfNonFullNodeData(internalNode.data, ?kv, insertIndex);
              // split and re-insert the single child that needs rebalancing
              NodeUtil.insertRebalancedChild(internalNode.children, insertIndex, leftChild, rightChild);
              #insert(null)
            }
          }
        }
      }
    }
  };

  func createLeaf<K, V>(kvs : [var ?(K, V)], count : Nat) : Node<K, V> {
    #leaf({
      data = {
        kvs;
        var count
      }
    })
  };

  // Additional functionality compared to original source.

  func mapData<K, V1, V2>(data : Data<K, V1>, project : (K, V1) -> V2) : Data<K, V2> {
      { kvs = VarArray.map<?(K, V1), ?(K, V2)>(
         data.kvs,
         func entry {
	   switch entry {
             case (?kv) ?(kv.0, project kv);
	     case null null;
	   }});
        var count = data.count };
  };

  func mapNode<K, V1, V2>(node : Node<K, V1>, project : (K, V1) -> V2) : Node<K, V2> {
    switch node {
      case (#leaf { data }) {
	  #leaf { data = mapData(data, project) }
        };
      case (#internal { data; children }) {
        let mappedData = mapData<K, V1, V2>(data, project);
        let mappedChildren = VarArray.map<?Node<K, V1>, ?Node<K, V2>>(
          children,
          func child {
            switch child {
              case null null;
              case (?childNode) ?mapNode(childNode, project)
            }
          }
        );
        # internal({
          data = mappedData;
          children = mappedChildren
        })
      }
    }
  };

  func cloneNode<K, V>(node : Node<K, V>) : Node<K, V> =
    mapNode<K, V, V>(node, func (k, v) = v);

  module BinarySearch {
    public type SearchResult = {
      #keyFound : Nat;
      #notFound : Nat
    };

    /// Searches an array for a specific key, returning the index it occurs at if #keyFound, or the child/insert index it may occur at
    /// if #notFound. This is used when determining if a key exists in an internal or leaf node, where a key should be inserted in a
    /// leaf node, or which child of an internal node a key could be in.
    ///
    /// Note: This function expects a mutable, nullable, array of keys in sorted order, where all nulls appear at the end of the array.
    /// This function may trap if a null value appears before any values. It also expects a maxIndex, which is the right-most index (bound)
    /// from which to begin the binary search (the left most bound is expected to be 0)
    ///
    /// Parameters:
    ///
    /// * array - the sorted array that the binary search is performed upon
    /// * compare - the comparator used to perform the search
    /// * searchKey - the key being compared against in the search
    /// * maxIndex - the right-most index (bound) from which to begin the search
    public func binarySearchNode<K, V>(array : [var ?(K, V)], compare : (K, K) -> Order.Order, searchKey : K, maxIndex : Nat) : SearchResult {
      // TODO: get rid of this check?
      // Trap if array is size 0 (should not happen)
      if (array.size() == 0) {
        assert false
      };

      // if all elements in the array are null (i.e. first element is null), return #notFound(0)
      if (maxIndex == 0) {
        return #notFound(0)
      };

      // Initialize search from first to last index
      var left : Nat = 0;
      var right = maxIndex; // maxIndex does not necessarily mean array.size() - 1
      // Search the array
      while (left < right) {
        let middle = (left + right) / 2;
        switch (array[middle]) {
          case null { assert false };
          case (?(key, _)) {
            switch (compare(searchKey, key)) {
              // If the element is present at the middle itself
              case (#equal) { return #keyFound(middle) };
              // If element is greater than mid, it can only be present in left subarray
              case (#greater) { left := middle + 1 };
              // If element is smaller than mid, it can only be present in right subarray
              case (#less) {
                right := if (middle == 0) { 0 } else { middle - 1 }
              }
            }
          }
        }
      };

      if (left == array.size()) {
        return #notFound(left)
      };

      // left == right
      switch (array[left]) {
        // inserting at end of array
        case null { #notFound(left) };
        case (?(key, _)) {
          switch (compare(searchKey, key)) {
            // if left is the key
            case (#equal) { #keyFound(left) };
            // if the key is not found, return notFound and the insert location
            case (#greater) { #notFound(left + 1) };
            case (#less) { #notFound(left) }
          }
        }
      }
    }
  };

  module NodeUtil {
    /// Inserts element at the given index into a non-full leaf node
    public func insertAtIndexOfNonFullNodeData<K, V>(data : Data<K, V>, kvPair : ?(K, V), insertIndex : Nat) {
      let currentLastElementIndex : Nat = if (data.count == 0) { 0 } else {
        data.count - 1
      };
      BTreeHelper.insertAtPosition<(K, V)>(data.kvs, kvPair, insertIndex, currentLastElementIndex);

      // increment the count of data in this node since just inserted an element
      data.count += 1
    };

    /// Inserts two rebalanced (split) child halves into a non-full array of children.
    public func insertRebalancedChild<K, V>(children : [var ?Node<K, V>], rebalancedChildIndex : Nat, leftChildInsert : Node<K, V>, rightChildInsert : Node<K, V>) {
      // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
      var j : Nat = children.size() - 2;

      // This is just a sanity check to ensure the children aren't already full (should split promote otherwise)
      // TODO: Remove this check once confident
      if (Option.isSome(children[j + 1])) { assert false };

      // Iterate backwards over the array and shift each element over to the right by one until the rebalancedChildIndex is hit
      while (j > rebalancedChildIndex) {
        children[j + 1] := children[j];
        j -= 1
      };

      // Insert both the left and right rebalanced children (replacing the pre-split child)
      children[j] := ?leftChildInsert;
      children[j + 1] := ?rightChildInsert
    };

    /// Used when splitting the children of an internal node
    ///
    /// Takes in the rebalanced child index, as well as both halves of the rebalanced child and splits the children, inserting the left and right child halves appropriately
    ///
    /// For more context, see the documentation for the splitArrayAndInsertTwo method in BTreeHelper.mo
    public func splitChildrenInTwoWithRebalances<K, V>(
      children : [var ?Node<K, V>],
      rebalancedChildIndex : Nat,
      leftChildInsert : Node<K, V>,
      rightChildInsert : Node<K, V>
    ) : ([var ?Node<K, V>], [var ?Node<K, V>]) {
      BTreeHelper.splitArrayAndInsertTwo<Node<K, V>>(children, rebalancedChildIndex, leftChildInsert, rightChildInsert)
    };

    /// Helper used to get the key index of of a key within a node
    ///
    /// for more, see the BinarySearch.binarySearchNode() documentation
    public func getKeyIndex<K, V>(data : Data<K, V>, compare : (K, K) -> Order.Order, key : K) : BinarySearch.SearchResult {
      BinarySearch.binarySearchNode<K, V>(data.kvs, compare, key, data.count)
    };

    // calculates a BTree Node's minimum allowed keys given the order of the BTree
    public func minKeysFromOrder(order : Nat) : Nat {
      if (order % 2 == 0) { order / 2 - 1 } else { order / 2 }
    };

    // Given a node, get the maximum key value (right most leaf kv)
    public func getMaxKeyValue<K, V>(node : ?Node<K, V>) : (K, V) {
      switch (node) {
        case (?#leaf({ data })) {
          switch (data.kvs[data.count - 1]) {
            case null {
              Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.NodeUtil.getMaxKeyValue, data cannot have more elements than it's count")
            };
            case (?kv) { kv }
          }
        };
        case (?#internal({ data; children })) {
          getMaxKeyValue(children[data.count])
        };
        case null {
          Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.NodeUtil.getMaxKeyValue, the node provided cannot be null")
        }
      }
    };

    type InorderBorrowType = {
      #predecessor;
      #successor
    };

    // attempts to retrieve the in max key of the child leaf node directly to the left if the node will allow it
    // returns the deleted max key if able to retrieve, null if not able
    //
    // mutates the predecessing node's keys
    public func borrowFromLeftLeafChild<K, V>(children : [var ?Node<K, V>], ofChildIndex : Nat) : ?(K, V) {
      let predecessorIndex : Nat = ofChildIndex - 1;
      borrowFromLeafChild(children, predecessorIndex, #predecessor)
    };

    // attempts to retrieve the in max key of the child leaf node directly to the right if the node will allow it
    // returns the deleted max key if able to retrieve, null if not able
    //
    // mutates the predecessing node's keys
    public func borrowFromRightLeafChild<K, V>(children : [var ?Node<K, V>], ofChildIndex : Nat) : ?(K, V) {
      borrowFromLeafChild(children, ofChildIndex + 1, #successor)
    };

    func borrowFromLeafChild<K, V>(children : [var ?Node<K, V>], borrowChildIndex : Nat, childSide : InorderBorrowType) : ?(K, V) {
      let minKeys = minKeysFromOrder(children.size());

      switch (children[borrowChildIndex]) {
        case (?#leaf({ data })) {
          if (data.count > minKeys) {
            // able to borrow a key-value from this child, so decrement the count of kvs
            data.count -= 1; // Since enforce order >= 4, there will always be at least 1 element per node
            switch (childSide) {
              case (#predecessor) {
                let deletedKV = data.kvs[data.count];
                data.kvs[data.count] := null;
                deletedKV
              };
              case (#successor) {
                ?BTreeHelper.deleteAndShift(data.kvs, 0)
              }
            }
          } else { null }
        };
        case _ {
          Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.NodeUtil.borrowFromLeafChild, the node at the borrow child index cannot be null or internal")
        }
      }
    };

    type InternalBorrowResult<K, V> = {
      #borrowed : InternalBorrow<K, V>;
      #notEnoughKeys : Internal<K, V>
    };

    type InternalBorrow<K, V> = {
      deletedSiblingKVPair : ?(K, V);
      child : ?Node<K, V>
    };

    // Attempts to borrow a KV and child from an internal sibling node
    public func borrowFromInternalSibling<K, V>(children : [var ?Node<K, V>], borrowChildIndex : Nat, borrowType : InorderBorrowType) : InternalBorrowResult<K, V> {
      let minKeys = minKeysFromOrder(children.size());

      switch (children[borrowChildIndex]) {
        case (?#internal({ data; children })) {
          if (data.count > minKeys) {
            data.count -= 1;
            switch (borrowType) {
              case (#predecessor) {
                let deletedSiblingKVPair = data.kvs[data.count];
                data.kvs[data.count] := null;
                let child = children[data.count + 1];
                children[data.count + 1] := null;
                #borrowed({
                  deletedSiblingKVPair;
                  child
                })
              };
              case (#successor) {
                #borrowed({
                  deletedSiblingKVPair = ?BTreeHelper.deleteAndShift(data.kvs, 0);
                  child = ?BTreeHelper.deleteAndShift(children, 0)
                })
              }
            }
          } else { #notEnoughKeys({ data; children }) }
        };
        case _ {
          Runtime.trap("UNREACHABLE_ERROR: file a bug report! In Map.NodeUtil.borrowFromInternalSibling from internal sibling, the child at the borrow index cannot be null or a leaf")
        }
      }
    };

    type SiblingSide = { #left; #right };

    // Rotates the borrowed KV and child from sibling side of the internal node to the internal child recipient
    public func rotateBorrowedKVsAndChildFromSibling<K, V>(
      internalNode : Internal<K, V>,
      parentRotateIndex : Nat,
      borrowedSiblingKVPair : ?(K, V),
      borrowedSiblingChild : ?Node<K, V>,
      internalChildRecipient : Internal<K, V>,
      siblingSide : SiblingSide
    ) {
      // if borrowing from the left, the rotated key and child will always be inserted first
      // if borrowing from the right, the rotated key and child will always be inserted last
      let (kvIndex, childIndex) = switch (siblingSide) {
        case (#left) { (0, 0) };
        case (#right) {
          (internalChildRecipient.data.count, internalChildRecipient.data.count + 1)
        }
      };

      // get the parent kv that will be pushed down the the child
      let kvPairToBePushedToChild = internalNode.data.kvs[parentRotateIndex];
      // replace the parent with the sibling kv
      internalNode.data.kvs[parentRotateIndex] := borrowedSiblingKVPair;
      // push the kv and child down into the internalChild
      insertAtIndexOfNonFullNodeData<K, V>(internalChildRecipient.data, kvPairToBePushedToChild, kvIndex);

      BTreeHelper.insertAtPosition<Node<K, V>>(internalChildRecipient.children, borrowedSiblingChild, childIndex, internalChildRecipient.data.count)
    };

    // Merges the kvs and children of two internal nodes, pushing the parent kv in between the right and left halves
    public func mergeChildrenAndPushDownParent<K, V>(leftChild : Internal<K, V>, parentKV : ?(K, V), rightChild : Internal<K, V>) : Internal<K, V> {
      {
        data = mergeData<K, V>(leftChild.data, parentKV, rightChild.data);
        children = mergeChildren(leftChild.children, rightChild.children)
      }
    };

    func mergeData<K, V>(leftData : Data<K, V>, parentKV : ?(K, V), rightData : Data<K, V>) : Data<K, V> {
      assert leftData.count <= minKeysFromOrder(leftData.kvs.size() + 1);
      assert rightData.count <= minKeysFromOrder(rightData.kvs.size() + 1);

      let mergedKVs = VarArray.repeat<?(K, V)>(null, leftData.kvs.size());
      var i = 0;
      while (i < leftData.count) {
        mergedKVs[i] := leftData.kvs[i];
        i += 1
      };

      mergedKVs[i] := parentKV;
      i += 1;

      var j = 0;
      while (j < rightData.count) {
        mergedKVs[i] := rightData.kvs[j];
        i += 1;
        j += 1
      };

      {
        kvs = mergedKVs;
        var count = leftData.count + 1 + rightData.count
      }
    };

    func mergeChildren<K, V>(leftChildren : [var ?Node<K, V>], rightChildren : [var ?Node<K, V>]) : [var ?Node<K, V>] {
      let mergedChildren = VarArray.repeat<?Node<K, V>>(null, leftChildren.size());
      var i = 0;

      while (Option.isSome(leftChildren[i])) {
        mergedChildren[i] := leftChildren[i];
        i += 1
      };

      var j = 0;
      while (Option.isSome(rightChildren[j])) {
        mergedChildren[i] := rightChildren[j];
        i += 1;
        j += 1
      };

      mergedChildren
    }
  }
}
