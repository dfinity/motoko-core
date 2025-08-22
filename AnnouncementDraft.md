Hello Motoko devs!

As you might have already heard, the Languages team overhauled the Motoko standard library (originally named `base`) to make it simpler for both humans and AI to understand and write Motoko programs.

## Relevant links

* [GitHub repository](https://github.com/dfinity/motoko-core)
* [Mops package](https://mops.one/core)
* [Documentation](https://internetcomputer.org/docs/motoko/core/)
* [Migration guide from `base` to `core`](https://internetcomputer.org/docs/motoko/base-core-migration)

## Summary of changes

* New imperative and functional data structures.
* Reworked existing data structures for storing directly in stable memory.
* Simplified and included missing type conversions.
* Removed hash-based data structures and collision-prone hash functions.
* `range()` functions for each numeric type with exclusive upper bounds.
* `Random` module with a simpler API and optional pseudo-random number generation.
* `VarArray` module for more conveniently working with mutable arrays.
* Consistent naming, parameter order, and usage examples across all modules.

## Add `core` to a Motoko project

Include the following in your [`mops.toml`](https://docs.mops.one/mops.toml) config file:

```toml
[dependencies]
core = "1.0.0" # Check https://mops.one/core for the latest version
```

## New data structures

The base library now includes both imperative (mutable) and purely functional (immutable) data structures which can all be used in stable memory. Because Motoko is a multi-paradigm language, we wanted to reflect this in the base library by providing data structures similar to those in imperative languages (JS, Java, C#, C++) and functional languages (Haskell, Elixir, OCaml, F#).

Check out [this article](https://learn.microsoft.com/en-us/dotnet/standard/linq/functional-vs-imperative-programming) for a refresher on the differences between imperative vs. functional programming, both of which are supported in Motoko.

| Data Structure         | Description                                                                                                                                                 |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **List**               | Mutable list (originally [`mo:vector`](https://mops.one/vector))                                                                                            |
| **Map**                | Mutable map (originally [`mo:stableheapbtreemap`](https://mops.one/stableheapbtreemap))                                                                     |
| **Queue**              | Mutable queue
| **Set**                | Mutable set                                                                                                                                                 |
| **Array**              | Immutable array                                                                                                                                             |
| **VarArray**           | Mutable array                                                                                                                                               |
| **pure/List**          | Immutable list (originally `mo:base/List`)                                                                                                                  |
| **pure/Map**           | Immutable map (originally `mo:base/OrderedMap`)                                                                                                             |
| **pure/Set**           | Immutable set (originally `mo:base/OrderedSet`)                                                                                                             |
| **pure/Queue**         | Immutable queue  (orginally `mo:base/Deque`)                                                                                                                                              |
| **pure/RealTimeQueue** | Immutable queue with [constant-time operations](https://drops.dagstuhl.de/storage/00lipics/lipics-vol268-itp2023/LIPIcs.ITP.2023.29/LIPIcs.ITP.2023.29.pdf) |

We chose implementations with good all-round performance, deferring specialized implementations to the [Mops](https://mops.one/) package ecosystem. We also updated function names for consistency and familiarity from other languages such as JS, Python, Java, and Rust.

Below is an example of using the new imperative `List` module, derived from the [`vector`](https://mops.one/vector) Mops package (big thanks to [Andrii Stepanov and Timo Hanke](https://github.com/research-ag)):

```motoko
import List "mo:core/List";
import Nat "mo:core/Nat";

persistent actor {
  let list = List.empty<Nat>(); // Persistent data structure
  List.add(list, 5);
  assert List.toText(list, Nat.toText) == "List[5]";
}
``` 

You can also use the original (purely functional) `List` module:

```motoko
import PureList "mo:core/pure/List";

persistent actor {
  var list = PureList.empty<Text>(); // Persistent data structure
  list := PureList.pushFront(list, "Hi");
  assert PureList.size(list) == 1;
  assert PureList.all<Text>(list, func(n) { n == "Hi" });
}
```

> Note: `pure/List` is a singly [linked list](https://en.wikipedia.org/wiki/Linked_list) that pushes elements to the front via `pushFront()`, while the imperative `List` is a [dynamic array](https://en.wikipedia.org/wiki/Dynamic_array) that pushes to the back via `add()`.

We also included an efficient [heap-based BTree map implementation](https://github.com/canscale/StableHeapBTreeMap) (big thanks to [Byron Becker](https://github.com/ByronBecker)):

```motoko no-repl
import Map "mo:core/Map";
import Text "mo:core/Text";
import Array "mo:core/Array";

persistent actor {
  let map = Map.empty<Text, Nat>();
  Map.add(map, Text.compare, "key", 123);
  assert Map.size(map) == 1;
  Array.fromIter(Map.entries(map)) == [("key", 123)];
}
```

## Module changes

Refer to the [migration guide](https://internetcomputer.org/docs/motoko/base-core-migration) for a comprehensive list of changes from `base` to `core`.

### New modules

- `List` - Mutable list
- `Map` - Mutable map
- `Queue` - Mutable double-ended queue
- `Set` - Mutable set
- `Runtime` - Runtime utilities and assertions
- `Tuples` - Tuple utilities
- `Types` - Common type definitions
- `VarArray` - Mutable array operations
- `pure/List` - Immutable list (originally `mo:base/List`)
- `pure/Map` - Immutable map (originally `mo:base/OrderedMap`)
- `pure/RealTimeQueue` - Queue implementation with performance tradeoffs
- `pure/Set` - Immutable set (originally `mo:base/OrderedSet`)

### Renamed modules

| Base package                   | Core package       | Notes                                               |
| ------------------------------ | ------------------ | --------------------------------------------------- |
| `ExperimentalCycles`           | `Cycles`           | Stabilized module for cycle management              |
| `ExperimentalInternetComputer` | `InternetComputer` | Stabilized low-level ICP interface                  |
| `Deque`                        | `pure/Queue`       | Enhanced double-ended queue becomes immutable queue |
| `List`                         | `pure/List`        | Original immutable list moved to `pure/` namespace  |
| `OrderedMap`                   | `pure/Map`         | Ordered map moved to `pure/` namespace              |
| `OrderedSet`                   | `pure/Set`         | Ordered set moved to `pure/` namespace              |

> The `pure/` namespace contains immutable (purely functional) data structures where operations return new values rather than modifying in place. The namespace makes it clear which data structures are mutable and which are immutable.

### Removed modules

- `AssocList` - Use `Map` or `pure/Map` instead
- `Buffer` - Use `List` or `VarArray` instead
- `ExperimentalStableMemory` - Deprecated
- `Hash` - Vulnerable to hash collision attacks
- `HashMap` - Use `Map` or `pure/Map`
- `Heap`
- `IterType` - Merged into `Types` module
- `None`
- `Prelude` - Merged into `Debug` and `Runtime`
- `RBTree`
- `Trie`
- `TrieMap` - Use `Map` or `pure/Map` instead
- `TrieSet` - Use `Set` or `pure/Set` instead

> Modules like `Random`, `Region`, `Time`, `Timer`, and `Stack` still exist in core but with modified APIs.

## Contributions and feedback

Big thanks to the following community contributors:

* [MR Research AG (A. Stepanov, T. Hanke)](https://github.com/research-ag): [`vector`](https://github.com/research-ag/vector), [`prng`](https://github.com/research-ag/prng)
* [Byron Becker](https://github.com/ByronBecker): [`StableHeapBTreeMap`](https://github.com/canscale/StableHeapBTreeMap)
* [Zen Voich](https://github.com/ZenVoich): [`test`](https://github.com/ZenVoich/test)

PRs are welcome! Please check out the [contributor guidelines](https://github.com/dfinity/motoko-core/blob/main/.github/CONTRIBUTING.md) for more information.

Interface design and code style guidelines for the repository can be found [here](https://github.com/dfinity/motoko-core/blob/main/Styleguide.md).

If you encounter a bug, please let us know by opening a [GitHub issue](https://github.com/dfinity/motoko-core/issues).

We look forward to hearing your thoughts! As always, your feedback is welcome and valuable as the `core` package continues to evolve over time.

Cheers!

~ Ryan
