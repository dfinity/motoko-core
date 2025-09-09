import PriorityQueue "../src/PriorityQueue";
import Nat "../src/Nat";
import Iter "../src/Iter";
import Runtime "../src/Runtime";
import Array "../src/Array";
import VarArray "../src/VarArray";
import Set "../src/Set";
import Random "../src/Random";
import { Tuple2 } "../src/Tuples";
import Order "../src/Order";

import { suite; test; expect } "mo:test";

suite(
  "empty",
  func() {
    test(
      "size",
      func() {
        expect.nat(PriorityQueue.size(PriorityQueue.empty<Nat>())).equal(0)
      }
    );

    test(
      "is empty",
      func() {
        expect.bool(PriorityQueue.isEmpty(PriorityQueue.empty<Nat>())).equal(true)
      }
    );

    test(
      "push",
      func() {
        let priorityQueue = PriorityQueue.empty<Nat>();
        PriorityQueue.push(priorityQueue, Nat.compare, 42);
        expect.nat(PriorityQueue.size(priorityQueue)).equal(1);
        let top = PriorityQueue.peek(priorityQueue);
        expect.option<Nat>(top, Nat.toText, Nat.equal).equal(?42)
      }
    );

    test(
      "peek",
      func() {
        let priorityQueue = PriorityQueue.empty<Nat>();
        let top = PriorityQueue.peek(priorityQueue);
        expect.bool(PriorityQueue.isEmpty(priorityQueue)).equal(true);
        expect.option<Nat>(top, Nat.toText, Nat.equal).equal(null)
      }
    );

    test(
      "pop",
      func() {
        let priorityQueue = PriorityQueue.empty<Nat>();
        let top = PriorityQueue.pop(priorityQueue, Nat.compare);
        expect.bool(PriorityQueue.isEmpty(priorityQueue)).equal(true);
        expect.option<Nat>(top, Nat.toText, Nat.equal).equal(null)
      }
    );

    test(
      "clear",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(0);
        PriorityQueue.clear(priorityQueue);
        expect.bool(PriorityQueue.isEmpty(priorityQueue)).equal(true)
      }
    )
  }
);

// TODO: add boxed int!

suite(
  "singleton",
  func() {
    test(
      "size",
      func() {
        expect.nat(PriorityQueue.size(PriorityQueue.singleton<Nat>(42))).equal(1)
      }
    );

    test(
      "is empty",
      func() {
        expect.bool(PriorityQueue.isEmpty(PriorityQueue.singleton<Nat>(42))).equal(false)
      }
    );

    test(
      "push smaller",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(42);
        PriorityQueue.push(priorityQueue, Nat.compare, 41);
        expect.nat(PriorityQueue.size(priorityQueue)).equal(2);
        let top = PriorityQueue.peek(priorityQueue);
        expect.option<Nat>(top, Nat.toText, Nat.equal).equal(?42)
      }
    );

    test(
      "push equal",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(42);
        PriorityQueue.push(priorityQueue, Nat.compare, 42);
        expect.nat(PriorityQueue.size(priorityQueue)).equal(2);
        let top = PriorityQueue.peek(priorityQueue);
        expect.option<Nat>(top, Nat.toText, Nat.equal).equal(?42)
      }
    );

    test(
      "push larger",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(42);
        PriorityQueue.push(priorityQueue, Nat.compare, 43);
        expect.nat(PriorityQueue.size(priorityQueue)).equal(2);
        let top = PriorityQueue.peek(priorityQueue);
        expect.option<Nat>(top, Nat.toText, Nat.equal).equal(?43)
      }
    );

    test(
      "peek",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(42);
        let top = PriorityQueue.peek(priorityQueue);
        expect.nat(PriorityQueue.size(priorityQueue)).equal(1);
        expect.option<Nat>(top, Nat.toText, Nat.equal).equal(?42)
      }
    );

    test(
      "pop",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(42);
        let top = PriorityQueue.pop(priorityQueue, Nat.compare);
        expect.bool(PriorityQueue.isEmpty(priorityQueue)).equal(true);
        expect.option<Nat>(top, Nat.toText, Nat.equal).equal(?42)
      }
    );

    test(
      "clear",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(42);
        PriorityQueue.clear(priorityQueue);
        expect.bool(PriorityQueue.isEmpty(priorityQueue)).equal(true)
      }
    )
  }
);

