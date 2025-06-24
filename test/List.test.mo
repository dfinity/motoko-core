import Suite "mo:matchers/Suite";
import T "mo:matchers/Testable";
import M "mo:matchers/Matchers";
import Test "mo:test";

import Prim "mo:⛔";
import Iter "../src/Iter";
import Array "../src/Array";
import Nat32 "../src/Nat32";
import Nat "../src/Nat";
import Order "../src/Order";
import List "../src/List";
import Runtime "../src/Runtime";
import Int "../src/Int";
import Debug "../src/Debug";
import { Tuple2 } "../src/Tuples";
import PureList "../src/pure/List";

let { run; test; suite } = Suite;

func unwrap<T>(x : ?T) : T = switch (x) {
  case (?v) v;
  case (_) Prim.trap "internal error in unwrap()"
};

let n = 100;
var list = List.empty<Nat>();

let sizes = List.empty<Nat>();
for (i in Nat.rangeInclusive(0, n)) {
  List.add(sizes, List.size(list));
  List.add(list, i)
};
List.add(sizes, List.size(list));

class OrderTestable(initItem : Order.Order) : T.TestableItem<Order.Order> {
  public let item = initItem;
  public func display(order : Order.Order) : Text {
    switch (order) {
      case (#less) {
        "#less"
      };
      case (#greater) {
        "#greater"
      };
      case (#equal) {
        "#equal"
      }
    }
  };
  public let equals = Order.equal
};

run(
  suite(
    "clone",
    [
      test(
        "clone",
        List.toArray(List.clone(list)),
        M.equals(T.array(T.natTestable, List.toArray(list)))
      )
    ]
  )
);

run(
  suite(
    "add",
    [
      test(
        "sizes",
        List.toArray(sizes),
        M.equals(T.array(T.natTestable, Iter.toArray(Nat.rangeInclusive(0, n + 1))))
      ),
      test(
        "elements",
        List.toArray(list),
        M.equals(T.array(T.natTestable, Iter.toArray(Nat.rangeInclusive(0, n))))
      )
    ]
  )
);

assert List.find(list, func(a : Nat) : Bool = a == 123456) == null;
assert List.find(list, func(a : Nat) : Bool = a == 0) == ?0;

assert List.indexOf(list, Nat.equal, n + 1) == null;
assert List.findIndex(list, func(a : Nat) : Bool = a == n + 1) == null;
assert List.indexOf(list, Nat.equal, n) == ?n;
assert List.findIndex(list, func(a : Nat) : Bool = a == n) == ?n;

assert List.lastIndexOf(list, Nat.equal, n + 1) == null;
assert List.findLastIndex(list, func(a : Nat) : Bool = a == n + 1) == null;

assert List.lastIndexOf(list, Nat.equal, 0) == ?0;
assert List.findLastIndex(list, func(a : Nat) : Bool = a == 0) == ?0;

assert List.all(list, func(x : Nat) : Bool = 0 <= x and x <= n);
assert List.any(list, func(x : Nat) : Bool = x == n / 2);

run(
  suite(
    "iterator",
    [
      test(
        "values",
        Iter.toArray(List.values(list)),
        M.equals(T.array(T.natTestable, Iter.toArray(Nat.rangeInclusive(0, n))))
      ),
      test(
        "reverseValues",
        Iter.toArray(List.reverseValues(list)),
        M.equals(T.array(T.natTestable, Iter.toArray(Iter.reverse(Nat.rangeInclusive(0, n)))))
      ),
      test(
        "keys",
        Iter.toArray(List.keys(list)),
        M.equals(T.array(T.natTestable, Iter.toArray(Nat.rangeInclusive(0, n))))
      ),
      test(
        "enumerate1",
        Iter.toArray(Iter.map<(Nat, Nat), Nat>(List.enumerate(list), func((a, b)) { b })),
        M.equals(T.array(T.natTestable, Iter.toArray(Nat.rangeInclusive(0, n))))
      ),
      test(
        "enumerate2",
        Iter.toArray(Iter.map<(Nat, Nat), Nat>(List.enumerate(list), func((a, b)) { a })),
        M.equals(T.array(T.natTestable, Iter.toArray(Nat.rangeInclusive(0, n))))
      ),
      test(
        "reverseEnumerate1",
        Iter.toArray(Iter.map<(Nat, Nat), Nat>(List.reverseEnumerate(list), func((a, b)) { b })),
        M.equals(T.array(T.natTestable, Iter.toArray(Iter.reverse(Nat.rangeInclusive(0, n)))))
      ),
      test(
        "reverseEnumerate2",
        Iter.toArray(Iter.map<(Nat, Nat), Nat>(List.reverseEnumerate(list), func((a, b)) { a })),
        M.equals(T.array(T.natTestable, Iter.toArray(Iter.reverse(Nat.rangeInclusive(0, n)))))
      )
    ]
  )
);

