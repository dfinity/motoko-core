import Bench "mo:bench";

import Array "../src/Array";
import Nat "../src/Nat";
import PriorityQueue "../src/PriorityQueue";
import PriorityQueueSet "../src/PriorityQueueSet";
import Random "../src/Random";
import Runtime "../src/Runtime";
import Map "../src/Map";
import Text "../src/Text";

module {

  type PriorityQueueUpdateOperation<T> = {
    #Push : T;
    #Pop;
    #Clear
  };

  // Generates a randomized sequence of PriorityQueueUpdateOperations on Nat values.
  // The distribution of operations is controlled by weights.
  //
  // randomSeed        - seed for reproducible RNG
  // operationsCount   – total number of operations to generate
  // maxValueExclusive – upper bound (exclusive) for values pushed into the queue
  // wPush             – relative weight of #Push operations (values in [0, maxValueExclusive))
  // wPop              – relative weight of #Pop operations
  // wClear            – relative weight of #Clear operations
  func genOpsNatRandom(
    randomSeed : Nat64,
    operationsCount : Nat,
    maxValueExclusive : Nat,
    wPush : Nat,
    wPop : Nat,
    wClear : Nat
  ) : [PriorityQueueUpdateOperation<Nat>] {
    let rng = Random.seed(randomSeed);
    Array.tabulate<PriorityQueueUpdateOperation<Nat>>(
      operationsCount,
      func(_) {
        let aux = rng.natRange(0, wPush + wPop + wClear);
        if (aux < wPush) {
          #Push(rng.natRange(0, maxValueExclusive))
        } else if (aux < wPush + wPop) {
          #Pop
        } else {
          #Clear
        }
      }
    )
  };

  public func init() : Bench.Bench {
    let bench = Bench.Bench();

    bench.name("Different priority queue implementations");
    bench.description("Compare the performance of the following priority queue implementations_:
- `PriorityQueue`: Binary heap implementation over `List`.
- `PriorityQueueSet`: Wrapper over `Set<(T, Nat)`.");

    let testInstances : Map.Map<Text, [PriorityQueueUpdateOperation<Nat>]> = Map.fromIter(
      [
        (
          "1.) 100000 operations (push:pop = 1:1)",
          genOpsNatRandom(
            /* randomSeed = */ 23,
            /* operationsCount = */ 100000,
            /* maxValueExclusive = */ 100000,
            /* wPush = */ 1,
            /* wPop = */ 1,
            /* wClear = */ 0
          )
        ),
        (
          "2.) 100000 operations (push:pop = 10:1)",
          genOpsNatRandom(
            /* randomSeed = */ 42,
            /* operationsCount = */ 100000,
            /* maxValueExclusive = */ 100000,
            /* wPush = */ 10,
            /* wPop = */ 1,
            /* wClear = */ 0
          )
        ),
        (
          "3.) 100000 operations (only push)",
          genOpsNatRandom(
            /* randomSeed = */ 33,
            /* operationsCount = */ 100000,
            /* maxValueExclusive = */ 100000,
            /* wPush = */ 10,
            /* wPop = */ 0,
            /* wClear = */ 0
          )
        )
      ].values(),
      Text.compare
    );
    bench.rows(Map.keys<Text, [PriorityQueueUpdateOperation<Nat>]>(testInstances) |> Array.fromIter(_));

    let testRunners : Map.Map<Text, [PriorityQueueUpdateOperation<Nat>] -> ()> = Map.fromIter(
      [
        (
          "A) PriorityQueue",
          func(ops : [PriorityQueueUpdateOperation<Nat>]) {
            let priorityQueue = PriorityQueue.empty<Nat>();
            for (op in ops.values()) {
              switch (op) {
                case (#Push element) PriorityQueue.push(priorityQueue, Nat.compare, element);
                case (#Pop) ignore PriorityQueue.pop(priorityQueue, Nat.compare);
                case (#Clear) PriorityQueue.clear(priorityQueue)
              }
            }
          }
        ),
        (
          "A2) PriorityQueue better push",
          func(ops : [PriorityQueueUpdateOperation<Nat>]) {
            let priorityQueue = PriorityQueue.empty<Nat>();
            for (op in ops.values()) {
              switch (op) {
                case (#Push element) PriorityQueue.pushBetter(priorityQueue, Nat.compare, element);
                case (#Pop) ignore PriorityQueue.pop(priorityQueue, Nat.compare);
                case (#Clear) PriorityQueue.clear(priorityQueue)
              }
            }
          }
        ),
        (
          "A3) PriorityQueue better push, better pop",
          func(ops : [PriorityQueueUpdateOperation<Nat>]) {
            let priorityQueue = PriorityQueue.empty<Nat>();
            for (op in ops.values()) {
              switch (op) {
                case (#Push element) PriorityQueue.pushBetter(priorityQueue, Nat.compare, element);
                case (#Pop) ignore PriorityQueue.popBetter(priorityQueue, Nat.compare);
                case (#Clear) PriorityQueue.clear(priorityQueue)
              }
            }
          }
        ),
        (
          "B) PriorityQueueSet",
          func(ops : [PriorityQueueUpdateOperation<Nat>]) {
            let priorityQueueSet = PriorityQueueSet.empty<Nat>();
            for (op in ops.values()) {
              switch (op) {
                case (#Push element) PriorityQueueSet.push(priorityQueueSet, Nat.compare, element);
                case (#Pop) ignore PriorityQueueSet.pop(priorityQueueSet, Nat.compare);
                case (#Clear) PriorityQueueSet.clear(priorityQueueSet)
              }
            }
          }
        )
      ].values(),
      Text.compare
    );
    bench.cols(Map.keys<Text, [PriorityQueueUpdateOperation<Nat>] -> ()>(testRunners) |> Array.fromIter(_));

    bench.runner(
      func(row, col) {
        switch (
          Map.get(testInstances, Text.compare, row),
          Map.get(testRunners, Text.compare, col)
        ) {
          case (?ops, ?runner) runner(ops);
          case _ Runtime.trap("Missing test instance or runner")
        }
      }
    );
    bench
  }
}
