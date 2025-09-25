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

let { run; test; suite } = Suite;

func unwrap<T>(x : ?T) : T = switch (x) {
  case (?v) v;
  case (_) Prim.trap "internal error in unwrap()"
};

let n = 100;
var list = List.empty<Nat>();

let sizes = List.empty<Nat>();
for (i in Nat.rangeInclusive(0, n)) {
  sizes.add(list.size());
  list.add(i)
};
sizes.add(list.size());

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
        list.clone().toArray(),
        M.equals(T.array(T.natTestable, list.toArray()))
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
        sizes.toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n + 1).toArray()))
      ),
      test(
        "elements",
        list.toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).toArray()))
      )
    ]
  )
);

assert list.find(func(a : Nat) : Bool = a == 123456) == null;
assert list.find(func(a : Nat) : Bool = a == 0) == ?0;

assert list.indexOf(Nat.equal, n + 1) == null;
assert list.findIndex(func(a : Nat) : Bool = a == n + 1) == null;
assert list.indexOf(Nat.equal, n) == ?n;
assert list.findIndex(func(a : Nat) : Bool = a == n) == ?n;

assert list.lastIndexOf(Nat.equal, n + 1) == null;
assert list.findLastIndex(func(a : Nat) : Bool = a == n + 1) == null;

assert list.lastIndexOf(Nat.equal, 0) == ?0;
assert list.findLastIndex(func(a : Nat) : Bool = a == 0) == ?0;

assert list.all(func(x : Nat) : Bool = 0 <= x and x <= n);
assert list.any(func(x : Nat) : Bool = x == n / 2);

run(
  suite(
    "iterator",
    [
      test(
        "values",
        list.values().toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).toArray()))
      ),
      test(
        "reverseValues",
        list.reverseValues().toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).reverse().toArray()))
      ),
      test(
        "keys",
        list.keys().toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).toArray()))
      ),
      test(
        "enumerate1",
        list.enumerate().map(func((a, b)) { b }).toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).toArray()))
      ),
      test(
        "enumerate2",
        list.enumerate().map(func((a, b)) { a }).toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).toArray()))
      ),
      test(
        "reverseEnumerate1",
        list.reverseEnumerate().map(func((a, b)) { b }).toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).reverse().toArray()))
      ),
      test(
        "reverseEnumerate2",
        list.reverseEnumerate().map(func((a, b)) { a }).toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).reverse().toArray()))
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
        List.repeat<Nat>(0, n).toArray(),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(n, func(_) = 0)))
      ),
      test(
        "init with values",
        List.repeat<Nat>(0, n).values().toArray(),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(n, func(_) = 0)))
      ),
      test(
        "add many with toArray",
        for_add_many.toArray(),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(2 * n, func(_) = 0)))
      ),
      test(
        "add many with vals",
        Iter.toArray(for_add_many.values()),
        M.equals(T.array(T.natTestable, Array.tabulate<Nat>(2 * n, func(_) = 0)))
      ),
      test(
        "addFromIter",
        for_add_iter.toArray(),
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
        list.size(),
        M.equals(T.nat(n + 1))
      ),
      test(
        "elements",
        list.toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).reverse().toArray()))
      )
    ]
  )
);

let removed = List.empty<Nat>();
for (i in Nat.rangeInclusive(0, n)) {
  removed.add(unwrap(list.removeLast()))
};

let empty = List.empty<Nat>();
let emptied = List.singleton<Nat>(0);
let _ = emptied.removeLast();