let for_add_many = List.repeat<Nat>(0, n);
List.addRepeat(for_add_many, 0, n);

let for_add_iter = List.repeat<Nat>(0, n);
List.addAll(for_add_iter, Iter.repeat<Nat>(0, n));

run(
  suite(
    "init",
    [
      test(
        "init with toArray",
        List.toArray(List.repeat<Nat>(0, n)),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(n, func(_) = 0)))
      ),
      test(
        "init with values",
        Iter.toArray(List.values(List.repeat<Nat>(0, n))),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(n, func(_) = 0)))
      ),
      test(
        "add many with toArray",
        List.toArray(for_add_many),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(2 * n, func(_) = 0)))
      ),
      test(
        "add many with vals",
        Iter.toArray(List.values(for_add_many)),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(2 * n, func(_) = 0)))
      ),
      test(
        "addFromIter",
        List.toArray(for_add_iter),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(2 * n, func(_) = 0)))
      )
    ]
  )
);

for (i in Nat.rangeInclusive(0, n)) {
  List.put(list, i, n - i : Nat)
};

run(
  suite(
    "put",
    [
      test(
        "size",
        List.size(list),
        M.equals(T.nat(n + 1))
      ),
      test(
        "elements",
        List.toArray(list),
        M.equals(T.array(T.natTestable, Iter.toArray(Iter.reverse(Nat.rangeInclusive(0, n)))))
      )
    ]
  )
);

let removed = List.empty<Nat>();
for (i in Nat.rangeInclusive(0, n)) {
  List.add(removed, unwrap(List.removeLast(list)))
};

let empty = List.empty<Nat>();
let emptied = List.singleton<Nat>(0);
let _ = List.removeLast(emptied);

run(
  suite(
    "removeLast",
    [
      test(
        "size",
        List.size(list),
        M.equals(T.nat(0))
      ),
      test(
        "elements",
        List.toArray(removed),
        M.equals(T.array(T.natTestable, Iter.toArray(Nat.rangeInclusive(0, n))))
      ),
      test(
        "empty",
        List.removeLast(List.empty<Nat>()),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      ),
      test(
        "emptied",
        List.removeLast(emptied),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      )
    ]
  )
);

// Test last and first
assert List.last(list) == null;
assert List.first(list) == null;

for (i in Nat.rangeInclusive(0, n)) {
  List.add(list, i);
  assert List.last(list) == ?i;
  assert List.first(list) == ?0
};

run(
  suite(
    "addAfterRemove",
    [
      test(
        "elements",
        List.toArray(list),
        M.equals(T.array(T.natTestable, Iter.toArray(Nat.rangeInclusive(0, n))))
      )
    ]
  )
);

run(
  suite(
    "firstAndLast",
    [
      test(
        "first",
        List.first(list),
        M.equals(T.optional(T.natTestable, ?0))
      ),
      test(
        "first empty",
        List.first(empty),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      ),
      test(
        "first emptied",
        List.first(emptied),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      ),
      test(
        "last of len N",
        List.last(list),
        M.equals(T.optional(T.natTestable, ?n))
      ),
      test(
        "last of len 1",
        List.last(List.repeat<Nat>(1, 1)),
        M.equals(T.optional(T.natTestable, ?1))
      ),
      test(
        "last of 6",
        List.last(List.fromArray<Nat>([0, 1, 2, 3, 4, 5])),
        M.equals(T.optional(T.natTestable, ?5))
      ),
      test(
        "last empty",
        List.last(List.empty<Nat>()),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      ),
      test(
        "last emptied",
        List.last(emptied),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      )
    ]
  )
);

Test.suite(
  "empty vs emptied",
  func() {
    Test.test(
      "empty",
      func() {
        Test.expect.nat(empty.blockIndex).equal(1);
        Test.expect.nat(empty.elementIndex).equal(0);
        Test.expect.bool(empty.blocks.size() == 1).equal(true)
      }
    );
    Test.test(
      "emptied",
      func() {
        Test.expect.nat(emptied.blockIndex).equal(1);
        Test.expect.nat(emptied.elementIndex).equal(0);
        Test.expect.bool(emptied.blocks.size() > 1).equal(true)
      }
    )
  }
);

var sumN = 0;
List.forEach<Nat>(list, func(i) { sumN += i });
var sumRev = 0;
List.reverseForEach<Nat>(list, func(i) { sumRev += i });
var sum1 = 0;
List.forEach<Nat>(List.repeat<Nat>(1, 1), func(i) { sum1 += i });
var sum0 = 0;
List.forEach<Nat>(List.empty<Nat>(), func(i) { sum0 += i });

