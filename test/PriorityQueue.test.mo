import PriorityQueue "../src/Queue";

import { suite; test; expect } "mo:test";
import Suite "mo:matchers/Suite";
import T "mo:matchers/Testable";
import M "mo:matchers/Matchers";

suite(
  "empty",
  func() {
    test(
      "size",
      func() {
        assert PriorityQueue.size(PriorityQueue.empty<Nat>()) == 0
      }
    );

    test(
      "is empty",
      func() {
        assert PriorityQueue.isEmpty(PriorityQueue.empty<Nat>())
      }
    );

    test(
      "peek",
      func() {
        assert PriorityQueue.peek(PriorityQueue.empty<Nat>()) == null
      }
    );

    test(
      "pop",
      func() {
        assert PriorityQueue.pop(PriorityQueue.empty<Nat>()) == null
      }
    );


    test(
      "clear",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(0);
        PriorityQueue.clear(priorityQueue);
        expect.nat(PriorityQueue.size(priorityQueue)).equal(0)
      }
    );
  }
);

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
        assert not PriorityQueue.isEmpty(PriorityQueue.singleton<Nat>(42))
      }
    );

    test(
      "peek",
      func() {
        assert PriorityQueue.peek(PriorityQueue.singleton<Nat>(42)) == ?42
      }
    );

    test(
      "pop",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(42);
        let top = PriorityQueue.popFront(priorityQueue);
        assert PriorityQueue.isEmpty(priorityQueue);
        assert top == ?42
      }
    );

    test(
      "clear",
      func() {
        let priorityQueue = PriorityQueue.singleton<Nat>(42);
        PriorityQueue.clear(priorityQueue);
        expect.nat(PriorityQueue.size(priorityQueue)).equal(0)
      }
    );
  }
);