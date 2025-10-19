## Next

* Add `forEachRange` to `List` (#411).
* **Breaking:** Rename `sort` to `sortInPlace`, add `sort` (#405).
* Add `isCleanReject` to `Error`, align reject code order with IC interface specification and improve comments (#401).
* internal: updates `matchers` dev-dependency (#394).
* Add `PriorityQueue` (#392).
* Add support for Weak references (#388).
* Clarify difference between `List` and `pure/List` in doc comments (#386).

## 1.0.0

* Add `sliceToVarArray()` to `Array` and `VarArray` (#377).
* **Breaking:** Standardize function argument order (#376).
* Add `binarySearch()` to `Array`, `VarArray`, and `List` modules (#375).
* Add example usage documentation to `Types` module (#374).
* Address inconsistent treatment of empty iterators by range functions in `Int` and `Nat` (#369).
* Fix corner cases in `Nat.rangeByInclusive()` (#368).
* **Breaking:** Rename `List.get()` to `List.at()` and `List.getOpt()` to `List.get()` (#367).
* Add `Text.foldLeft()` (#366).
* **Breaking:** Adjust `Int.fromText()` to return `null` instead of `?0` for `"+"` and `"-"` (#365).
* Fix corner case in `sliceToArray()` (#364).
* Add `uniform64()`, `nat64()`, `natRange()`, and `intRange()` to `AsyncRandom` class (#360).
* Make `Nat.toText()` slightly more performant (#358).

## 0.6.0

* Update style guidelines (#353).
* Add `Text.reverse()` (#351).
* Add `fromArray()` and `toArray()` to `Queue` and `pure/Queue` (#349).
* Add `explode()` to `Int16`/`32`/`64`, `Nat16`/`32`/`64`, slicing fixed-length numbers into constituent bytes (#346).
* Fix a typo in the `VarArray` documentation (#338).
* Fix a bug in `List.last()` (#336). 
* Perf: Uses the new `Array_tabulateVar` primitive to speed up various function in `VarArray` (#334).
* **Breaking:** Enable persistence of `Random` and `AsyncRandom` state in stable memory (#329).

## 0.5.0

* **Breaking:** Adjust `List` and `pure/List` APIs for consistency (#322).
* Fix: `first()` and `last()` from `List` now return `null` on empty lists instead of trapping (#312).
* Add `reverse()` function to the `pure/Queue` module (#229).
* Add `pure/RealTimeQueue` module - an alternative immutable double-ended queue implementation with worst-case `O(1)` time complexity for all operations but worse amortized performance (#229).
  * Refer to the `Queues.bench.mo` benchmark for comparison with other queue implementations.
* Rename `Map.replaceIfExists()` to `Map.replace()` (#286).
* Add `entriesFrom()` and `reverseEntriesFrom()` to `Map`, `valuesFrom()` and `reverseValuesFrom()` to `Set` and `Text.toText()` (#272).
* Update code examples in doc comments (#224, #282, #303, #315).
* Add `findIndex()` function to modules with `find()` (#321).

## 0.4.0

* Add `isReplicated : () -> Bool` to `InternetComputer` (#213).
* Use `Order` type instead of the inlined variant (#270).
* Fix argument order for `Result.compare()` and `Result.equal()` (#268).
* Add `isEmpty : _ -> Bool` to `Blob` and `Text` (#263).
* Make `pure/List` and `pure/Queue` stack-safe (#252).
* Optimize `Iter.reverse` (#266).
* Fix List growing bug (#251).
* Improve `Iter.mo` with new functions and documentation (#231).
* Adjust `Random` representation to allow persistence in stable memory (#226).
* Fix bug in `Array.enumerate()` and `VarArray.enumerate()` (#233).
* Add `burn : <system>Nat -> Nat` to `Cycles` (#228).
* Fix bug in `Iter.step()`
* Fix bug in `Array.enumerate()` / `VarArray.enumerate()`
* Adjust `Random` representation to allow persistence in stable memory
* Add `Tuples` module

## 0.3.0

* Rename `List.push()` to `pushFront()` and `List.pop()` to `popFront()` (#219).

## 0.2.2

* Add range functions to `Random.crypto()` (#215).
* Add `isRetryPossible : Error -> Bool` to `Error` (#211).

## 0.2.1

* Cleanups in `pure/List` test, fixes and docstrings in `pure/Queue`
* Bump `motoko-matchers` to 1.3.1

## 0.2.0

* Make `replyDeadline` an optional return type

## 0.1.1

* Update readme

## 0.1.0

* Initial release