run(
  suite(
    "iterate",
    [
      test(
        "sumN",
        [sumN],
        M.equals(T.array(T.natTestable, [n * (n + 1) / 2]))
      ),
      test(
        "sumRev",
        [sumRev],
        M.equals(T.array(T.natTestable, [n * (n + 1) / 2]))
      ),
      test(
        "sum1",
        [sum1],
        M.equals(T.array(T.natTestable, [1]))
      ),
      test(
        "sum0",
        [sum0],
        M.equals(T.array(T.natTestable, [0]))
      )
    ]
  )
);

/* --------------------------------------- */

var sumItems = 0;
List.forEachEntry<Nat>(list, func(i, x) { sumItems += i + x });
var sumItemsRev = 0;
List.forEachEntry<Nat>(list, func(i, x) { sumItemsRev += i + x });

run(
  suite(
    "iterateItems",
    [
      test(
        "sumItems",
        [sumItems],
        M.equals(T.array(T.natTestable, [n * (n + 1)]))
      ),
      test(
        "sumItemsRev",
        [sumItemsRev],
        M.equals(T.array(T.natTestable, [n * (n + 1)]))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5]);

run(
  suite(
    "contains",
    [
      test(
        "true",
        List.contains<Nat>(list, Nat.equal, 2),
        M.equals(T.bool(true))
      ),
      test(
        "true",
        List.contains<Nat>(list, Nat.equal, 9),
        M.equals(T.bool(false))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.empty<Nat>();

run(
  suite(
    "contains empty",
    [
      test(
        "true",
        List.contains<Nat>(list, Nat.equal, 2),
        M.equals(T.bool(false))
      ),
      test(
        "true",
        List.contains<Nat>(list, Nat.equal, 9),
        M.equals(T.bool(false))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([2, 1, 10, 1, 0, 3]);

run(
  suite(
    "max",
    [
      test(
        "return value",
        List.max<Nat>(list, Nat.compare),
        M.equals(T.optional(T.natTestable, ?10))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([2, 1, 10, 1, 0, 3, 0]);

run(
  suite(
    "min",
    [
      test(
        "return value",
        List.min<Nat>(list, Nat.compare),
        M.equals(T.optional(T.natTestable, ?0))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5]);

var list2 = List.fromArray<Nat>([0, 1, 2]);

run(
  suite(
    "equal",
    [
      test(
        "empty lists",
        List.equal<Nat>(List.empty<Nat>(), List.empty<Nat>(), Nat.equal),
        M.equals(T.bool(true))
      ),
      test(
        "non-empty lists",
        List.equal<Nat>(list, List.clone(list), Nat.equal),
        M.equals(T.bool(true))
      ),
      test(
        "non-empty and empty lists",
        List.equal<Nat>(list, List.empty<Nat>(), Nat.equal),
        M.equals(T.bool(false))
      ),
      test(
        "non-empty lists mismatching lengths",
        List.equal<Nat>(list, list2, Nat.equal),
        M.equals(T.bool(false))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5]);
list2 := List.fromArray<Nat>([0, 1, 2]);

var list3 = List.fromArray<Nat>([2, 3, 4, 5]);

run(
  suite(
    "compare",
    [
      test(
        "empty lists",
        List.compare<Nat>(List.empty<Nat>(), List.empty<Nat>(), Nat.compare),
        M.equals(OrderTestable(#equal))
      ),
      test(
        "non-empty lists equal",
        List.compare<Nat>(list, List.clone(list), Nat.compare),
        M.equals(OrderTestable(#equal))
      ),
      test(
        "non-empty and empty lists",
        List.compare<Nat>(list, List.empty<Nat>(), Nat.compare),
        M.equals(OrderTestable(#greater))
      ),
      test(
        "non-empty lists mismatching lengths",
        List.compare<Nat>(list, list2, Nat.compare),
        M.equals(OrderTestable(#greater))
      ),
      test(
        "non-empty lists lexicographic difference",
        List.compare<Nat>(list, list3, Nat.compare),
        M.equals(OrderTestable(#less))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5]);

run(
  suite(
    "toText",
    [
      test(
        "empty list",
        List.toText<Nat>(List.empty<Nat>(), Nat.toText),
        M.equals(T.text("List[]"))
      ),
      test(
        "singleton list",
        List.toText<Nat>(List.singleton<Nat>(3), Nat.toText),
        M.equals(T.text("List[3]"))
      ),
      test(
        "non-empty list",
        List.toText<Nat>(list, Nat.toText),
        M.equals(T.text("List[0, 1, 2, 3, 4, 5]"))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6, 7]);
list2 := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6]);
list3 := List.empty<Nat>();

var list4 = List.singleton<Nat>(3);

List.reverseInPlace<Nat>(list);
List.reverseInPlace<Nat>(list2);
List.reverseInPlace<Nat>(list3);
List.reverseInPlace<Nat>(list4);

run(
  suite(
    "reverseInPlace",
    [
      test(
        "even elements",
        List.toArray(list),
        M.equals(T.array(T.natTestable, [7, 6, 5, 4, 3, 2, 1, 0]))
      ),
      test(
        "odd elements",
        List.toArray(list2),
        M.equals(T.array(T.natTestable, [6, 5, 4, 3, 2, 1, 0]))
      ),
      test(
        "empty",
        List.toArray(list3),
        M.equals(T.array(T.natTestable, [] : [Nat]))
      ),
      test(
        "singleton",
        List.toArray(list4),
        M.equals(T.array(T.natTestable, [3]))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.reverse<Nat>(List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6, 7]));
list2 := List.reverse<Nat>(List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6]));
list3 := List.reverse<Nat>(List.empty<Nat>());
list4 := List.reverse<Nat>(List.singleton<Nat>(3));

run(
  suite(
    "reverse",
    [
      test(
        "even elements",
        List.toArray(list),
        M.equals(T.array(T.natTestable, [7, 6, 5, 4, 3, 2, 1, 0]))
      ),
      test(
        "odd elements",
        List.toArray(list2),
        M.equals(T.array(T.natTestable, [6, 5, 4, 3, 2, 1, 0]))
      ),
      test(
        "empty",
        List.toArray(list3),
        M.equals(T.array(T.natTestable, [] : [Nat]))
      ),
      test(
        "singleton",
        List.toArray(list4),
        M.equals(T.array(T.natTestable, [3]))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6]);

run(
  suite(
    "foldLeft",
    [
      test(
        "return value",
        List.foldLeft<Text, Nat>(list, "", func(acc, x) = acc # Nat.toText(x)),
        M.equals(T.text("0123456"))
      ),
      test(
        "return value empty",
        List.foldLeft<Text, Nat>(List.empty<Nat>(), "", func(acc, x) = acc # Nat.toText(x)),
        M.equals(T.text(""))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6]);

run(
  suite(
    "foldRight",
    [
      test(
        "return value",
        List.foldRight<Nat, Text>(list, "", func(x, acc) = acc # Nat.toText(x)),
        M.equals(T.text("6543210"))
      ),
      test(
        "return value empty",
        List.foldRight<Nat, Text>(List.empty<Nat>(), "", func(x, acc) = acc # Nat.toText(x)),
        M.equals(T.text(""))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.singleton<Nat>(2);

run(
  suite(
    "isEmpty",
    [
      test(
        "true",
        List.isEmpty(List.empty<Nat>()),
        M.equals(T.bool(true))
      ),
      test(
        "false",
        List.isEmpty(list),
        M.equals(T.bool(false))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6]);

run(
  suite(
    "map",
    [
      test(
        "map",
        List.toArray(List.map<Nat, Text>(list, Nat.toText)),
        M.equals(T.array(T.textTestable, ["0", "1", "2", "3", "4", "5", "6"]))
      ),
      test(
        "empty",
        List.isEmpty(List.map<Nat, Text>(List.empty<Nat>(), Nat.toText)),
        M.equals(T.bool(true))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6]);

run(
  suite(
    "filter",
    [
      test(
        "filter evens",
        List.toArray(List.filter<Nat>(list, func x = x % 2 == 0)),
        M.equals(T.array(T.natTestable, [0, 2, 4, 6]))
      ),
      test(
        "filter none",
        List.toArray(List.filter<Nat>(list, func _ = false)),
        M.equals(T.array(T.natTestable, [] : [Nat]))
      ),
      test(
        "filter all",
        List.toArray(List.filter<Nat>(list, func _ = true)),
        M.equals(T.array(T.natTestable, [0, 1, 2, 3, 4, 5, 6]))
      ),
      test(
        "filter empty",
        List.isEmpty(List.filter<Nat>(List.empty<Nat>(), func _ = true)),
        M.equals(T.bool(true))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6]);

run(
  suite(
    "filterMap",
    [
      test(
        "filterMap double evens",
        List.toArray(List.filterMap<Nat, Nat>(list, func x = if (x % 2 == 0) ?(x * 2) else null)),
        M.equals(T.array(T.natTestable, [0, 4, 8, 12]))
      ),
      test(
        "filterMap none",
        List.toArray(List.filterMap<Nat, Nat>(list, func _ = null)),
        M.equals(T.array(T.natTestable, [] : [Nat]))
      ),
      test(
        "filterMap all",
        List.toArray(List.filterMap<Nat, Text>(list, func x = ?(Nat.toText(x)))),
        M.equals(T.array(T.textTestable, ["0", "1", "2", "3", "4", "5", "6"]))
      ),
      test(
        "filterMap empty",
        List.isEmpty(List.filterMap<Nat, Nat>(List.empty<Nat>(), func x = ?x)),
        M.equals(T.bool(true))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([8, 6, 9, 10, 0, 4, 2, 3, 7, 1, 5]);

run(
  suite(
    "sort",
    [
      test(
        "sort",
        List.sort<Nat>(list, Nat.compare) |> List.toArray(list),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] |> M.equals(T.array(T.natTestable, _))
      )
    ]
  )
);

/* --------------------------------------- */

func locate_readable<X>(index : Nat) : (Nat, Nat) {
  // index is any Nat32 except for
  // blocks before super block s == 2 ** s
  let i = Nat32.fromNat(index);
  // element with index 0 located in data block with index 1
  if (i == 0) {
    return (1, 0)
  };
  let lz = Nat32.bitcountLeadingZero(i);
  // super block s = bit length - 1 = (32 - leading zeros) - 1
  // i in binary = zeroes; 1; bits blocks mask; bits element mask
  // bit lengths =     lz; 1;     floor(s / 2);       ceil(s / 2)
  let s = 31 - lz;
  // floor(s / 2)
  let down = s >> 1;
  // ceil(s / 2) = floor((s + 1) / 2)
  let up = (s + 1) >> 1;
  // element mask = ceil(s / 2) ones in binary
  let e_mask = 1 << up - 1;
  //block mask = floor(s / 2) ones in binary
  let b_mask = 1 << down - 1;
  // data blocks in even super blocks before current = 2 ** ceil(s / 2)
  // data blocks in odd super blocks before current = 2 ** floor(s / 2)
  // data blocks before the super block = element mask + block mask
  // elements before the super block = 2 ** s
  // first floor(s / 2) bits in index after the highest bit = index of data block in super block
  // the next ceil(s / 2) to the end of binary representation of index + 1 = index of element in data block
  (Nat32.toNat(e_mask + b_mask + 2 + (i >> up) & b_mask), Nat32.toNat(i & e_mask))
};

// this was optimized in terms of instructions
func locate_optimal<X>(index : Nat) : (Nat, Nat) {
  // super block s = bit length - 1 = (32 - leading zeros) - 1
  // blocks before super block s == 2 ** s
  let i = Nat32.fromNat(index);
  let lz = Nat32.bitcountLeadingZero(i);
  let lz2 = lz >> 1;
  // we split into cases to apply different optimizations in each one
  if (lz & 1 == 0) {
    // ceil(s / 2)  = 16 - lz2
    // floor(s / 2) = 15 - lz2
    // i in binary = zeroes; 1; bits blocks mask; bits element mask
    // bit lengths =     lz; 1;         15 - lz2;          16 - lz2
    // blocks before = 2 ** ceil(s / 2) + 2 ** floor(s / 2)

    // so in order to calculate index of the data block
    // we need to shift i by 16 - lz2 and set bit with number 16 - lz2, bit 15 - lz2 is already set

    // element mask = 2 ** (16 - lz2) = (1 << 16) >> lz2 = 0xFFFF >> lz2
    let mask = 0xFFFF >> lz2;
    (Nat32.toNat(((i << lz2) >> 16) ^ (0x10000 >> lz2)), Nat32.toNat(i & mask))
  } else {
    // s / 2 = ceil(s / 2) = floor(s / 2) = 15 - lz2
    // i in binary = zeroes; 1; bits blocks mask; bits element mask
    // bit lengths =     lz; 1;         15 - lz2;          15 - lz2
    // block mask = element mask = mask = 2 ** (s / 2) - 1 = 2 ** (15 - lz2) - 1 = (1 << 15) >> lz2 = 0x7FFF >> lz2
    // blocks before = 2 * 2 ** (s / 2)

    // so in order to calculate index of the data block
    // we need to shift i by 15 - lz2, set bit with number 16 - lz2 and unset bit 15 - lz2

    let mask = 0x7FFF >> lz2;
    (Nat32.toNat(((i << lz2) >> 15) ^ (0x18000 >> lz2)), Nat32.toNat(i & mask))
  }
};

let locate_n = 1_000;
var i = 0;
while (i < locate_n) {
  assert (locate_readable(i) == locate_optimal(i));
  assert (locate_readable(1_000_000 + i) == locate_optimal(1_000_000 + i));
  assert (locate_readable(1_000_000_000 + i) == locate_optimal(1_000_000_000 + i));
  assert (locate_readable(2_000_000_000 + i) == locate_optimal(2_000_000_000 + i));
  assert (locate_readable(2 ** 32 - 1 - i : Nat) == locate_optimal(2 ** 32 - 1 - i : Nat));
  i += 1
};

// Claude tests (from original Mops package)

// Helper function to run tests
func runTest(name : Text, test : (Nat) -> Bool) {
  let testSizes = [0, 1, 10, 100];
  for (n in testSizes.vals()) {
    if (test(n)) {
      Debug.print("✅ " # name # " passed for n = " # Nat.toText(n))
    } else {
      Runtime.trap("❌ " # name # " failed for n = " # Nat.toText(n))
    }
  }
};

// Test cases
func testNew(n : Nat) : Bool {
  let vec = List.empty<Nat>();
  List.size(vec) == 0
};

func testInit(n : Nat) : Bool {
  let vec = List.repeat<Nat>(1, n);
  List.size(vec) == n and (n == 0 or (List.get(vec, 0) == 1 and List.get(vec, n - 1 : Nat) == 1))
};

func testAdd(n : Nat) : Bool {
  if (n == 0) return true;
  let vec = List.empty<Nat>();
  for (i in Nat.range(0, n)) {
    List.add(vec, i)
  };

  if (List.size(vec) != n) {
    Debug.print("Size mismatch: expected " # Nat.toText(n) # ", got " # Nat.toText(List.size(vec)));
    return false
  };

  for (i in Nat.range(0, n)) {
    let value = List.get(vec, i);
    if (value != i) {
      Debug.print("Value mismatch at index " # Nat.toText(i) # ": expected " # Nat.toText(i) # ", got " # Nat.toText(value));
      return false
    }
  };

  true
};

func testAddAll(n : Nat) : Bool {
  if (n == 0) return true;
  let vec = List.repeat<Nat>(0, n);
  List.addRepeat(vec, 1, n);
  if (List.size(vec) != 2 * n) {
    Debug.print("Size mismatch: expected " # Nat.toText(2 * n) # ", got " # Nat.toText(List.size(vec)));
    return false
  };
  for (i in Nat.range(0, n)) {
    let value = List.get(vec, n + i);
    if (value != 1) {
      Debug.print("Value mismatch at index " # Nat.toText(i) # ": expected " # Nat.toText(1) # ", got " # Nat.toText(value));
      return false
    }
  };
  true
};

func testRemoveLast(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  var i = n;

  while (i > 0) {
    i -= 1;
    let last = List.removeLast(vec);
    if (last != ?i) {
      Debug.print("Unexpected value removed: expected ?" # Nat.toText(i) # ", got " # debug_show (last));
      return false
    };
    if (List.size(vec) != i) {
      Debug.print("Unexpected size after removal: expected " # Nat.toText(i) # ", got " # Nat.toText(List.size(vec)));
      return false
    }
  };

  // Try to remove from empty vector
  if (List.removeLast(vec) != null) {
    Debug.print("Expected null when removing from empty vector, but got a value");
    return false
  };

  if (List.size(vec) != 0) {
    Debug.print("List should be empty, but has size " # Nat.toText(List.size(vec)));
    return false
  };

  true
};

func testGet(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));

  for (i in Nat.range(1, n + 1)) {
    let value = List.get(vec, i - 1 : Nat);
    if (value != i) {
      Debug.print("get: Mismatch at index " # Nat.toText(i) # ": expected " # Nat.toText(i) # ", got " # Nat.toText(value));
      return false
    }
  };

  true
};

func testGetOpt(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));

  for (i in Nat.range(1, n + 1)) {
    switch (List.getOpt(vec, i - 1 : Nat)) {
      case (?value) {
        if (value != i) {
          Debug.print("getOpt: Mismatch at index " # Nat.toText(i) # ": expected ?" # Nat.toText(i) # ", got ?" # Nat.toText(value));
          return false
        }
      };
      case (null) {
        Debug.print("getOpt: Unexpected null at index " # Nat.toText(i));
        return false
      }
    }
  };

  // Test out-of-bounds access
  switch (List.getOpt(vec, n)) {
    case (null) {
      // This is expected
    };
    case (?value) {
      Debug.print("getOpt: Expected null for out-of-bounds access, got ?" # Nat.toText(value));
      return false
    }
  };

  true
};

func testPut(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  if (n == 0) {
    true
  } else {
    List.put(vec, n - 1 : Nat, 100);
    List.get(vec, n - 1 : Nat) == 100
  }
};

func testClear(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  List.clear(vec);
  List.size(vec) == 0
};

func testClone(n : Nat) : Bool {
  let vec1 = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  let vec2 = List.clone(vec1);
  List.equal(vec1, vec2, Nat.equal)
};

func testMap(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  let mapped = List.map<Nat, Nat>(vec, func(x) = x * 2);
  List.equal(mapped, List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i * 2)), Nat.equal)
};

func testIndexOf(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(2 * n, func(i) = i % n));
  if (n == 0) {
    List.indexOf(vec, Nat.equal, 0) == null
  } else {
    var allCorrect = true;
    for (i in Nat.range(0, n)) {
      let index = List.indexOf(vec, Nat.equal, i);
      if (index != ?i) {
        allCorrect := false;
        Debug.print("indexOf failed for i = " # Nat.toText(i) # ", expected ?" # Nat.toText(i) # ", got " # debug_show (index))
      }
    };
    allCorrect and List.indexOf(vec, Nat.equal, n) == null
  }
};

func testLastIndexOf(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(2 * n, func(i) = i % n));
  if (n == 0) {
    List.lastIndexOf(vec, Nat.equal, 0) == null
  } else {
    var allCorrect = true;
    for (i in Nat.range(0, n)) {
      let index = List.lastIndexOf(vec, Nat.equal, i);
      if (index != ?(n + i)) {
        allCorrect := false;
        Debug.print("lastIndexOf failed for i = " # Nat.toText(i) # ", expected ?" # Nat.toText(n + i) # ", got " # debug_show (index))
      }
    };
    allCorrect and List.lastIndexOf(vec, Nat.equal, n) == null
  }
};

func testContains(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));

  // Check if it contains all elements from 0 to n-1
  for (i in Nat.range(1, n + 1)) {
    if (not List.contains(vec, Nat.equal, i)) {
      Debug.print("List should contain " # Nat.toText(i) # " but it doesn't");
      return false
    }
  };

  // Check if it doesn't contain n (which should be out of range)
  if (List.contains(vec, Nat.equal, n + 1)) {
    Debug.print("List shouldn't contain " # Nat.toText(n + 1) # " but it does");
    return false
  };

  // Check if it doesn't contain n+1 (another out of range value)
  if (List.contains(vec, Nat.equal, n + 2)) {
    Debug.print("List shouldn't contain " # Nat.toText(n + 2) # " but it does");
    return false
  };

  true
};
func testReverse(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  List.reverseInPlace(vec);
  List.equal(vec, List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = n - 1 - i)), Nat.equal)
};

func testSort(n : Nat) : Bool {
  let vec = List.fromArray<Int>(Array.tabulate<Int>(n, func(i) = (i * 123) % 100 - 50));
  List.sort(vec, Int.compare);
  List.equal(vec, List.fromArray<Int>(Array.sort(Array.tabulate<Int>(n, func(i) = (i * 123) % 100 - 50), Int.compare)), Int.equal)
};

func testToArray(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  Array.equal(List.toArray(vec), Array.tabulate<Nat>(n, func(i) = i), Nat.equal)
};

func testFromIter(n : Nat) : Bool {
  let iter = Nat.range(1, n + 1);
  let vec = List.fromIter<Nat>(iter);
  List.equal(vec, List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1)), Nat.equal)
};

func testFoldLeft(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));
  List.foldLeft<Text, Nat>(vec, "", func(acc, x) = acc # Nat.toText(x)) == Array.foldLeft<Nat, Text>(Array.tabulate<Nat>(n, func(i) = i + 1), "", func(acc, x) = acc # Nat.toText(x))
};

func testFoldRight(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));
  List.foldRight<Nat, Text>(vec, "", func(x, acc) = Nat.toText(x) # acc) == Array.foldRight<Nat, Text>(Array.tabulate<Nat>(n, func(i) = i + 1), "", func(x, acc) = Nat.toText(x) # acc)
};

func testFilter(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));

  let evens = List.filter<Nat>(vec, func x = x % 2 == 0);
  let expectedEvens = List.fromArray<Nat>(Array.tabulate<Nat>((n + 1) / 2, func(i) = i * 2));
  if (not List.equal<Nat>(evens, expectedEvens, Nat.equal)) {
    Debug.print("Filter evens failed");
    return false
  };

  let none = List.filter<Nat>(vec, func _ = false);
  if (not List.isEmpty(none)) {
    Debug.print("Filter none failed");
    return false
  };

  let all = List.filter<Nat>(vec, func _ = true);
  if (not List.equal<Nat>(all, vec, Nat.equal)) {
    Debug.print("Filter all failed");
    return false
  };

  true
};

func testFilterMap(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));

  let doubledEvens = List.filterMap<Nat, Nat>(vec, func x = if (x % 2 == 0) ?(x * 2) else null);
  let expectedDoubledEvens = List.fromArray<Nat>(Array.tabulate<Nat>((n + 1) / 2, func(i) = i * 4));
  if (not List.equal<Nat>(doubledEvens, expectedDoubledEvens, Nat.equal)) {
    Debug.print("FilterMap doubled evens failed");
    return false
  };

  let none = List.filterMap<Nat, Nat>(vec, func _ = null);
  if (not List.isEmpty(none)) {
    Debug.print("FilterMap none failed");
    return false
  };

  let all = List.filterMap<Nat, Nat>(vec, func x = ?x);
  if (not List.equal<Nat>(all, vec, Nat.equal)) {
    Debug.print("FilterMap all failed");
    return false
  };

  true
};

func testPure(n : Nat) : Bool {
  let idArray = Array.tabulate<Nat>(n, func(i) = i);
  let vec = List.fromArray<Nat>(idArray);
  let pureList = List.toPure<Nat>(vec);
  let newVec = List.fromPure<Nat>(pureList);

  if (not PureList.equal<Nat>(pureList, PureList.fromArray<Nat>(idArray), Nat.equal)) {
    Debug.print("PureList conversion failed");
    return false
  };
  if (not List.equal<Nat>(newVec, vec, Nat.equal)) {
    Debug.print("List conversion from PureList failed");
    return false
  };

  true
};

// Run all tests
func runAllTests() {
  runTest("testNew", testNew);
  runTest("testInit", testInit);
  runTest("testAdd", testAdd);
  runTest("testAddAll", testAddAll);
  runTest("testRemoveLast", testRemoveLast);
  runTest("testGet", testGet);
  runTest("testGetOpt", testGetOpt);
  runTest("testPut", testPut);
  runTest("testClear", testClear);
  runTest("testClone", testClone);
  runTest("testMap", testMap);
  runTest("testIndexOf", testIndexOf);
  runTest("testLastIndexOf", testLastIndexOf);
  runTest("testContains", testContains);
  runTest("testReverse", testReverse);
  runTest("testSort", testSort);
  runTest("testToArray", testToArray);
  runTest("testFromIter", testFromIter);
  runTest("testFoldLeft", testFoldLeft);
  runTest("testFoldRight", testFoldRight);
  runTest("testFilter", testFilter);
  runTest("testFilterMap", testFilterMap);
  runTest("testPure", testPure)
};

// Run all tests
runAllTests();

Test.suite(
  "Regression tests",
  func() {
    Test.test(
      "test adding many elements",
      func() {
        let list = List.empty<Nat>();

        var blockSize = list.blocks.size();
        var sizes = List.empty<(Nat, Nat)>();
        List.add(sizes, (blockSize, 0));

        let expectedSize = 100_000;
        for (i in Nat.range(0, expectedSize)) {
          List.add(list, i);

          let size = list.blocks.size();
          assert blockSize <= size;
          if (blockSize < size) {
            blockSize := size;
            List.add(sizes, (blockSize, List.size(list)))
          }
        };
        Test.expect.nat(List.size(list)).equal(expectedSize);

        // Check how block size grows with the number of elements
        let expectedBlockResizes = [
          (1, 0),
          (2, 1),
          (3, 2),
          (4, 3),
          (6, 5),
          (8, 9),
          (12, 17),
          (16, 33),
          (24, 65),
          (32, 129),
          (48, 257),
          (64, 513),
          (96, 1_025),
          (128, 2_049),
          (192, 4_097),
          (256, 8_193),
          (384, 16_385),
          (512, 32_769),
          (768, 65_537)
        ];
        Test.expect.array<(Nat, Nat)>(List.toArray(sizes), Tuple2.makeToText(Nat.toText, Nat.toText), Tuple2.makeEqual<Nat, Nat>(Nat.equal, Nat.equal)).equal(expectedBlockResizes)
      }
    )
  }
);

Test.suite(
  "Null on empty",
  func() {
    Test.test(
      "indexOf",
      func() {
        Test.expect.bool(List.indexOf(empty, Nat.equal, 0) == null).equal(true);
        Test.expect.bool(List.indexOf(emptied, Nat.equal, 0) == null).equal(true)
      }
    );
    Test.test(
      "lastIndexOf",
      func() {
        Test.expect.bool(List.lastIndexOf(empty, Nat.equal, 0) == null).equal(true);
        Test.expect.bool(List.lastIndexOf(emptied, Nat.equal, 0) == null).equal(true)
      }
    );
    Test.test(
      "find",
      func() {
        Test.expect.bool(List.find<Nat>(empty, func x = x == 0) == null).equal(true);
        Test.expect.bool(List.find<Nat>(emptied, func x = x == 0) == null).equal(true)
      }
    );
    Test.test(
      "findIndex",
      func() {
        Test.expect.bool(List.findIndex<Nat>(empty, func x = x == 0) == null).equal(true);
        Test.expect.bool(List.findIndex<Nat>(emptied, func x = x == 0) == null).equal(true)
      }
    );
    Test.test(
      "findLastIndex",
      func() {
        Test.expect.bool(List.findLastIndex<Nat>(empty, func x = x == 0) == null).equal(true);
        Test.expect.bool(List.findLastIndex<Nat>(emptied, func x = x == 0) == null).equal(true)
      }
    );
    Test.test(
      "max",
      func() {
        Test.expect.bool(List.max(empty, Nat.compare) == null).equal(true);
        Test.expect.bool(List.max(emptied, Nat.compare) == null).equal(true)
      }
    );
    Test.test(
      "min",
      func() {
        Test.expect.bool(List.min(empty, Nat.compare) == null).equal(true);
        Test.expect.bool(List.min(emptied, Nat.compare) == null).equal(true)
      }
    )
  }
)