run(
  suite(
    "removeLast",
    [
      test(
        "size",
        list.size(),
        M.equals(T.nat(0))
      ),
      test(
        "elements",
        removed.toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).toArray()))
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
assert list.first() == null;
assert list.last() == null;

for (i in Nat.rangeInclusive(0, n)) {
  list.add(i);
  assert list.last() == ?i;
  assert list.first() == ?0
};

run(
  suite(
    "addAfterRemove",
    [
      test(
        "elements",
        list.toArray(),
        M.equals(T.array(T.natTestable, Nat.rangeInclusive(0, n).toArray()))
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
        list.first(),
        M.equals(T.optional(T.natTestable, ?0))
      ),
      test(
        "first empty",
        empty.first(),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      ),
      test(
        "first emptied",
        emptied.first(),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      ),
      test(
        "last of len N",
        list.last(),
        M.equals(T.optional(T.natTestable, ?n))
      ),
      test(
        "last of len 1",
        List.repeat<Nat>(1, 1).last(),
        M.equals(T.optional(T.natTestable, ?1))
      ),
      test(
        "last of 6",
        List.fromArray<Nat>([0, 1, 2, 3, 4, 5]).last(),
        M.equals(T.optional(T.natTestable, ?5))
      ),
      test(
        "last empty",
        List.empty<Nat>().last(),
        M.equals(T.optional(T.natTestable, null : ?Nat))
      ),
      test(
        "last emptied",
        emptied.last(),
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
list.forEach(func(i) { sumN += i });
var sumRev = 0;
list.reverseForEach<Nat>(func(i) { sumRev += i });
var sum1 = 0;
List.repeat<Nat>(1, 1).forEach(func(i) { sum1 += i });
var sum0 = 0;
List.empty<Nat>().forEach(func(i) { sum0 += i });

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
list.forEachEntry<Nat>(func(i, x) { sumItems += i + x });
var sumItemsRev = 0;
list.forEachEntry<Nat>(func(i, x) { sumItemsRev += i + x });

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
        list.contains(Nat.equal, 2),
        M.equals(T.bool(true))
      ),
      test(
        "true",
        list.contains(Nat.equal, 9),
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
        list.contains(Nat.equal, 2),
        M.equals(T.bool(false))
      ),
      test(
        "true",
        list.contains(Nat.equal, 9),
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
        list.max(Nat.compare),
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
        list.min(Nat.compare),
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
        List.empty<Nat>().equal(List.empty<Nat>(), Nat.equal),
        M.equals(T.bool(true))
      ),
      test(
        "non-empty lists",
        list.equal(List.clone(list), Nat.equal),
        M.equals(T.bool(true))
      ),
      test(
        "non-empty and empty lists",
        list.equal(List.empty<Nat>(), Nat.equal),
        M.equals(T.bool(false))
      ),
      test(
        "non-empty lists mismatching lengths",
        list.equal<Nat>(list2, Nat.equal),
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
        List.empty<Nat>().compare(List.empty<Nat>(), Nat.compare),
        M.equals(OrderTestable(#equal))
      ),
      test(
        "non-empty lists equal",
        list.compare(List.clone(list), Nat.compare),
        M.equals(OrderTestable(#equal))
      ),
      test(
        "non-empty and empty lists",
        list.compare(List.empty<Nat>(), Nat.compare),
        M.equals(OrderTestable(#greater))
      ),
      test(
        "non-empty lists mismatching lengths",
        list.compare(list2, Nat.compare),
        M.equals(OrderTestable(#greater))
      ),
      test(
        "non-empty lists lexicographic difference",
        list.compare(list3, Nat.compare),
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
        List.empty<Nat>().toText(Nat.toText),
        M.equals(T.text("List[]"))
      ),
      test(
        "singleton list",
        List.singleton<Nat>(3).toText<Nat>(Nat.toText),
        M.equals(T.text("List[3]"))
      ),
      test(
        "non-empty list",
        list.toText(Nat.toText),
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

list.reverseInPlace();
list2.reverseInPlace();
list3.reverseInPlace();
list4.reverseInPlace();

run(
  suite(
    "reverseInPlace",
    [
      test(
        "even elements",
        list.toArray(),
        M.equals(T.array(T.natTestable, [7, 6, 5, 4, 3, 2, 1, 0]))
      ),
      test(
        "odd elements",
        list2.toArray(),
        M.equals(T.array(T.natTestable, [6, 5, 4, 3, 2, 1, 0]))
      ),
      test(
        "empty",
        list3.toArray(),
        M.equals(T.array(T.natTestable, [] : [Nat]))
      ),
      test(
        "singleton",
        list4.toArray(),
        M.equals(T.array(T.natTestable, [3]))
      )
    ]
  )
);

/* --------------------------------------- */

list := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6, 7]).reverse();
list2 := List.fromArray<Nat>([0, 1, 2, 3, 4, 5, 6]).reverse();
list3 := List.empty<Nat>().reverse();
list4 := List.singleton<Nat>(3).reverse();

run(
  suite(
    "reverse",
    [
      test(
        "even elements",
        list.toArray(),
        M.equals(T.array(T.natTestable, [7, 6, 5, 4, 3, 2, 1, 0]))
      ),
      test(
        "odd elements",
        list2.toArray(),
        M.equals(T.array(T.natTestable, [6, 5, 4, 3, 2, 1, 0]))
      ),
      test(
        "empty",
        list3.toArray(),
        M.equals(T.array(T.natTestable, [] : [Nat]))
      ),
      test(
        "singleton",
        list4.toArray(),
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
        list.foldLeft("", func(acc, x) = acc # Nat.toText(x)),
        M.equals(T.text("0123456"))
      ),
      test(
        "return value empty",
        List.empty<Nat>().foldLeft("", func(acc, x) = acc # Nat.toText(x)),
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
        list.foldRight("", func(x, acc) = acc # Nat.toText(x)),
        M.equals(T.text("6543210"))
      ),
      test(
        "return value empty",
        List.empty<Nat>().foldRight("", func(x, acc) = acc # Nat.toText(x)),
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
        List.empty<Nat>().isEmpty(),
        M.equals(T.bool(true))
      ),
      test(
        "false",
        list.isEmpty(),
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
        list.map(Nat.toText).toArray(),
        M.equals(T.array(T.textTestable, ["0", "1", "2", "3", "4", "5", "6"]))
      ),
      test(
        "empty",
        List.empty<Nat>().map(Nat.toText).isEmpty(),
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
        list.filter(func x = x % 2 == 0).toArray(),
        M.equals(T.array(T.natTestable, [0, 2, 4, 6]))
      ),
      test(
        "filter none",
        list.filter(func _ = false).toArray(),
        M.equals(T.array(T.natTestable, [] : [Nat]))
      ),
      test(
        "filter all",
        list.filter(func _ = true).toArray(),
        M.equals(T.array(T.natTestable, [0, 1, 2, 3, 4, 5, 6]))
      ),
      test(
        "filter empty",
        List.empty<Nat>().filter(func _ = true).isEmpty(),
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
        list.filterMap<Nat, Nat>(func x = if (x % 2 == 0) ?(x * 2) else null).toArray(),
        M.equals(T.array(T.natTestable, [0, 4, 8, 12]))
      ),
      test(
        "filterMap none",
        list.filterMap<Nat, Nat>(func _ = null).toArray(),
        M.equals(T.array(T.natTestable, [] : [Nat]))
      ),
      test(
        "filterMap all",
        list.filterMap<Nat, Text>(func x = ?(Nat.toText(x))).toArray(),
        M.equals(T.array(T.textTestable, ["0", "1", "2", "3", "4", "5", "6"]))
      ),
      test(
        "filterMap empty",
        List.empty<Nat>().filterMap<Nat, Nat>(func x = ?x).isEmpty(),
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
        do { list.sort(Nat.compare); list.toArray() },
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
  vec.size() == 0
};

func testInit(n : Nat) : Bool {
  let vec = List.repeat<Nat>(1, n);
  vec.size() == n and (n == 0 or (List.at(vec, 0) == 1 and List.at(vec, n - 1 : Nat) == 1))
};

func testAdd(n : Nat) : Bool {
  if (n == 0) return true;
  let vec = List.empty<Nat>();
  for (i in Nat.range(0, n)) {
    vec.add(i)
  };

  if (vec.size() != n) {
    Debug.print("Size mismatch: expected " # Nat.toText(n) # ", got " # Nat.toText(vec.size()));
    return false
  };

  for (i in Nat.range(0, n)) {
    let value = List.at(vec, i);
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
    let value = List.at(vec, n + i);
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
    let last = vec.removeLast();
    if (last != ?i) {
      Debug.print("Unexpected value removed: expected ?" # Nat.toText(i) # ", got " # debug_show (last));
      return false
    };
    if (List.size(vec) != i) {
      Debug.print("Unexpected size after removal: expected " # Nat.toText(i) # ", got " # Nat.toText(vec.size()));
      return false
    }
  };

  // Try to remove from empty vector
  if (List.removeLast(vec) != null) {
    Debug.print("Expected null when removing from empty vector, but got a value");
    return false
  };

  if (List.size(vec) != 0) {
    Debug.print("List should be empty, but has size " # Nat.toText(vec.size()));
    return false
  };

  true
};

func testAt(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));

  for (i in Nat.range(1, n + 1)) {
    let value = List.at(vec, i - 1 : Nat);
    if (value != i) {
      Debug.print("at: Mismatch at index " # Nat.toText(i) # ": expected " # Nat.toText(i) # ", got " # Nat.toText(value));
      return false
    }
  };

  true
};

func testGet(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));

  for (i in Nat.range(1, n + 1)) {
    switch (List.get(vec, i - 1 : Nat)) {
      case (?value) {
        if (value != i) {
          Debug.print("get: Mismatch at index " # Nat.toText(i) # ": expected ?" # Nat.toText(i) # ", got ?" # Nat.toText(value));
          return false
        }
      };
      case (null) {
        Debug.print("get: Unexpected null at index " # Nat.toText(i));
        return false
      }
    }
  };

  // Test out-of-bounds access
  switch (List.get(vec, n)) {
    case (null) {
      // This is expected
    };
    case (?value) {
      Debug.print("get: Expected null for out-of-bounds access, got ?" # Nat.toText(value));
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
    vec.put(n - 1 : Nat, 100);
    vec.at(n - 1 : Nat) == 100
  }
};

func testClear(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  vec.clear();
  vec.size() == 0
};

func testClone(n : Nat) : Bool {
  let vec1 = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  let vec2 = vec1.clone();
  vec1.equal(vec2, Nat.equal)
};

func testMap(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  let mapped = vec.map<Nat, Nat>(func(x) = x * 2);
  mapped.equal(List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i * 2)), Nat.equal)
};

func testIndexOf(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(2 * n, func(i) = i % n));
  if (n == 0) {
    vec.indexOf(Nat.equal, 0) == null
  } else {
    var allCorrect = true;
    for (i in Nat.range(0, n)) {
      let index = vec.indexOf(Nat.equal, i);
      if (index != ?i) {
        allCorrect := false;
        Debug.print("indexOf failed for i = " # Nat.toText(i) # ", expected ?" # Nat.toText(i) # ", got " # debug_show (index))
      }
    };
    allCorrect and vec.indexOf(Nat.equal, n) == null
  }
};

func testLastIndexOf(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(2 * n, func(i) = i % n));
  if (n == 0) {
    vec.lastIndexOf(Nat.equal, 0) == null
  } else {
    var allCorrect = true;
    for (i in Nat.range(0, n)) {
      let index = vec.lastIndexOf(Nat.equal, i);
      if (index != ?(n + i)) {
        allCorrect := false;
        Debug.print("lastIndexOf failed for i = " # Nat.toText(i) # ", expected ?" # Nat.toText(n + i) # ", got " # debug_show (index))
      }
    };
    allCorrect and vec.lastIndexOf(Nat.equal, n) == null
  }
};

func testContains(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));

  // Check if it contains all elements from 0 to n-1
  for (i in Nat.range(1, n + 1)) {
    if (not vec.contains(Nat.equal, i)) {
      Debug.print("List should contain " # Nat.toText(i) # " but it doesn't");
      return false
    }
  };

  // Check if it doesn't contain n (which should be out of range)
  if (vec.contains(Nat.equal, n + 1)) {
    Debug.print("List shouldn't contain " # Nat.toText(n + 1) # " but it does");
    return false
  };

  // Check if it doesn't contain n+1 (another out of range value)
  if (vec.contains(Nat.equal, n + 2)) {
    Debug.print("List shouldn't contain " # Nat.toText(n + 2) # " but it does");
    return false
  };

  true
};
func testReverse(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  vec.reverseInPlace();
  vec.equal(List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = n - 1 - i)), Nat.equal)
};

func testSort(n : Nat) : Bool {
  let vec = List.fromArray<Int>(Array.tabulate<Int>(n, func(i) = (i * 123) % 100 - 50));
  vec.sort(Int.compare);
  vec.equal(List.fromArray<Int>(Array.sort(Array.tabulate<Int>(n, func(i) = (i * 123) % 100 - 50), Int.compare)), Int.equal)
};

func testToArray(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));
  Array.equal(vec.toArray(), Array.tabulate<Nat>(n, func(i) = i), Nat.equal)
};

func testFromIter(n : Nat) : Bool {
  let iter = Nat.range(1, n + 1);
  let vec = List.fromIter<Nat>(iter);
  vec.equal(List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1)), Nat.equal)
};

func testFoldLeft(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));
  vec.foldLeft("", func(acc, x) = acc # Nat.toText(x)) == Array.foldLeft<Nat, Text>(Array.tabulate<Nat>(n, func(i) = i + 1), "", func(acc, x) = acc # Nat.toText(x))
};

func testFoldRight(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i + 1));
  vec.foldRight("", func(x, acc) = Nat.toText(x) # acc) == Array.foldRight<Nat, Text>(Array.tabulate<Nat>(n, func(i) = i + 1), "", func(x, acc) = Nat.toText(x) # acc)
};

func testFilter(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));

  let evens = vec.filter(func x = x % 2 == 0);
  let expectedEvens = List.fromArray<Nat>(Array.tabulate<Nat>((n + 1) / 2, func(i) = i * 2));
  if (not evens.equal(expectedEvens, Nat.equal)) {
    Debug.print("Filter evens failed");
    return false
  };

  let none = vec.filter(func _ = false);
  if (not none.isEmpty()) {
    Debug.print("Filter none failed");
    return false
  };

  let all = vec.filter(func _ = true);
  if (not all.equal(vec, Nat.equal)) {
    Debug.print("Filter all failed");
    return false
  };

  true
};

func testFilterMap(n : Nat) : Bool {
  let vec = List.fromArray<Nat>(Array.tabulate<Nat>(n, func(i) = i));

  let doubledEvens = vec.filterMap<Nat, Nat>(func x = if (x % 2 == 0) ?(x * 2) else null);
  let expectedDoubledEvens = List.fromArray<Nat>(Array.tabulate<Nat>((n + 1) / 2, func(i) = i * 4));
  if (not doubledEvens.equal(expectedDoubledEvens, Nat.equal)) {
    Debug.print("FilterMap doubled evens failed");
    return false
  };

  let none = vec.filterMap<Nat, Nat>(func _ = null);
  if (not none.isEmpty()) {
    Debug.print("FilterMap none failed");
    return false
  };

  let all = vec.filterMap<Nat, Nat>(func x = ?x);
  if (not all.equal<Nat>(vec, Nat.equal)) {
    Debug.print("FilterMap all failed");
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
  runTest("testAt", testAt);
  runTest("testGet", testGet);
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
  runTest("testFilterMap", testFilterMap)
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
        sizes.add(blockSize, 0);

        let expectedSize = 100_000;
        for (i in Nat.range(0, expectedSize)) {
          list.add(i);

          let size = list.blocks.size();
          assert blockSize <= size;
          if (blockSize < size) {
            blockSize := size;
            sizes.add(blockSize, list.size())
          }
        };
        Test.expect.nat(list.size()).equal(expectedSize);

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
        Test.expect.array<(Nat, Nat)>(sizes.toArray(), Tuple2.makeToText(Nat.toText, Nat.toText), Tuple2.makeEqual<Nat, Nat>(Nat.equal, Nat.equal)).equal(expectedBlockResizes)
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
    );
    Test.test(
      "binarySearch",
      func() {
        let result1 = List.binarySearch<Nat>(empty, Nat.compare, 0);
        let result2 = List.binarySearch<Nat>(emptied, Nat.compare, 0);
        Test.expect.bool(result1 == #insertionIndex(0)).equal(true);
        Test.expect.bool(result2 == #insertionIndex(0)).equal(true)
      }
    )
  }
);

// Additional binarySearch tests
Test.suite(
  "binarySearch",
  func() {
    Test.test(
      "found",
      func() {
        let list = List.fromArray<Nat>([1, 3, 5, 7, 9, 11]);
        let result = List.binarySearch<Nat>(list, Nat.compare, 5);
        Test.expect.bool(result == #found(2)).equal(true)
      }
    );
    Test.test(
      "not found",
      func() {
        let list = List.fromArray<Nat>([1, 3, 5, 7, 9, 11]);
        let result = List.binarySearch<Nat>(list, Nat.compare, 6);
        Test.expect.bool(result == #insertionIndex(3)).equal(true)
      }
    );
    Test.test(
      "first element",
      func() {
        let list = List.fromArray<Nat>([1, 3, 5, 7, 9, 11]);
        let result = List.binarySearch<Nat>(list, Nat.compare, 1);
        Test.expect.bool(result == #found(0)).equal(true)
      }
    );
    Test.test(
      "last element",
      func() {
        let list = List.fromArray<Nat>([1, 3, 5, 7, 9, 11]);
        let result = List.binarySearch<Nat>(list, Nat.compare, 11);
        Test.expect.bool(result == #found(5)).equal(true)
      }
    );
    Test.test(
      "single element found",
      func() {
        let list = List.fromArray<Nat>([42]);
        let result = List.binarySearch<Nat>(list, Nat.compare, 42);
        Test.expect.bool(result == #found(0)).equal(true)
      }
    );
    Test.test(
      "single element not found",
      func() {
        let list = List.fromArray<Nat>([42]);
        let result = List.binarySearch<Nat>(list, Nat.compare, 43);
        Test.expect.bool(result == #insertionIndex(1)).equal(true)
      }
    );
    Test.test(
      "duplicates",
      func() {
        let list = List.fromArray<Nat>([1, 2, 2, 2, 3]);
        let result = List.binarySearch<Nat>(list, Nat.compare, 2);
        let ok = switch result {
          case (#found index) { index >= 1 and index <= 3 };
          case _ { false }
        };
        Test.expect.bool(ok).equal(true)
      }
    )
  }
)
