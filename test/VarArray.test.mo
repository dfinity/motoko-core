import VarArray "../src/VarArray";
import Int "../src/Int";
import Char "../src/Char";
import Nat "../src/Nat";
import Text "../src/Text";
import Suite "mo:matchers/Suite";
import T "mo:matchers/Testable";
import M "mo:matchers/Matchers";

func joinWith(xs : [var Text], sep : Text) : Text {
  let size = xs.size();

  if (size == 0) return "";
  if (size == 1) return xs[0];

  var result = xs[0];
  var i = 0;
  label l loop {
    i += 1;
    if (i >= size) { break l };
    result #= sep # xs[i]
  };
  result
};

func varArrayTestable<A>(testableA : T.Testable<A>) : T.Testable<[var A]> {
  {
    display = func(xs : [var A]) : Text = "[var " # joinWith(VarArray.map<A, Text>(xs, testableA.display), ", ") # "]";
    equals = func(xs1 : [var A], xs2 : [var A]) : Bool = VarArray.equal(xs1, xs2, testableA.equals)
  }
};

func varArray<A>(testableA : T.Testable<A>, xs : [var A]) : T.TestableItem<[var A]> {
  let testableAs = varArrayTestable<A>(testableA);
  {
    item = xs;
    display = testableAs.display;
    equals = testableAs.equals
  }
};

