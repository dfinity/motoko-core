import Queue "../../src/pure/Queue";
import Array "../../src/Array";
import Nat "../../src/Nat";
import Iter "../../src/Iter";
import Prim "mo:prim";
import { suite; test; expect } = "mo:test";

func iterateForward<T>(queue : Queue.Queue<T>) : Iter.Iter<T> {
  var current = queue;
  object {
    public func next() : ?T {
      switch (Queue.popFront(current)) {
        case null null;
        case (?result) {
          current := result.1;
          ?result.0
        }
      }
    }
  }
};

func iterateBackward<T>(queue : Queue.Queue<T>) : Iter.Iter<T> {
  var current = queue;
  object {
    public func next() : ?T {
      switch (Queue.popBack(current)) {
        case null null;
        case (?result) {
          current := result.0;
          ?result.1
        }
      }
    }
  }
};

func frontToText(t : (Nat, Queue.Queue<Nat>)) : Text {
  "(" # Nat.toText(t.0) # ", " # Queue.toText(t.1, Nat.toText) # ")"
};

func frontEqual(t1 : (Nat, Queue.Queue<Nat>), t2 : (Nat, Queue.Queue<Nat>)) : Bool {
  t1.0 == t2.0 and Queue.equal(t1.1, t2.1, Nat.equal)
};

func backToText(t : (Queue.Queue<Nat>, Nat)) : Text {
  "(" # Queue.toText(t.0, Nat.toText) # ", " # Nat.toText(t.1) # ")"
};

func backEqual(t1 : (Queue.Queue<Nat>, Nat), t2 : (Queue.Queue<Nat>, Nat)) : Bool {
  t1.1 == t2.1 and Queue.equal(t1.0, t2.0, Nat.equal)
};

func reduceFront<T>(queue : Queue.Queue<T>, amount : Nat) : Queue.Queue<T> {
  var current = queue;
  for (_ in Nat.range(0, amount)) {
    switch (Queue.popFront(current)) {
      case null Prim.trap("should not be null");
      case (?result) current := result.1
    }
  };
  current
};

func reduceBack<T>(queue : Queue.Queue<T>, amount : Nat) : Queue.Queue<T> {
  var current = queue;
  for (_ in Nat.range(0, amount)) {
    switch (Queue.popBack(current)) {
      case null Prim.trap("should not be null");
      case (?result) current := result.0
    }
  };
  current
};

var queue = Queue.empty<Nat>();

suite(
  "construct",
  func() {
    test(
      "empty",
      func() {
        expect.bool(Queue.isEmpty(queue)).isTrue()
      }
    );

    test(
      "iterate forward",
      func() {
        expect.array<Nat>(Iter.toArray(iterateForward(queue)), Nat.toText, Nat.equal).size(0)
      }
    );

    test(
      "iterate backward",
      func() {
        expect.array(Iter.toArray(iterateBackward(queue)), Nat.toText, Nat.equal).size(0)
      }
    );

    test(
      "peek front",
      func() {
        expect.option(Queue.peekFront(queue), Nat.toText, Nat.equal).isNull()
      }
    );

    test(
      "peek back",
      func() {
        expect.option(Queue.peekBack(queue), Nat.toText, Nat.equal).isNull()
      }
    );

    test(
      "pop front",
      func() {
        expect.option(
          Queue.popFront(queue),
          frontToText,
          frontEqual
        ).isNull()
      }
    );

    test(
      "pop back",
      func() {
        expect.option(
          Queue.popBack(queue),
          backToText,
          backEqual
        ).isNull()
      }
    )
  }
);

queue := Queue.pushFront(Queue.empty<Nat>(), 1);

