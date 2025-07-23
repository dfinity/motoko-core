# Changelog

## 0.4.1

* Update readme

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
* Fix bug in `Iter.step()` (#222).

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