func testPushAndPeekThenPopArrayNat(values : [Nat]) {
  let priorityQueue = PriorityQueue.empty<Nat>();

  for ((i, v) in Iter.enumerate(values.values())) {
    PriorityQueue.push(priorityQueue, Nat.compare, v);
    expect.nat(PriorityQueue.size(priorityQueue)).equal(i + 1);
    let top = PriorityQueue.peek(priorityQueue);
    expect.option<Nat>(top, Nat.toText, Nat.equal).equal(
      values.values()
      |> Iter.take(_, i + 1) |> Iter.max(_, Nat.compare)
    )
  };

  let extractedValues = VarArray.repeat<Nat>(0, values.size());
  for (i in Nat.range(0, values.size())) {
    let ?top = PriorityQueue.pop(priorityQueue, Nat.compare) else Runtime.trap("priorityQueue unexpectedly empty");
    extractedValues[i] := top;
    expect.nat(PriorityQueue.size(priorityQueue)).equal(values.size() - i - 1)
  };

  expect.array<Nat>(Array.fromVarArray(extractedValues), Nat.toText, Nat.equal).equal(
    Array.sort(values, Nat.compare) |> Array.reverse(_)
  )
};

suite(
  "push & peek, then pop",
  func() {
    test(
      "v1",
      func() {
        testPushAndPeekThenPopArrayNat([3, 5, 2, 1, 4])
      }
    );
    test(
      "v2",
      func() {
        testPushAndPeekThenPopArrayNat([10, 3, 1, 13])
      }
    );
    test(
      "v3",
      func() {
        testPushAndPeekThenPopArrayNat([10, 3, 1, 10, 2, 1])
      }
    );
    test(
      "v4",
      func() {
        testPushAndPeekThenPopArrayNat([10, 3, 1, 7, 10, 2, 1, 7, 7, 13, 1, 1, 3])
      }
    )
  }
);

type PriorityQueueUpdateOperation = {
  #Push : Nat;
  #Pop;
  #Clear
};

type PriorityQueueQueryOperation = {
  #IsEmpty;
  #Size;
  #Peek
};

class SetPriorityQueue<T>() {
  let set = Set.empty<(T, Nat)>();
  var counter = 0;

  public func isEmpty() : Bool = Set.isEmpty<(T, Nat)>(set);
  public func size() : Nat = Set.size<(T, Nat)>(set);
  public func peek() : ?T = do ? {
    let (element, _) = Set.max<(T, Nat)>(set)!;
    element
  };
  public func pop(compare : (T, T) -> Order.Order) : ?T = do ? {
    let (element, nonce) = Set.max<(T, Nat)>(set)!;
    Set.add(set, Tuple2.makeCompare<T, Nat>(compare, Nat.compare), (element, nonce));
    element
  };
  public func push(compare : (T, T) -> Order.Order, element : T) {
    Set.add(set, Tuple2.makeCompare<T, Nat>(compare, Nat.compare), (element, counter));
    counter += 1
  }
};

// func generatePriorityQueueUpdateOperations(randomSeed : Nat64, maxValue : Nat, wPush : Nat, wPop, wClear : Nat) : [PriorityQueueUpdateOperation] {
//   return [];
// };

// Can make the "Set" variant work easily by generating synthetic IDs (counter += 1).
// I can make an interator that gives all, or random values, done! (for generating random and generating backtracking).

suite(
  "random",
  func() {
    test(
      "v1",
      func() {
        let operationsCount = 10000;
        let randomSeed : Nat64 = 666013;
        let maxValue = 9;
        let rng = Random.seed(randomSeed);
        let priorityQueue = PriorityQueue.empty<Nat>();
        let set = Set.empty<(Nat, Nat)>();
        for (opId in Nat.range(0, operationsCount)) {
          // is empty, size, push, peek, pop, clear.
          // Choose between.
          // push
          // pop
          // clear
          // Always do peek (expected to be immutable, like const in C++)
          // Always do size.
          // Always do is_empty.

        }
      }
    )
  }
)