suite(
  "single item",
  func() {
    test(
      "not empty",
      func() {
        expect.bool(Queue.isEmpty(queue)).isFalse()
      }
    );

    test(
      "iterate forward",
      func() {
        expect.array(Iter.toArray(iterateForward(queue)), Nat.toText, Nat.equal).equal([1])
      }
    );

    test(
      "iterate backward",
      func() {
        expect.array(Iter.toArray(iterateBackward(queue)), Nat.toText, Nat.equal).equal([1])
      }
    );

    test(
      "peek front",
      func() {
        expect.option(Queue.peekFront(queue), Nat.toText, Nat.equal).equal(?1)
      }
    );

    test(
      "peek back",
      func() {
        expect.option(Queue.peekBack(queue), Nat.toText, Nat.equal).equal(?1)
      }
    );

    test(
      "pop front",
      func() {
        expect.option(
          Queue.popFront(queue),
          frontToText,
          frontEqual
        ).equal(?(1, Queue.empty()))
      }
    );

    test(
      "pop back",
      func() {
        expect.option(
          Queue.popBack(queue),
          backToText,
          backEqual
        ).equal(?(Queue.empty(), 1))
      }
    )
  }
);

let testSize = 100;

func populateForward(from : Nat, to : Nat) : Queue.Queue<Nat> {
  var queue = Queue.empty<Nat>();
  for (number in Nat.range(from, to)) {
    queue := Queue.pushFront(queue, number)
  };
  queue
};

queue := populateForward(1, testSize + 1);

suite(
  "forward insertion",
  func() {
    test(
      "not empty",
      func() {
        expect.bool(Queue.isEmpty(queue)).isFalse()
      }
    );

    test(
      "iterate forward",
      func() {
        expect.array(
          Iter.toArray(iterateForward(queue)),
          Nat.toText,
          Nat.equal
        ).equal(
          Array.tabulate(
            testSize,
            func(index : Nat) : Nat {
              testSize - index
            }
          )
        )
      }
    );

    test(
      "iterate backward",
      func() {
        expect.array(
          Iter.toArray(iterateBackward(queue)),
          Nat.toText,
          Nat.equal
        ).equal(
          Array.tabulate(
            testSize,
            func(index : Nat) : Nat {
              index + 1
            }
          )
        )
      }
    );

    test(
      "peek front",
      func() {
        expect.option(Queue.peekFront(queue), Nat.toText, Nat.equal).equal(?testSize)
      }
    );

    test(
      "peek back",
      func() {
        expect.option(Queue.peekBack(queue), Nat.toText, Nat.equal).equal(?1)
      }
    );

    test(
      "pop front",
      func() {
        expect.option(
          Queue.popFront(queue),
          frontToText,
          frontEqual
        ).equal(?(testSize, populateForward(1, testSize)))
      }
    );

    test(
      "empty after front removal",
      func() {
        expect.bool(Queue.isEmpty(reduceFront(queue, testSize))).isTrue()
      }
    );

    test(
      "empty after back removal",
      func() {
        expect.bool(Queue.isEmpty(reduceBack(queue, testSize))).isTrue()
      }
    )
  }
);

func populateBackward(from : Nat, to : Nat) : Queue.Queue<Nat> {
  var queue = Queue.empty<Nat>();
  for (number in Nat.range(from, to)) {
    queue := Queue.pushBack(queue, number)
  };
  queue
};

queue := populateBackward(1, testSize + 1);

suite(
  "backward insertion",
  func() {
    test(
      "not empty",
      func() {
        expect.bool(Queue.isEmpty(queue)).isFalse()
      }
    );

    test(
      "iterate forward",
      func() {
        expect.array(
          Iter.toArray(iterateForward(queue)),
          Nat.toText,
          Nat.equal
        ).equal(
          Array.tabulate(
            testSize,
            func(index : Nat) : Nat {
              index + 1
            }
          )
        )
      }
    );

    test(
      "iterate backward",
      func() {
        expect.array(
          Iter.toArray(iterateBackward(queue)),
          Nat.toText,
          Nat.equal
        ).equal(
          Array.tabulate(
            testSize,
            func(index : Nat) : Nat {
              testSize - index
            }
          )
        )
      }
    );

    test(
      "peek front",
      func() {
        expect.option(Queue.peekFront(queue), Nat.toText, Nat.equal).equal(?1)
      }
    );

    test(
      "peek back",
      func() {
        expect.option(Queue.peekBack(queue), Nat.toText, Nat.equal).equal(?testSize)
      }
    );

    test(
      "pop front",
      func() {
        expect.option(
          Queue.popFront(queue),
          frontToText,
          frontEqual
        ).equal(?(1, populateBackward(2, testSize + 1)))
      }
    );

    test(
      "pop back",
      func() {
        expect.option(
          Queue.popBack(queue),
          backToText,
          backEqual
        ).equal(?(populateBackward(1, testSize), testSize))
      }
    );

    test(
      "empty after front removal",
      func() {
        expect.bool(Queue.isEmpty(reduceFront(queue, testSize))).isTrue()
      }
    );

    test(
      "empty after back removal",
      func() {
        expect.bool(Queue.isEmpty(reduceBack(queue, testSize))).isTrue()
      }
    )
  }
);

