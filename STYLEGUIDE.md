# Core library style guide

## Source code

Unless otherwise mentioned, this repository should follow the official [Motoko code style guidelines](https://internetcomputer.org/docs/motoko/main/reference/style).

## Documentation code examples

* When relevant, examples should use the `assert` keyword without outer parentheses:

```motoko
assert Nat.toInt(1234) == +1234;
```

* Data structure modules (`Array`, `List`, `Map`, `Queue`, etc.) should use a `persistent actor` wrapper with transient keywords as needed:

```motoko
import Map "mo:core/Map";

persistent actor {
  let iter = Iter.fromArray([(0, "Zero"), (1, "One"), (2, "Two")]);
  let map = Map.fromIter<Nat, Text>(iter, Nat.compare);
}
```

* Other modules (`Bool`, `Int`, `Time`, etc.) should use either a minimal top-level code snippet (omitting the import) or a full actor example:

```motoko
assert Principal.fromText("2vxsx-fae") == Principal.anonymous();
```

...or...

```motoko
import IC "mo:core/InternetComputer";
import Principal "mo:core/Principal";

persistent actor {
  type OutputType = { decimals : Nat32 };

  public func example() : async ?OutputType {
    let ledger = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai")
    let method = "decimals";
    let input = ();
    let rawReply = await IC.call(ledger, method, to_candid (input));
    let output : ?OutputType = from_candid (rawReply);
    assert output == ?{ decimals = 8 };
    output
  }
}
```

* For minimal code snippets with imports from other modules, include a space after the import. For a code example in the `Text`` module:

```motoko
import Char "mo:core/Char";

assert Text.compareWith("abc", "ABC", Char.compare) == #greater
```
