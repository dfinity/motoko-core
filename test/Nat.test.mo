import Nat "../src/Nat";
import Array "../src/Array";
import { test } "mo:test";

test(
  "add",
  func() {
    assert Nat.add(1, Nat.add(2, 3)) == Nat.add(1, Nat.add(2, 3));
    assert Nat.add(0, 1) == 1;
    assert 1 == Nat.add(1, 0);
    assert Nat.add(0, 1) == Nat.add(1, 0);
    assert Nat.add(1, 2) == Nat.add(2, 1)
  }
);

test(
  "shift",
  func() {
    assert Nat.bitshiftLeft(1234567890, 3) == 1234567890 * 8;
    assert Nat.bitshiftRight(1234567892, 2) == 1234567892 / 4
  }
);

test(
  "toText",
  func() {
    assert Nat.toText(0) == "0";
    assert Nat.toText(1234) == "1234"
  }
);

test(
  "range",
  func() {
    assert Array.fromIter(Nat.range(0, 3)) == [0, 1, 2];
    assert Array.fromIter(Nat.range(1, 3)) == [1, 2];
    assert Array.fromIter(Nat.range(1, 2)) == [1];
    assert Array.fromIter(Nat.range(3, 0)) == [];
    assert Array.fromIter(Nat.range(1, 0)) == [];
    assert Array.fromIter(Nat.range(0, 0)) == []
  }
);

test(
  "rangeBy",
  func() {
    assert Array.fromIter(Nat.rangeBy(0, 3, 1)) == [0, 1, 2];
    assert Array.fromIter(Nat.rangeBy(0, 3, 2)) == [0, 2];
    assert Array.fromIter(Nat.rangeBy(0, 3, 3)) == [0];
    assert Array.fromIter(Nat.rangeBy(1, 4, 2)) == [1, 3];
    assert Array.fromIter(Nat.rangeBy(1, 3, 2)) == [1];
    assert Array.fromIter(Nat.rangeBy(3, 0, -1)) == [3, 2, 1];
    assert Array.fromIter(Nat.rangeBy(3, 1, -1)) == [3, 2];
    assert Array.fromIter(Nat.rangeBy(3, 0, -2)) == [3, 1];
    assert Array.fromIter(Nat.rangeBy(3, 1, -2)) == [3];
    assert Array.fromIter(Nat.rangeBy(1, 3, -1)) == [];
    assert Array.fromIter(Nat.rangeBy(0, 1, 0)) == [];
    assert Array.fromIter(Nat.rangeBy(1, 0, 0)) == []
  }
);

test(
  "rangeByInclusive",
  func() {
    assert Array.fromIter(Nat.rangeByInclusive(1, 7, 2)) == [1, 3, 5, 7];
    assert Array.fromIter(Nat.rangeByInclusive(1, 6, 2)) == [1, 3, 5];
    assert Array.fromIter(Nat.rangeByInclusive(1, 3, 1)) == [1, 2, 3];

    assert Array.fromIter(Nat.rangeByInclusive(7, 1, -2)) == [7, 5, 3, 1];
    assert Array.fromIter(Nat.rangeByInclusive(6, 1, -2)) == [6, 4, 2];
    assert Array.fromIter(Nat.rangeByInclusive(3, 1, -1)) == [3, 2, 1];

    assert Array.fromIter(Nat.rangeByInclusive(1, 1, 1)) == [1];
    assert Array.fromIter(Nat.rangeByInclusive(1, 1, -1)) == [1];
    assert Array.fromIter(Nat.rangeByInclusive(1, 2, 0)) == [];
    assert Array.fromIter(Nat.rangeByInclusive(2, 1, 1)) == [];
    assert Array.fromIter(Nat.rangeByInclusive(1, 2, -1)) == []
  }
)