object Random {
  var number = 4711;
  public func next() : Int {
    number := (123138118391 * number + 133489131) % 9999;
    number
  }
};

func randomPopulate(amount : Nat) : Queue.Queue<Nat> {
  var current = Queue.empty<Nat>();
  for (number in Nat.range(0, amount)) {
    current := if (Random.next() % 2 == 0) {
      Queue.pushFront(current, Nat.sub(amount, number))
    } else {
      Queue.pushBack(current, amount + number)
    }
  };
  current
};

func isSorted(queue : Queue.Queue<Nat>) : Bool {
  let array = Iter.toArray(iterateForward(queue));
  let sorted = Array.sort(array, Nat.compare);
  Array.equal(array, sorted, Nat.equal)
};

func randomRemoval(queue : Queue.Queue<Nat>, amount : Nat) : Queue.Queue<Nat> {
  var current = queue;
  for (number in Nat.range(0, amount)) {
    current := if (Random.next() % 2 == 0) {
      let pair = Queue.popFront(current);
      switch pair {
        case null Prim.trap("should not be null");
        case (?result) result.1
      }
    } else {
      let pair = Queue.popBack(current);
      switch pair {
        case null Prim.trap("should not be null");
        case (?result) result.0
      }
    }
  };
  current
};

queue := randomPopulate(testSize);

suite(
  "random insertion",
  func() {
    test(
      "not empty",
      func() {
        expect.bool(Queue.isEmpty(queue)).isFalse()
      }
    );

    test(
      "correct order",
      func() {
        expect.bool(isSorted(queue)).isTrue()
      }
    );

    test(
      "consistent iteration",
      func() {
        expect.array(
          Iter.toArray(iterateForward(queue)),
          Nat.toText,
          Nat.equal
        ).equal(Array.reverse(Iter.toArray(iterateBackward(queue))))
      }
    );

    test(
      "random quarter removal",
      func() {
        expect.bool(isSorted(randomRemoval(queue, testSize / 4))).isTrue()
      }
    );

    test(
      "random half removal",
      func() {
        expect.bool(isSorted(randomRemoval(queue, testSize / 2))).isTrue()
      }
    );

    test(
      "random three quarter removal",
      func() {
        expect.bool(isSorted(randomRemoval(queue, testSize * 3 / 4))).isTrue()
      }
    );

    test(
      "random total removal",
      func() {
        expect.bool(Queue.isEmpty(randomRemoval(queue, testSize))).isTrue()
      }
    )
  }
);

func randomInsertionDeletion(steps : Nat) : Queue.Queue<Nat> {
  var current = Queue.empty<Nat>();
  var size = 0;
  for (number in Nat.range(0, steps - 1)) {
    let random = Random.next();
    current := switch (random % 4) {
      case 0 {
        size += 1;
        Queue.pushFront(current, Nat.sub(steps, number))
      };
      case 1 {
        size += 1;
        Queue.pushBack(current, steps + number)
      };
      case 2 {
        switch (Queue.popFront(current)) {
          case null {
            assert (size == 0);
            current
          };
          case (?result) {
            size -= 1;
            result.1
          }
        }
      };
      case 3 {
        switch (Queue.popBack(current)) {
          case null {
            assert (size == 0);
            current
          };
          case (?result) {
            size -= 1;
            result.0
          }
        }
      };
      case _ Prim.trap("Impossible case")
    };
    assert (isSorted(current))
  };
  current
};

suite(
  "completely random",
  func() {
    test(
      "random insertion and deletion",
      func() {
        expect.bool(isSorted(randomInsertionDeletion(1000))).isTrue()
      }
    )
  }
)