let suite = Suite.suite(
  "VarArray",
  [
    Suite.test(
      "repeat",
      VarArray.repeat<Int>(4, 3),
      M.equals(varArray<Int>(T.intTestable, [var 4, 4, 4]))
    ),
    Suite.test(
      "repeat empty",
      VarArray.repeat<Int>(4, 0),
      M.equals(varArray<Int>(T.intTestable, [var]))
    ),
    Suite.test(
      "tabulate",
      VarArray.tabulate<Int>(3, func(i : Nat) = i * 2),
      M.equals(varArray<Int>(T.intTestable, [var 0, 2, 4]))
    ),
    Suite.test(
      "tabulate empty",
      VarArray.tabulate<Int>(0, func(i : Nat) = i),
      M.equals(varArray<Int>(T.intTestable, [var]))
    ),
    Suite.test(
      "equal",
      VarArray.equal<Int>([var 1, 2, 3], [var 1, 2, 3], Int.equal),
      M.equals(T.bool(true))
    ),
    Suite.test(
      "equal empty",
      VarArray.equal<Int>([var], [var], Int.equal),
      M.equals(T.bool(true))
    ),
    Suite.test(
      "not equal one empty",
      VarArray.equal<Int>([var], [var 2, 3], Int.equal),
      M.equals(T.bool(false))
    ),
    Suite.test(
      "not equal different lengths",
      VarArray.equal<Int>([var 1, 2, 3], [var 2, 4], Int.equal),
      M.equals(T.bool(false))
    ),
    Suite.test(
      "not equal same lengths",
      VarArray.equal<Int>([var 1, 2, 3], [var 1, 2, 4], Int.equal),
      M.equals(T.bool(false))
    ),
    Suite.test(
      "find",
      VarArray.find<Nat>([var 1, 9, 4, 8], func x = x == 9),
      M.equals(T.optional(T.natTestable, ?9))
    ),
    Suite.test(
      "find fail",
      VarArray.find<Nat>([var 1, 9, 4, 8], func _ = false),
      M.equals(T.optional(T.natTestable, null : ?Nat))
    ),
    Suite.test(
      "find empty",
      VarArray.find<Nat>([var], func _ = true),
      M.equals(T.optional(T.natTestable, null : ?Nat))
    ),
    Suite.test(
      "concat",
      VarArray.concat<Int>([var 1, 2, 3], [var 4, 5, 6]),
      M.equals(varArray<Int>(T.intTestable, [var 1, 2, 3, 4, 5, 6]))
    ),
    Suite.test(
      "concat first empty",
      VarArray.concat<Int>([var], [var 4, 5, 6]),
      M.equals(varArray<Int>(T.intTestable, [var 4, 5, 6]))
    ),
    Suite.test(
      "concat second empty",
      VarArray.concat<Int>([var 1, 2, 3], [var]),
      M.equals(varArray<Int>(T.intTestable, [var 1, 2, 3]))
    ),
    Suite.test(
      "concat both empty",
      VarArray.concat<Int>([var], [var]),
      M.equals(varArray<Int>(T.intTestable, [var]))
    ),
    Suite.test(
      "sort",
      VarArray.sort([var 2, 3, 1], Nat.compare),
      M.equals(varArray<Nat>(T.natTestable, [var 1, 2, 3]))
    ),
    Suite.test(
      "sort empty array",
      VarArray.sort<Nat>([var], Nat.compare),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    ),
    Suite.test(
      "sort already sorted",
      VarArray.sort([var 1, 2, 3, 4, 5], Nat.compare),
      M.equals(varArray<Nat>(T.natTestable, [var 1, 2, 3, 4, 5]))
    ),
    Suite.test(
      "sort repeated elements",
      VarArray.sort([var 2, 2, 2, 2, 2], Nat.compare),
      M.equals(varArray<Nat>(T.natTestable, [var 2, 2, 2, 2, 2]))
    ),
    Suite.test(
      "reverse",
      VarArray.reverse<Nat>([var 0, 1, 2, 2, 3]),
      M.equals(varArray<Nat>(T.natTestable, [var 3, 2, 2, 1, 0]))
    ),
    Suite.test(
      "reverse empty",
      VarArray.reverse<Nat>([var]),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    ),
    Suite.test(
      "reverse singleton",
      VarArray.reverse<Nat>([var 0]),
      M.equals(varArray<Nat>(T.natTestable, [var 0]))
    ),
    Suite.test(
      "map",
      VarArray.map<Nat, Bool>([var 1, 2, 3], func x = x % 2 == 0),
      M.equals(varArray<Bool>(T.boolTestable, [var false, true, false]))
    ),
    Suite.test(
      "map empty",
      VarArray.map<Nat, Bool>([var], func x = x % 2 == 0),
      M.equals(varArray<Bool>(T.boolTestable, [var]))
    ),
    Suite.test(
      "filter",
      VarArray.filter<Nat>([var 1, 2, 3, 4, 5, 6], func x = x % 2 == 0),
      M.equals(varArray<Nat>(T.natTestable, [var 2, 4, 6]))
    ),
    Suite.test(
      "filter empty",
      VarArray.filter<Nat>([var], func x = x % 2 == 0),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    ),
    Suite.test(
      "mapEntries",
      VarArray.mapEntries<Nat, Nat>([var 1, 2, 3], func(x, i) = x + i),
      M.equals(varArray<Nat>(T.natTestable, [var 1, 3, 5]))
    ),
    Suite.test(
      "mapEntries empty",
      VarArray.mapEntries<Nat, Nat>([var], func(x, i) = x + i),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    ),
    Suite.test(
      "filterMap",
      VarArray.filterMap<Nat, Nat>([var 1, 2, 3, 4, 5, 6], func x { if (x % 2 == 0) ?x else null }),
      M.equals(varArray<Nat>(T.natTestable, [var 2, 4, 6]))
    ),
    Suite.test(
      "filterMap keep all",
      VarArray.filterMap<Nat, Nat>([var 1, 2, 3], func x = ?x),
      M.equals(varArray<Nat>(T.natTestable, [var 1, 2, 3]))
    ),
    Suite.test(
      "filterMap keep none",
      VarArray.filterMap<Nat, Nat>([var 1, 2, 3], func _ = null),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    ),
    Suite.test(
      "filterMap empty",
      VarArray.filterMap<Nat, Nat>([var], func x { if (x % 2 == 0) ?x else null }),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    ),
    Suite.test(
      "mapResult",
      VarArray.mapResult<Int, Nat, Text>(
        [var 1, 2, 3],
        func x { if (x >= 0) { #ok(Int.abs x) } else { #err "error message" } }
      ),
      M.equals(T.result<[var Nat], Text>(varArrayTestable(T.natTestable), T.textTestable, #ok([var 1, 2, 3])))
    ),
    Suite.test(
      "mapResult fail first",
      VarArray.mapResult<Int, Nat, Text>(
        [var -1, 2, 3],
        func x { if (x >= 0) { #ok(Int.abs x) } else { #err "error message" } }
      ),
      M.equals(T.result<[var Nat], Text>(varArrayTestable(T.natTestable), T.textTestable, #err "error message"))
    ),
    Suite.test(
      "mapResult fail last",
      VarArray.mapResult<Int, Nat, Text>(
        [var 1, 2, -3],
        func x { if (x >= 0) { #ok(Int.abs x) } else { #err "error message" } }
      ),
      M.equals(T.result<[var Nat], Text>(varArrayTestable(T.natTestable), T.textTestable, #err "error message"))
    ),
    Suite.test(
      "mapResult empty",
      VarArray.mapResult<Nat, Nat, Text>(
        [var],
        func x = #ok x
      ),
      M.equals(T.result<[var Nat], Text>(varArrayTestable(T.natTestable), T.textTestable, #ok([var])))
    ),
    Suite.test(
      "flatMap",
      VarArray.flatMap<Int, Int>([var 0, 1, 2], func x = [x, -x].values()),
      M.equals(varArray<Int>(T.intTestable, [var 0, 0, 1, -1, 2, -2]))
    ),
    Suite.test(
      "flatMap empty",
      VarArray.flatMap<Int, Int>([var], func x = [x, -x].values()),
      M.equals(varArray<Int>(T.intTestable, [var]))
    ),
    Suite.test(
      "flatMap mix",
      VarArray.flatMap<Nat, Nat>(
        [var 1, 2, 1, 2, 3],
        func n = VarArray.tabulate<Nat>(n, func i = i).values()
      ),
      M.equals(varArray<Nat>(T.natTestable, [var 0, 0, 1, 0, 0, 1, 0, 1, 2]))
    ),
    Suite.test(
      "flatMap mix empty right",
      VarArray.flatMap<Nat, Nat>(
        [var 0, 1, 2, 0, 1, 2, 3, 0],
        func n = VarArray.tabulate<Nat>(n, func i = i).values()
      ),
      M.equals(varArray<Nat>(T.natTestable, [var 0, 0, 1, 0, 0, 1, 0, 1, 2]))
    ),
    Suite.test(
      "flatMap mix empties right",
      VarArray.flatMap<Nat, Nat>(
        [var 0, 1, 2, 0, 1, 2, 3, 0, 0, 0],
        func n = VarArray.tabulate<Nat>(n, func i = i).values()
      ),
      M.equals(varArray<Nat>(T.natTestable, [var 0, 0, 1, 0, 0, 1, 0, 1, 2]))
    ),
    Suite.test(
      "flatMap mix empty left",
      VarArray.flatMap<Nat, Nat>(
        [var 0, 1, 2, 0, 1, 2, 3],
        func n = VarArray.tabulate<Nat>(n, func i = i).values()
      ),
      M.equals(varArray<Nat>(T.natTestable, [var 0, 0, 1, 0, 0, 1, 0, 1, 2]))
    ),
    Suite.test(
      "flatMap mix empties left",
      VarArray.flatMap<Nat, Nat>(
        [var 0, 0, 0, 1, 2, 0, 1, 2, 3],
        func n = VarArray.tabulate<Nat>(n, func i = i).values()
      ),
      M.equals(varArray<Nat>(T.natTestable, [var 0, 0, 1, 0, 0, 1, 0, 1, 2]))
    ),
    Suite.test(
      "flatMap mix empties middle",
      VarArray.flatMap<Nat, Nat>(
        [var 0, 1, 2, 0, 0, 0, 1, 2, 3],
        func n = VarArray.tabulate<Nat>(n, func i = i).values()
      ),
      M.equals(varArray<Nat>(T.natTestable, [var 0, 0, 1, 0, 0, 1, 0, 1, 2]))
    ),
    Suite.test(
      "flatMap mix empties",
      VarArray.flatMap<Nat, Nat>(
        [var 0, 0, 0],
        func n = VarArray.tabulate<Nat>(n, func i = i).values()
      ),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    ),
    Suite.test(
      "flatMap mix empty",
      VarArray.flatMap<Nat, Nat>(
        [var],
        func n = VarArray.tabulate<Nat>(n, func i = i).values()
      ),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    ),
    Suite.test(
      "foldLeft",
      VarArray.foldLeft<Text, Text>([var "a", "b", "c"], "", Text.concat),
      M.equals(T.text("abc"))
    ),
    Suite.test(
      "foldLeft empty",
      VarArray.foldLeft<Text, Text>([var], "base", Text.concat),
      M.equals(T.text("base"))
    ),
    Suite.test(
      "foldRight",
      VarArray.foldRight<Text, Text>([var "a", "b", "c"], "", func(x, acc) = acc # x),
      M.equals(T.text("cba"))
    ),
    Suite.test(
      "foldRight empty",
      VarArray.foldRight<Text, Text>([var], "base", Text.concat),
      M.equals(T.text("base"))
    ),
    Suite.test(
      "flatten",
      VarArray.flatten<Int>([var [var 1, 2, 3], [var], [var 1]]),
      M.equals(varArray<Int>(T.intTestable, [var 1, 2, 3, 1]))
    ),
    Suite.test(
      "flatten empty start",
      VarArray.flatten<Int>([var [var], [var 1, 2, 3], [var], [var 1]]),
      M.equals(varArray<Int>(T.intTestable, [var 1, 2, 3, 1]))
    ),
    Suite.test(
      "flatten empty end",
      VarArray.flatten<Int>([var [var 1, 2, 3], [var], [var 1], [var]]),
      M.equals(varArray<Int>(T.intTestable, [var 1, 2, 3, 1]))
    ),
    Suite.test(
      "flatten singleton",
      VarArray.flatten<Int>([var [var 1, 2, 3]]),
      M.equals(varArray<Int>(T.intTestable, [var 1, 2, 3]))
    ),
    Suite.test(
      "flatten singleton empty",
      VarArray.flatten<Int>([var [var]]),
      M.equals(varArray<Int>(T.intTestable, [var]))
    ),
    Suite.test(
      "flatten empty",
      VarArray.flatten<Int>([var]),
      M.equals(varArray<Int>(T.intTestable, [var]))
    ),
    Suite.test(
      "make",
      VarArray.singleton<Int>(0),
      M.equals(varArray<Int>(T.intTestable, [var 0]))
    ),
    Suite.test(
      "values",
      do {
        var sum = 0;
        for (x in VarArray.values([var 1, 2, 3])) {
          sum += x
        };
        sum
      },
      M.equals(T.nat(6))
    ),
    Suite.test(
      "values empty",
      do {
        var sum = 0;
        for (x in VarArray.values([var])) {
          sum += x
        };
        sum
      },
      M.equals(T.nat(0))
    ),
    Suite.test(
      "keys",
      do {
        var sum = 0;
        for (x in VarArray.keys([var 1, 2, 3])) {
          sum += x
        };
        sum
      },
      M.equals(T.nat(3))
    ),
    Suite.test(
      "keys empty",
      do {
        var sum = 0;
        for (x in VarArray.keys([var])) {
          sum += x
        };
        sum
      },
      M.equals(T.nat(0))
    ),
    Suite.test(
      "sliceToArray if including entire array",
      VarArray.sliceToArray<Nat>([var 2, 4, 6, 8, 10], 0, 5),
      M.equals(T.array(T.natTestable, [2, 4, 6, 8, 10]))
    ),
    Suite.test(
      "sliceToArray if including all but last index",
      VarArray.sliceToArray<Nat>([var 2, 4, 6, 8, 10], 0, -1),
      M.equals(T.array(T.natTestable, [2, 4, 6, 8]))
    ),
    Suite.test(
      "sliceToArray if including all but first index",
      VarArray.sliceToArray<Nat>([var 2, 4, 6, 8, 10], 1, 5),
      M.equals(T.array(T.natTestable, [4, 6, 8, 10]))
    ),
    Suite.test(
      "sliceToArray if including middle of array",
      VarArray.sliceToArray<Nat>([var 2, 4, 6, 8, 10], 1, 4),
      M.equals(T.array(T.natTestable, [4, 6, 8]))
    ),
    Suite.test(
      "sliceToArray if including middle of array (negative indices)",
      VarArray.sliceToArray<Nat>([var 2, 4, 6, 8, 10], -4, -1),
      M.equals(T.array(T.natTestable, [4, 6, 8]))
    ),
    Suite.test(
      "sliceToArray if including start, but not end of array",
      VarArray.sliceToArray<Nat>([var 2, 4, 6, 8, 10], 0, -2),
      M.equals(T.array(T.natTestable, [2, 4, 6]))
    ),
    Suite.test(
      "sliceToArray if including end, but not start of array",
      VarArray.sliceToArray<Nat>([var 2, 4, 6, 8, 10], 2, 5),
      M.equals(T.array(T.natTestable, [6, 8, 10]))
    ),
    Suite.test(
      "sliceToArray if including end, but not start of array (negative indices)",
      VarArray.sliceToArray<Nat>([var 2, 4, 6, 8, 10], -3, 5),
      M.equals(T.array(T.natTestable, [6, 8, 10]))
    ),
    Suite.test(
      "nextIndexOf start",
      VarArray.nextIndexOf<Char>('c', [var 'c', 'o', 'f', 'f', 'e', 'e'], 0, Char.equal),
      M.equals(T.optional(T.natTestable, ?0))
    ),
    Suite.test(
      "nextIndexOf not found from offset",
      VarArray.nextIndexOf<Char>('c', [var 'c', 'o', 'f', 'f', 'e', 'e'], 1, Char.equal),
      M.equals(T.optional(T.natTestable, null : ?Nat))
    ),
    Suite.test(
      "nextIndexOf middle",
      VarArray.nextIndexOf<Char>('f', [var 'c', 'o', 'f', 'f', 'e', 'e'], 0, Char.equal),
      M.equals(T.optional(T.natTestable, ?2))
    ),
    Suite.test(
      "nextIndexOf repeat",
      VarArray.nextIndexOf<Char>('f', [var 'c', 'o', 'f', 'f', 'e', 'e'], 2, Char.equal),
      M.equals(T.optional(T.natTestable, ?2))
    ),
    Suite.test(
      "nextIndexOf start from the middle",
      VarArray.nextIndexOf<Char>('f', [var 'c', 'o', 'f', 'f', 'e', 'e'], 3, Char.equal),
      M.equals(T.optional(T.natTestable, ?3))
    ),
    Suite.test(
      "nextIndexOf not found",
      VarArray.nextIndexOf<Char>('g', [var 'c', 'o', 'f', 'f', 'e', 'e'], 0, Char.equal),
      M.equals(T.optional(T.natTestable, null : ?Nat))
    ),
    Suite.test(
      "nextIndexOf index out of bounds",
      VarArray.nextIndexOf<Char>('f', [var 'c', 'o', 'f', 'f', 'e', 'e'], 100, Char.equal),
      M.equals(T.optional(T.natTestable, null : ?Nat))
    ),

    Suite.test(
      "prevIndexOf first",
      VarArray.prevIndexOf<Char>('c', [var 'c', 'o', 'f', 'f', 'e', 'e'], 6, Char.equal),
      M.equals(T.optional(T.natTestable, ?0))
    ),
    Suite.test(
      "prevIndexOf last",
      VarArray.prevIndexOf<Char>('e', [var 'c', 'o', 'f', 'f', 'e', 'e'], 6, Char.equal),
      M.equals(T.optional(T.natTestable, ?5))
    ),
    Suite.test(
      "prevIndexOf middle",
      VarArray.prevIndexOf<Char>('f', [var 'c', 'o', 'f', 'f', 'e', 'e'], 6, Char.equal),
      M.equals(T.optional(T.natTestable, ?3))
    ),
    Suite.test(
      "prevIndexOf start from the middle",
      VarArray.prevIndexOf<Char>('f', [var 'c', 'o', 'f', 'f', 'e', 'e'], 3, Char.equal),
      M.equals(T.optional(T.natTestable, ?2))
    ),
    Suite.test(
      "prevIndexOf existing not found",
      VarArray.prevIndexOf<Char>('f', [var 'c', 'o', 'f', 'f', 'e', 'e'], 2, Char.equal),
      M.equals(T.optional(T.natTestable, null : ?Nat))
    ),
    Suite.test(
      "prevIndexOf not found",
      VarArray.prevIndexOf<Char>('g', [var 'c', 'o', 'f', 'f', 'e', 'e'], 6, Char.equal),
      M.equals(T.optional(T.natTestable, null : ?Nat))
    ),
    Suite.test(
      "Iter conversions",
      VarArray.fromIter<Nat>(VarArray.values([var 1, 2, 3])),
      M.equals(varArray<Nat>(T.natTestable, [var 1, 2, 3]))
    ),
    Suite.test(
      "Iter conversions empty",
      VarArray.fromIter<Nat>(VarArray.values([var])),
      M.equals(varArray<Nat>(T.natTestable, [var]))
    )
  ]
);

Suite.run(suite)
