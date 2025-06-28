/// A mutable list data structure with efficient random access and dynamic resizing.
/// Provides O(1) access time and O(sqrt(n)) memory overhead.
/// Can be declared `stable` for orthogonal persistence.
///
/// This implementation is adapted with permission from the `vector` Mops package created by Research AG.
///
/// Copyright: 2023 MR Research AG
/// Main author: Andrii Stepanov (AStepanov25)
/// Contributors: Timo Hanke (timohanke), Andy Gura (andygura), react0r-com
///
/// ```motoko name=import
/// import List "mo:core/List";
/// ```

import PureList "pure/List";
import Prim "mo:⛔";
import Result "Result";
import Nat32 "Nat32";
import Array "Array";
import Iter "Iter";
import Nat "Nat";
import Order "Order";
import Option "Option";
import VarArray "VarArray";
import Types "Types";
import Runtime "Runtime";

module {
  /// `List<T>` provides a mutable list of elements of type `T`.
  /// Based on the paper "Resizable Arrays in Optimal Time and Space" by Brodnik, Carlsson, Demaine, Munro and Sedgewick (1999).
  /// Since this is internally a two-dimensional array the access times for put and get operations
  /// will naturally be 2x slower than Buffer and Array. However, Array is not resizable and Buffer
  /// has `O(size)` memory waste.
  ///
  /// The maximum number of elements in a `List` is 2^32.
  public type List<T> = Types.List<T>;

  let INTERNAL_ERROR = "List: internal error";

  /// Creates a new empty List for elements of type T.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>(); // Creates a new List
  /// ```
  public func empty<T>() : List<T> = {
    var blocks = [var [var]];
    var blockIndex = 1;
    var elementIndex = 0
  };

  /// Returns a new list with capacity and size 1, containing `element`.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.singleton<Nat>(1);
  /// assert List.toText<Nat>(list, Nat.toText) == "List[1]";
  /// ```
  ///
  /// Runtime: `O(1)`
  ///
  /// Space: `O(1)`
  public func singleton<T>(element : T) : List<T> = {
    var blockIndex = 2;
    var blocks = [var [var], [var ?element]];
    var elementIndex = 0
  };

  private func repeatInternal<T>(initValue : ?T, size : Nat) : List<T> {
    let (blockIndex, elementIndex) = locate(size);

    let blocks = newIndexBlockLength(Nat32.fromNat(if (elementIndex == 0) { blockIndex - 1 } else blockIndex));
    let dataBlocks = VarArray.repeat<[var ?T]>([var], blocks);
    var i = 1;
    while (i < blockIndex) {
      dataBlocks[i] := VarArray.repeat<?T>(initValue, dataBlockSize(i));
      i += 1
    };
    if (elementIndex != 0 and blockIndex < blocks) {
      let block = VarArray.repeat<?T>(null, dataBlockSize(i));
      if (not Option.isNull(initValue)) {
        var j = 0;
        while (j < elementIndex) {
          block[j] := initValue;
          j += 1
        }
      };
      dataBlocks[i] := block
    };

    {
      var blocks = dataBlocks;
      var blockIndex = blockIndex;
      var elementIndex = elementIndex
    }
  };

  /// Creates a new List with `size` copies of the initial value.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.repeat<Nat>(2, 4);
  /// assert List.toArray(list) == [2, 2, 2, 2];
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  public func repeat<T>(initValue : T, size : Nat) : List<T> = repeatInternal<T>(?initValue, size);

  /// Converts a mutable `List` to a purely functional `PureList`.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.fromArray<Nat>([1, 2, 3]);
  /// let pureList = List.toPure<Nat>(list); // converts to immutable PureList
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  public func toPure<T>(list : List<T>) : PureList.List<T> {
    var result : PureList.List<T> = null;

    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;
    var db : [var ?T] = if (blockIndex < list.blocks.size()) {
      list.blocks[blockIndex]
    } else { [var] };

    loop {
      if (elementIndex != 0) {
        elementIndex -= 1
      } else {
        blockIndex -= 1;
        if (blockIndex == 0) return result;
        db := list.blocks[blockIndex];
        elementIndex := db.size() - 1
      };
      switch (db[elementIndex]) {
        case (?x) result := ?(x, result);
        case (_) Prim.trap(INTERNAL_ERROR)
      }
    }
  };

  /// Converts a purely functional `List` to a mutable `List`.
  ///
  /// Example:
  /// ```motoko include=import
  /// import PureList "mo:core/pure/List";
  ///
  /// let pureList = PureList.fromArray<Nat>([1, 2, 3]);
  /// let list = List.fromPure<Nat>(pureList); // converts to mutable List
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  public func fromPure<T>(p : PureList.List<T>) : List<T> {
    var pure = p;
    var list = empty<T>();
    loop {
      switch (pure) {
        case (?(x, xs)) {
          add(list, x);
          pure := xs
        };
        case null return list
      }
    }
  };

  private func addRepeatInternal<T>(list : List<T>, initValue : ?T, count : Nat) {
    let (blockIndex, elementIndex) = locate(size(list) + count);
    let blocks = newIndexBlockLength(Nat32.fromNat(if (elementIndex == 0) { blockIndex - 1 } else blockIndex));

    let oldBlocks = list.blocks.size();
    if (oldBlocks < blocks) {
      let oldDataBlocks = list.blocks;
      list.blocks := VarArray.repeat<[var ?T]>([var], blocks);
      var i = 0;
      while (i < oldBlocks) {
        list.blocks[i] := oldDataBlocks[i];
        i += 1
      }
    };

    var cnt = count;
    while (cnt > 0) {
      let dbSize = dataBlockSize(list.blockIndex);
      if (list.elementIndex == 0 and dbSize <= cnt) {
        list.blocks[list.blockIndex] := VarArray.repeat<?T>(initValue, dbSize);
        cnt -= dbSize;
        list.blockIndex += 1
      } else {
        if (list.blocks[list.blockIndex].size() == 0) {
          list.blocks[list.blockIndex] := VarArray.repeat<?T>(null, dbSize)
        };
        let from = list.elementIndex;
        let to = Nat.min(list.elementIndex + cnt, dbSize);

        let block = list.blocks[list.blockIndex];
        if (not Option.isNull(initValue)) {
          var i = from;
          while (i < to) {
            block[i] := initValue;
            i += 1
          }
        };

        list.elementIndex := to;
        if (list.elementIndex == dbSize) {
          list.elementIndex := 0;
          list.blockIndex += 1
        };
        cnt -= to - from
      }
    }
  };

  /// Add to list `count` copies of the initial value.
  ///
  /// ```motoko include=import
  /// let list = List.repeat<Nat>(2, 4); // [2, 2, 2, 2]
  /// List.addRepeat(list, 2, 1); // [2, 2, 2, 2, 1, 1]
  /// ```
  ///
  /// The maximum number of elements in a `List` is 2^32.
  ///
  /// Runtime: `O(count)`
  public func addRepeat<T>(list : List<T>, initValue : T, count : Nat) = addRepeatInternal<T>(list, ?initValue, count);

  /// Resets the list to size 0, de-referencing all elements.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.add(list, 11);
  /// List.add(list, 12);
  /// List.clear(list); // list is now empty
  /// assert List.toArray(list) == [];
  /// ```
  ///
  /// Runtime: `O(1)`
  public func clear<T>(list : List<T>) {
    list.blocks := [var [var]];
    list.blockIndex := 1;
    list.elementIndex := 0
  };

  /// Creates a list of size `size`. Each element at index i
  /// is created by applying `generator` to i.
  ///
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.tabulate<Nat>(4, func i = i * 2);
  /// assert List.toArray(list) == [0, 2, 4, 6];
  /// ```
  ///
  /// Runtime: O(size)
  ///
  /// Space: O(size)
  ///
  /// *Runtime and space assumes that `generator` runs in O(1) time and space.
  public func tabulate<T>(size : Nat, generator : Nat -> T) : List<T> {
    let (blockIndex, elementIndex) = locate(size);

    let blocks = newIndexBlockLength(Nat32.fromNat(if (elementIndex == 0) { blockIndex - 1 } else blockIndex));
    let dataBlocks = VarArray.repeat<[var ?T]>([var], blocks);

    func makeBlock(generator : Nat -> T, p : Nat, len : Nat, fill : Nat) : [var ?T] {
      let block = VarArray.repeat<?T>(null, len);
      var j = 0;
      var pos = p;
      while (j < fill) {
        block[j] := ?generator(pos);
        j += 1;
        pos += 1
      };
      block
    };

    var i = 1;
    var pos = 0;

    while (i < blockIndex) {
      let len = dataBlockSize(i);
      dataBlocks[i] := makeBlock(generator, pos, len, len);
      pos += len;
      i += 1
    };
    if (elementIndex != 0 and blockIndex < blocks) {
      dataBlocks[i] := makeBlock(generator, pos, dataBlockSize(i), elementIndex)
    };

    {
      var blocks = dataBlocks;
      var blockIndex = blockIndex;
      var elementIndex = elementIndex
    }
  };

  /// Combines a list of lists into a single list. Retains the original
  /// ordering of the elements.
  ///
  /// This has better performance compared to `List.join()`.
  ///
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let lists = List.fromArray([
  ///   List.fromArray([0, 1, 2]), List.fromArray([2, 3]), List.fromArray([]), List.fromArray([4])
  /// ]);
  /// let flatList = List.flatten<Nat>(lists);
  /// assert List.equal(flatList, List.fromArray([0, 1, 2, 2, 3, 4]), Nat.equal);
  /// ```
  ///
  /// Runtime: O(number of elements in list)
  ///
  /// Space: O(number of elements in list)
  public func flatten<T>(lists : List<List<T>>) : List<T> {
    var sz = 0;
    forEach<List<T>>(lists, func(sublist) = sz += size(sublist));

    let result = repeatInternal<T>(null, sz);
    result.blockIndex := 1;
    result.elementIndex := 0;

    forEach<List<T>>(
      lists,
      func(sublist) {
        forEach<T>(
          sublist,
          func(item) {
            add(result, item)
          }
        )
      }
    );
    result
  };

  /// Combines an iterator of lists into a single list.
  /// Retains the original ordering of the elements.
  ///
  /// Consider using `List.flatten()` for better performance.
  ///
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let lists = [List.fromArray([0, 1, 2]), List.fromArray([2, 3]), List.fromArray([]), List.fromArray([4])];
  /// let joinedList = List.join<Nat>(lists.vals());
  /// assert List.equal(joinedList, List.fromArray([0, 1, 2, 2, 3, 4]), Nat.equal);
  /// ```
  ///
  /// Runtime: O(number of elements in list)
  ///
  /// Space: O(number of elements in list)
  public func join<T>(lists : Iter.Iter<List<T>>) : List<T> {
    var result = empty<T>();
    for (list in lists) {
      let oldBlockIndex = result.blockIndex;
      let oldElementIndex = result.elementIndex;

      addRepeatInternal<T>(result, null, size(list));
      
      result.blockIndex := oldBlockIndex;
      result.elementIndex := oldElementIndex;

      forEach<T>(list, func item = add(result, item));
    };
    result
  };

  /// Returns a copy of a List, with the same size.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 1);
  ///
  /// let clone = List.clone(list);
  /// assert List.toArray(clone) == [1];
  /// ```
  ///
  /// Runtime: `O(size)`
  public func clone<T>(list : List<T>) : List<T> = {
    var blocks = VarArray.tabulate<[var ?T]>(
      list.blocks.size(),
      func(i) = VarArray.clone<?T>(list.blocks[i])
    );
    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex
  };

  /// Creates a new list by applying the provided function to each element in the input list.
  /// The resulting list has the same size as the input list.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.singleton<Nat>(123);
  /// let textList = List.map<Nat, Text>(list, Nat.toText);
  /// assert List.toArray(textList) == ["123"];
  /// ```
  ///
  /// Runtime: `O(size)`
  public func map<T, R>(list : List<T>, f : T -> R) : List<R> {
    let blocks = VarArray.repeat<[var ?R]>([var], list.blocks.size());
    let blocksCount = list.blocks.size();

    var i = 1;
    while (i < blocksCount) {
      let oldBlock = list.blocks[i];
      let blockSize = oldBlock.size();
      let newBlock = VarArray.repeat<?R>(null, blockSize);
      blocks[i] := newBlock;
      var j = 0;

      while (j < blockSize) {
        switch (oldBlock[j]) {
          case (?item) newBlock[j] := ?f(item);
          case null return {
            var blocks = blocks;
            var blockIndex = list.blockIndex;
            var elementIndex = list.elementIndex
          }
        };
        j += 1
      };
      i += 1
    };

    {
      var blocks = blocks;
      var blockIndex = list.blockIndex;
      var elementIndex = list.elementIndex
    }
  };

  /// Applies `f` to each element of `list` in place,
  /// retaining the original ordering of elements.
  /// This modifies the original list.
  ///
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.fromArray<Nat>([0, 1, 2, 3]);
  /// List.mapInPlace<Nat>(list, func x = x * 3);
  /// assert List.equal(list, List.fromArray<Nat>([0, 3, 6, 9]), Nat.equal);
  /// ```
  ///
  /// Runtime: O(size)
  ///
  /// Space: O(size)
  ///
  /// *Runtime and space assumes that `f` runs in O(1) time and space.
  public func mapInPlace<T>(list : List<T>, f : T -> T) {
    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) db[j] := ?f(x);
          case null return
        };
        j += 1
      };
      i += 1
    }
  };

  /// Creates a new list by applying `f` to each element in `list` and its index.
  /// Retains original ordering of elements.
  ///
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.fromArray<Nat>([10, 10, 10, 10]);
  /// let newList = List.mapEntries<Nat, Nat>(list, func (x, i) = i * x);
  /// assert List.equal(newList, List.fromArray<Nat>([0, 10, 20, 30]), Nat.equal);
  /// ```
  ///
  /// Runtime: O(size)
  ///
  /// Space: O(size)
  ///
  /// *Runtime and space assumes that `f` runs in O(1) time and space.
  public func mapEntries<T, R>(list : List<T>, f : (T, Nat) -> R) : List<R> {
    let blocks = VarArray.repeat<[var ?R]>([var], list.blocks.size());
    let blocksCount = list.blocks.size();

    var index = 0;

    var i = 1;
    while (i < blocksCount) {
      let oldBlock = list.blocks[i];
      let blockSize = oldBlock.size();
      let newBlock = VarArray.repeat<?R>(null, blockSize);
      blocks[i] := newBlock;
      var j = 0;

      while (j < blockSize) {
        switch (oldBlock[j]) {
          case (?item) newBlock[j] := ?f(item, index);
          case null return {
            var blocks = blocks;
            var blockIndex = list.blockIndex;
            var elementIndex = list.elementIndex
          }
        };
        j += 1;
        index += 1
      };
      i += 1
    };

    {
      var blocks = blocks;
      var blockIndex = list.blockIndex;
      var elementIndex = list.elementIndex
    }
  };

  /// Creates a new list by applying `f` to each element in `list`.
  /// If any invocation of `f` produces an `#err`, returns an `#err`. Otherwise
  /// returns an `#ok` containing the new list.
  ///
  /// ```motoko include=import
  /// import Result "mo:core/Result";
  ///
  /// let list = List.fromArray([4, 3, 2, 1, 0]);
  /// // divide 100 by every element in the list
  /// let result = List.mapResult<Nat, Nat, Text>(list, func x {
  ///   if (x > 0) {
  ///     #ok(100 / x)
  ///   } else {
  ///     #err "Cannot divide by zero"
  ///   }
  /// });
  /// assert Result.isErr(result);
  /// ```
  ///
  /// Runtime: O(size)
  ///
  /// Space: O(size)
  ///
  /// *Runtime and space assumes that `f` runs in O(1) time and space.
  public func mapResult<T, R, E>(list : List<T>, f : T -> Result.Result<R, E>) : Result.Result<List<R>, E> {
    var error : ?E = null;

    let blocks = VarArray.repeat<[var ?R]>([var], list.blocks.size());
    let blocksCount = list.blocks.size();

    var i = 1;
    while (i < blocksCount) {
      let oldBlock = list.blocks[i];
      let blockSize = oldBlock.size();
      let newBlock = VarArray.repeat<?R>(null, blockSize);
      blocks[i] := newBlock;
      var j = 0;

      while (j < blockSize) {
        switch (oldBlock[j]) {
          case (?item) newBlock[j] := switch (f(item)) {
            case (#ok x) ?x;
            case (#err e) switch (error) {
              case (null) {
                error := ?e;
                null
              };
              case (?_) null
            }
          };
          case null return switch (error) {
            case (null) return #ok {
              var blocks = blocks;
              var blockIndex = list.blockIndex;
              var elementIndex = list.elementIndex
            };
            case (?e) return #err e
          }
        };
        j += 1
      };
      i += 1
    };

    switch (error) {
      case (null) return #ok {
        var blocks = blocks;
        var blockIndex = list.blockIndex;
        var elementIndex = list.elementIndex
      };
      case (?e) return #err e
    }
  };

  /// Returns a new list containing only the elements from `list` for which the predicate returns true.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.fromArray<Nat>([1, 2, 3, 4]);
  /// let evenNumbers = List.filter<Nat>(list, func x = x % 2 == 0);
  /// assert List.toArray(evenNumbers) == [2, 4];
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  ///
  /// *Runtime and space assumes that `predicate` runs in `O(1)` time and space.
  public func filter<T>(list : List<T>, predicate : T -> Bool) : List<T> {
    let filtered = empty<T>();

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return filtered;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) if (predicate(x)) add(filtered, x);
          case null return filtered
        };
        j += 1
      };
      i += 1
    };

    filtered
  };

  /// Returns a new list containing all elements from `list` for which the function returns ?element.
  /// Discards all elements for which the function returns null.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.fromArray<Nat>([1, 2, 3, 4]);
  /// let doubled = List.filterMap<Nat, Nat>(list, func x = if (x % 2 == 0) ?(x * 2) else null);
  /// assert List.toArray(doubled) == [4, 8];
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  ///
  /// *Runtime and space assumes that `f` runs in `O(1)` time and space.
  public func filterMap<T, R>(list : List<T>, f : T -> ?R) : List<R> {
    let filtered = empty<R>();

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return filtered;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) switch (f(x)) {
            case (?y) add(filtered, y);
            case null {}
          };
          case null return filtered
        };
        j += 1
      };
      i += 1
    };

    filtered
  };

  /// Creates a new list by applying `k` to each element in `list`,
  /// and concatenating the resulting iterators in order.
  ///
  /// ```motoko include=import
  /// import Int "mo:core/Int"
  ///
  /// let list = List.fromArray([1, 2, 3, 4]);
  /// let newList = List.flatMap<Nat, Int>(list, func x = [x, -x].vals());
  /// assert List.equal(newList, List.fromArray([1, -1, 2, -2, 3, -3, 4, -4]), Int.equal);
  /// ```
  /// Runtime: O(size)
  ///
  /// Space: O(size)
  /// *Runtime and space assumes that `k` runs in O(1) time and space.
  public func flatMap<T, R>(list : List<T>, k : T -> Iter.Iter<R>) : List<R> {
    let result = empty<R>();

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return result;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) for (y in k(x)) add(result, y);
          case _ return result
        };
        j += 1
      };
      i += 1
    };

    result
  };

  /// Returns the current number of elements in the list.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// assert List.size(list) == 0
  /// ```
  ///
  /// Runtime: `O(1)` (with some internal calculations)
  public func size<T>(list : List<T>) : Nat {
    let d = Nat32.fromNat(list.blockIndex);
    let i = Nat32.fromNat(list.elementIndex);

    // We call all data blocks of the same capacity an "epoch". We number the epochs 0,1,2,...
    // A data block is in epoch e iff the data block has capacity 2 ** e.
    // Each epoch starting with epoch 1 spans exactly two super blocks.
    // Super block s falls in epoch ceil(s/2).

    // epoch of last data block
    // e = 32 - lz
    let lz = Nat32.bitcountLeadingZero(d / 3);

    // capacity of all prior epochs combined
    // capacity_before_e = 2 * 4 ** (e - 1) - 1

    // data blocks in all prior epochs combined
    // blocks_before_e = 3 * 2 ** (e - 1) - 2

    // then size = d * 2 ** e + i - c
    // where c = blocks_before_e * 2 ** e - capacity_before_e

    // there can be overflows, but the result is without overflows, so use addWrap and subWrap
    // we don't erase bits by >>, so to use <>> is ok
    Nat32.toNat((d -% (1 <>> lz)) <>> lz +% i)
  };

  func dataBlockSize(blockIndex : Nat) : Nat {
    // formula for the size of given blockIndex
    // don't call it for blockIndex == 0
    Nat32.toNat(1 <>> Nat32.bitcountLeadingZero(Nat32.fromNat(blockIndex) / 3))
  };

  func newIndexBlockLength(blockIndex : Nat32) : Nat {
    if (blockIndex <= 1) 2 else {
      let s = 30 - Nat32.bitcountLeadingZero(blockIndex);
      Nat32.toNat(((blockIndex >> s) +% 1) << s)
    }
  };

  func growIndexBlockIfNeeded<T>(list : List<T>) {
    if (list.blocks.size() == list.blockIndex) {
      let newBlocks = VarArray.repeat<[var ?T]>([var], newIndexBlockLength(Nat32.fromNat(list.blockIndex)));
      var i = 0;
      while (i < list.blockIndex) {
        newBlocks[i] := list.blocks[i];
        i += 1
      };
      list.blocks := newBlocks
    }
  };

  func shrinkIndexBlockIfNeeded<T>(list : List<T>) {
    let blockIndex = Nat32.fromNat(list.blockIndex);
    // kind of index of the first block in the super block
    if ((blockIndex << Nat32.bitcountLeadingZero(blockIndex)) << 2 == 0) {
      let newLength = newIndexBlockLength(blockIndex);
      if (newLength < list.blocks.size()) {
        let newBlocks = VarArray.repeat<[var ?T]>([var], newLength);
        var i = 0;
        while (i < newLength) {
          newBlocks[i] := list.blocks[i];
          i += 1
        };
        list.blocks := newBlocks
      }
    }
  };

  /// Adds a single element to the end of a List,
  /// allocating a new internal data block if needed,
  /// and resizing the internal index block if needed.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 0); // add 0 to list
  /// List.add(list, 1);
  /// List.add(list, 2);
  /// List.add(list, 3);
  /// assert List.toArray(list) == [0, 1, 2, 3];
  /// ```
  ///
  /// The maximum number of elements in a `List` is 2^32.
  ///
  /// Amortized Runtime: `O(1)`, Worst Case Runtime: `O(sqrt(n))`
  public func add<T>(list : List<T>, element : T) {
    var elementIndex = list.elementIndex;
    if (elementIndex == 0) {
      growIndexBlockIfNeeded(list);
      let blockIndex = list.blockIndex;

      // When removing last we keep one more data block, so can be not empty
      if (list.blocks[blockIndex].size() == 0) {
        list.blocks[blockIndex] := VarArray.repeat<?T>(
          null,
          dataBlockSize(blockIndex)
        )
      }
    };

    let lastDataBlock = list.blocks[list.blockIndex];

    lastDataBlock[elementIndex] := ?element;

    elementIndex += 1;
    if (elementIndex == lastDataBlock.size()) {
      elementIndex := 0;
      list.blockIndex += 1
    };
    list.elementIndex := elementIndex
  };

  /// Removes and returns the last item in the list or `null` if
  /// the list is empty.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.add(list, 11);
  /// assert List.removeLast(list) == ?11;
  /// assert List.removeLast(list) == ?10;
  /// assert List.removeLast(list) == null;
  /// ```
  ///
  /// Amortized Runtime: `O(1)`, Worst Case Runtime: `O(sqrt(n))`
  ///
  /// Amortized Space: `O(1)`, Worst Case Space: `O(sqrt(n))`
  public func removeLast<T>(list : List<T>) : ?T {
    var elementIndex = list.elementIndex;
    if (elementIndex == 0) {
      shrinkIndexBlockIfNeeded(list);

      var blockIndex = list.blockIndex;
      if (blockIndex == 1) {
        return null
      };
      blockIndex -= 1;
      elementIndex := list.blocks[blockIndex].size();

      // Keep one totally empty block when removing
      if (blockIndex + 2 < list.blocks.size()) {
        if (list.blocks[blockIndex + 2].size() == 0) {
          list.blocks[blockIndex + 2] := [var]
        }
      };
      list.blockIndex := blockIndex
    };
    elementIndex -= 1;

    var lastDataBlock = list.blocks[list.blockIndex];

    let element = lastDataBlock[elementIndex];
    lastDataBlock[elementIndex] := null;

    list.elementIndex := elementIndex;
    return element
  };

  func locate(index : Nat) : (Nat, Nat) {
    // see comments in tests
    let i = Nat32.fromNat(index);
    let lz = Nat32.bitcountLeadingZero(i);
    let lz2 = lz >> 1;
    if (lz & 1 == 0) {
      (Nat32.toNat(((i << lz2) >> 16) ^ (0x10000 >> lz2)), Nat32.toNat(i & (0xFFFF >> lz2)))
    } else {
      (Nat32.toNat(((i << lz2) >> 15) ^ (0x18000 >> lz2)), Nat32.toNat(i & (0x7FFF >> lz2)))
    }
  };

  /// Returns the element at index `index`. Indexing is zero-based.
  /// Traps if `index >= size`, error message may not be descriptive.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.add(list, 11);
  /// assert List.get(list, 0) == 10;
  /// ```
  ///
  /// Runtime: `O(1)`
  public func get<T>(list : List<T>, index : Nat) : T {
    // inlined version of:
    //   let (a,b) = locate(index);
    //   switch(list.blocks[a][b]) {
    //     case (?element) element;
    //     case (null) Prim.trap "";
    //   };
    let i = Nat32.fromNat(index);
    let lz = Nat32.bitcountLeadingZero(i);
    let lz2 = lz >> 1;
    switch (
      if (lz & 1 == 0) {
        list.blocks[Nat32.toNat(((i << lz2) >> 16) ^ (0x10000 >> lz2))][Nat32.toNat(i & (0xFFFF >> lz2))]
      } else {
        list.blocks[Nat32.toNat(((i << lz2) >> 15) ^ (0x18000 >> lz2))][Nat32.toNat(i & (0x7FFF >> lz2))]
      }
    ) {
      case (?result) return result;
      case (_) Prim.trap "List index out of bounds in get"
    }
  };

  /// Returns the element at index `index` as an option.
  /// Returns `null` when `index >= size`. Indexing is zero-based.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.add(list, 11);
  /// assert List.getOpt(list, 0) == ?10;
  /// assert List.getOpt(list, 2) == null;
  /// ```
  ///
  /// Runtime: `O(1)`
  ///
  /// Space: `O(1)`
  public func getOpt<T>(list : List<T>, index : Nat) : ?T {
    let (a, b) = do {
      let i = Nat32.fromNat(index);
      let lz = Nat32.bitcountLeadingZero(i);
      let lz2 = lz >> 1;
      if (lz & 1 == 0) {
        (Nat32.toNat(((i << lz2) >> 16) ^ (0x10000 >> lz2)), Nat32.toNat(i & (0xFFFF >> lz2)))
      } else {
        (Nat32.toNat(((i << lz2) >> 15) ^ (0x18000 >> lz2)), Nat32.toNat(i & (0x7FFF >> lz2)))
      }
    };
    if (a < list.blockIndex or list.elementIndex != 0 and a == list.blockIndex) {
      list.blocks[a][b]
    } else null
  };

  /// Overwrites the current element at `index` with `element`.
  /// Traps if `index` >= size. Indexing is zero-based.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.put(list, 0, 20); // overwrites 10 at index 0 with 20
  /// assert List.toArray(list) == [20];
  /// ```
  ///
  /// Runtime: `O(1)`
  public func put<T>(list : List<T>, index : Nat, value : T) {
    let (a, b) = do {
      let i = Nat32.fromNat(index);
      let lz = Nat32.bitcountLeadingZero(i);
      let lz2 = lz >> 1;
      if (lz & 1 == 0) {
        (Nat32.toNat(((i << lz2) >> 16) ^ (0x10000 >> lz2)), Nat32.toNat(i & (0xFFFF >> lz2)))
      } else {
        (Nat32.toNat(((i << lz2) >> 15) ^ (0x18000 >> lz2)), Nat32.toNat(i & (0x7FFF >> lz2)))
      }
    };
    if (a < list.blockIndex or a == list.blockIndex and b < list.elementIndex) {
      list.blocks[a][b] := ?value
    } else Prim.trap "List index out of bounds in put"
  };

  /// Sorts the elements in the list according to `compare`.
  /// Sort is deterministic, stable, and in-place.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.empty<Nat>();
  /// List.add(list, 3);
  /// List.add(list, 1);
  /// List.add(list, 2);
  /// List.sort(list, Nat.compare);
  /// assert List.toArray(list) == [1, 2, 3];
  /// ```
  ///
  /// Runtime: O(size * log(size))
  ///
  /// Space: O(size)
  /// *Runtime and space assumes that `compare` runs in O(1) time and space.
  public func sort<T>(list : List<T>, compare : (T, T) -> Order.Order) {
    if (size(list) < 2) return;
    let arr = toVarArray(list);
    VarArray.sortInPlace(arr, compare);
    forEachEntryChange<T>(list, func(i, _) = arr[i])
  };

  /// Finds the first index of `element` in `list` using equality of elements defined
  /// by `equal`. Returns `null` if `element` is not found.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.empty<Nat>();
  /// List.add(list, 1);
  /// List.add(list, 2);
  /// List.add(list, 3);
  /// List.add(list, 4);
  ///
  /// assert List.indexOf<Nat>(list, Nat.equal, 3) == ?2;
  /// assert List.indexOf<Nat>(list, Nat.equal, 5) == null;
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// *Runtime and space assumes that `equal` runs in `O(1)` time and space.
  public func indexOf<T>(list : List<T>, equal : (T, T) -> Bool, element : T) : ?Nat {
    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return null;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) if (equal(x, element)) return ?size<T>({
            var blocks = [var];
            var blockIndex = i;
            var elementIndex = j
          });
          case null return null
        };
        j += 1
      };
      i += 1
    };
    null
  };

  /// Finds the last index of `element` in `list` using equality of elements defined
  /// by `equal`. Returns `null` if `element` is not found.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.fromArray<Nat>([1, 2, 3, 4, 2, 2]);
  ///
  /// assert List.lastIndexOf<Nat>(list, Nat.equal, 2) == ?5;
  /// assert List.lastIndexOf<Nat>(list, Nat.equal, 5) == null;
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// *Runtime and space assumes that `equal` runs in `O(1)` time and space.
  public func lastIndexOf<T>(list : List<T>, equal : (T, T) -> Bool, element : T) : ?Nat {
    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;
    var db : [var ?T] = if (blockIndex < list.blocks.size()) {
      list.blocks[blockIndex]
    } else { [var] };

    loop {
      if (elementIndex != 0) {
        elementIndex -= 1
      } else {
        blockIndex -= 1;
        if (blockIndex == 0) return null;
        db := list.blocks[blockIndex];
        elementIndex := db.size() - 1
      };
      switch (db[elementIndex]) {
        case (?x) {
          if (equal(x, element)) return ?size<T>({
            var blocks = [var];
            var blockIndex = blockIndex;
            var elementIndex = elementIndex
          })
        };
        case (_) Prim.trap(INTERNAL_ERROR)
      }
    }
  };

  /// Returns the first value in `list` for which `predicate` returns true.
  /// If no element satisfies the predicate, returns null.
  ///
  /// ```motoko include=import
  /// let list = List.fromArray<Nat>([1, 9, 4, 8]);
  /// let found = List.find<Nat>(list, func(x) { x > 8 });
  /// assert found == ?9;
  /// ```
  /// Runtime: O(size)
  ///
  /// Space: O(1)
  ///
  /// *Runtime and space assumes that `predicate` runs in O(1) time and space.
  public func find<T>(list : List<T>, predicate : T -> Bool) : ?T {
    Option.map<Nat, T>(findIndex<T>(list, predicate), func(i) = get(list, i))
  };

  /// Finds the index of the first element in `list` for which `predicate` is true.
  /// Returns `null` if no such element is found.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 1);
  /// List.add(list, 2);
  /// List.add(list, 3);
  /// List.add(list, 4);
  ///
  /// assert List.findIndex<Nat>(list, func(i) { i % 2 == 0 }) == ?1;
  /// assert List.findIndex<Nat>(list, func(i) { i > 5 }) == null;
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// *Runtime and space assumes that `predicate` runs in `O(1)` time and space.
  public func findIndex<T>(list : List<T>, predicate : T -> Bool) : ?Nat {
    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return null;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) if (predicate(x)) return ?size<T>({
            var blocks = [var];
            var blockIndex = i;
            var elementIndex = j
          });
          case null return null
        };
        j += 1
      };
      i += 1
    };
    null
  };

  /// Finds the index of the last element in `list` for which `predicate` is true.
  /// Returns `null` if no such element is found.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 1);
  /// List.add(list, 2);
  /// List.add(list, 3);
  /// List.add(list, 4);
  ///
  /// assert List.findLastIndex<Nat>(list, func(i) { i % 2 == 0 }) == ?3;
  /// assert List.findLastIndex<Nat>(list, func(i) { i > 5 }) == null;
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// *Runtime and space assumes that `predicate` runs in `O(1)` time and space.
  public func findLastIndex<T>(list : List<T>, predicate : T -> Bool) : ?Nat {
    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;
    var db : [var ?T] = if (blockIndex < list.blocks.size()) {
      list.blocks[blockIndex]
    } else { [var] };

    loop {
      if (elementIndex != 0) {
        elementIndex -= 1
      } else {
        blockIndex -= 1;
        if (blockIndex == 0) return null;
        db := list.blocks[blockIndex];
        elementIndex := db.size() - 1
      };
      switch (db[elementIndex]) {
        case (?x) {
          if (predicate(x)) return ?size<T>({
            var blocks = [var];
            var blockIndex = blockIndex;
            var elementIndex = elementIndex
          })
        };
        case (_) Prim.trap(INTERNAL_ERROR)
      }
    }
  };

  /// Returns true iff every element in `list` satisfies `predicate`.
  /// In particular, if `list` is empty the function returns `true`.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 2);
  /// List.add(list, 3);
  /// List.add(list, 4);
  ///
  /// assert List.all<Nat>(list, func x { x > 1 });
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `predicate` runs in O(1) time and space.
  public func all<T>(list : List<T>, predicate : T -> Bool) : Bool {
    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return true;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) if (not predicate(x)) return false;
          case null return true
        };
        j += 1
      };
      i += 1
    };
    true
  };

  /// Returns true iff some element in `list` satisfies `predicate`.
  /// In particular, if `list` is empty the function returns `false`.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 2);
  /// List.add(list, 3);
  /// List.add(list, 4);
  ///
  /// assert List.any<Nat>(list, func x { x > 3 });
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `predicate` runs in O(1) time and space.
  public func any<T>(list : List<T>, predicate : T -> Bool) : Bool {
    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return false;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) if (predicate(x)) return true;
          case null return false
        };
        j += 1
      };
      i += 1
    };
    false
  };

  /// Returns an Iterator (`Iter`) over the elements of a List.
  /// Iterator provides a single method `next()`, which returns
  /// elements in order, or `null` when out of elements to iterate over.
  ///
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.add(list, 11);
  /// List.add(list, 12);
  ///
  /// var sum = 0;
  /// for (element in List.values(list)) {
  ///   sum += element;
  /// };
  /// assert sum == 33;
  /// ```
  ///
  /// Note: This does not create a snapshot. If the returned iterator is not consumed at once,
  /// and instead the consumption of the iterator is interleaved with other operations on the
  /// List, then this may lead to unexpected results.
  ///
  /// Runtime: `O(1)`
  public func values<T>(list : List<T>) : Iter.Iter<T> = object {
    let blocks = list.blocks.size();
    var blockIndex = 0;
    var elementIndex = 0;
    var db : [var ?T] = list.blocks[blockIndex];
    var dbSize = db.size();

    public func next() : ?T {
      if (elementIndex == dbSize) {
        blockIndex += 1;
        if (blockIndex >= blocks) return null;
        db := list.blocks[blockIndex];
        dbSize := db.size();
        if (dbSize == 0) return null;
        elementIndex := 0
      };
      switch (db[elementIndex]) {
        case (?x) {
          elementIndex += 1;
          return ?x
        };
        case (_) return null
      }
    }
  };

  /// Returns an Iterator (`Iter`) over the items (index-value pairs) in the list.
  /// Each item is a tuple of `(index, value)`. The iterator provides a single method
  /// `next()` which returns elements in order, or `null` when out of elements.
  ///
  /// ```motoko include=import
  /// import Iter "mo:core/Iter";
  ///
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.add(list, 11);
  /// List.add(list, 12);
  /// assert Iter.toArray(List.enumerate(list)) == [(0, 10), (1, 11), (2, 12)];
  /// ```
  ///
  /// Note: This does not create a snapshot. If the returned iterator is not consumed at once,
  /// and instead the consumption of the iterator is interleaved with other operations on the
  /// List, then this may lead to unexpected results.
  ///
  /// Runtime: `O(1)`
  ///
  /// Warning: Allocates memory on the heap to store ?(Nat, T).
  public func enumerate<T>(list : List<T>) : Iter.Iter<(Nat, T)> = object {
    let blocks = list.blocks.size();
    var blockIndex = 0;
    var elementIndex = 0;
    var size = 0;
    var db : [var ?T] = [var];
    var i = 0;

    public func next() : ?(Nat, T) {
      if (elementIndex == size) {
        blockIndex += 1;
        if (blockIndex >= blocks) return null;
        db := list.blocks[blockIndex];
        size := db.size();
        if (size == 0) return null;
        elementIndex := 0
      };
      switch (db[elementIndex]) {
        case (?x) {
          let ret = ?(i, x);
          elementIndex += 1;
          i += 1;
          return ret
        };
        case (_) return null
      }
    }
  };

  /// Returns an Iterator (`Iter`) over the elements of the list in reverse order.
  /// The iterator provides a single method `next()` which returns elements from
  /// last to first, or `null` when out of elements.
  ///
  /// ```motoko include=import
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.add(list, 11);
  /// List.add(list, 12);
  ///
  /// var sum = 0;
  /// for (element in List.reverseValues(list)) {
  ///   sum += element;
  /// };
  /// assert sum == 33;
  /// ```
  ///
  /// Note: This does not create a snapshot. If the returned iterator is not consumed at once,
  /// and instead the consumption of the iterator is interleaved with other operations on the
  /// List, then this may lead to unexpected results.
  ///
  /// Runtime: `O(1)`
  public func reverseValues<T>(list : List<T>) : Iter.Iter<T> = object {
    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;
    var db : [var ?T] = if (blockIndex < list.blocks.size()) {
      list.blocks[blockIndex]
    } else { [var] };

    public func next() : ?T {
      if (elementIndex != 0) {
        elementIndex -= 1
      } else {
        blockIndex -= 1;
        if (blockIndex == 0) return null;
        db := list.blocks[blockIndex];
        elementIndex := db.size() - 1
      };

      db[elementIndex]
    }
  };

  /// Returns an Iterator (`Iter`) over the items in reverse order, i.e. pairs of index and value.
  /// Iterator provides a single method `next()`, which returns
  /// elements in reverse order, or `null` when out of elements to iterate over.
  ///
  /// ```motoko include=import
  /// import Iter "mo:core/Iter";
  ///
  /// let list = List.empty<Nat>();
  /// List.add(list, 10);
  /// List.add(list, 11);
  /// List.add(list, 12);
  /// assert Iter.toArray(List.reverseEnumerate(list)) == [(2, 12), (1, 11), (0, 10)];
  /// ```
  ///
  /// Note: This does not create a snapshot. If the returned iterator is not consumed at once,
  /// and instead the consumption of the iterator is interleaved with other operations on the
  /// List, then this may lead to unexpected results.
  ///
  /// Runtime: `O(1)`
  ///
  /// Warning: Allocates memory on the heap to store ?(T, Nat).
  public func reverseEnumerate<T>(list : List<T>) : Iter.Iter<(Nat, T)> = object {
    var i = size(list);
    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;
    var db : [var ?T] = if (blockIndex < list.blocks.size()) {
      list.blocks[blockIndex]
    } else { [var] };

    public func next() : ?(Nat, T) {
      if (elementIndex != 0) {
        elementIndex -= 1
      } else {
        blockIndex -= 1;
        if (blockIndex == 0) return null;
        db := list.blocks[blockIndex];
        elementIndex := db.size() - 1
      };
      switch (db[elementIndex]) {
        case (?x) {
          i -= 1;
          return ?(i, x)
        };
        case (_) Prim.trap(INTERNAL_ERROR)
      }
    }
  };

  /// Returns an Iterator (`Iter`) over the indices (keys) of the list.
  /// The iterator provides a single method `next()` which returns indices
  /// from 0 to size-1, or `null` when out of elements.
  ///
  /// ```motoko include=import
  /// import Iter "mo:core/Iter";
  ///
  /// let list = List.empty<Text>();
  /// List.add(list, "A");
  /// List.add(list, "B");
  /// List.add(list, "C");
  /// Iter.toArray(List.keys(list)) // [0, 1, 2]
  /// ```
  ///
  /// Note: This does not create a snapshot. If the returned iterator is not consumed at once,
  /// and instead the consumption of the iterator is interleaved with other operations on the
  /// List, then this may lead to unexpected results.
  ///
  /// Runtime: `O(1)`
  public func keys<T>(list : List<T>) : Iter.Iter<Nat> = Nat.range(0, size(list));

  /// Creates a new List containing all elements from the provided iterator.
  /// Elements are added in the order they are returned by the iterator.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Iter "mo:core/Iter";
  ///
  /// let array = [1, 1, 1];
  /// let iter = array.vals();
  ///
  /// let list = List.fromIter<Nat>(iter);
  /// assert Iter.toArray(List.values(list)) == [1, 1, 1];
  /// ```
  ///
  /// Runtime: `O(size)`
  public func fromIter<T>(iter : Iter.Iter<T>) : List<T> {
    let list = empty<T>();
    for (element in iter) add(list, element);
    list
  };

  /// Adds all elements from the provided iterator to the end of the list.
  /// Elements are added in the order they are returned by the iterator.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Iter "mo:core/Iter";
  ///
  /// let array = [1, 1, 1];
  /// let iter = array.vals();
  /// let list = List.repeat<Nat>(2, 1);
  ///
  /// List.addAll<Nat>(list, iter);
  /// assert Iter.toArray(List.values(list)) == [2, 1, 1, 1];
  /// ```
  ///
  /// The maximum number of elements in a `List` is 2^32.
  ///
  /// Runtime: `O(size)`, where n is the size of iter.
  public func addAll<T>(list : List<T>, iter : Iter.Iter<T>) {
    for (element in iter) add(list, element)
  };

  /// Creates a new immutable array containing all elements from the list.
  /// Elements appear in the same order as in the list.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.fromArray<Nat>([1, 2, 3]);
  ///
  /// assert List.toArray<Nat>(list) == [1, 2, 3];
  /// ```
  ///
  /// Runtime: `O(size)`
  public func toArray<T>(list : List<T>) : [T] {
    let blocks = list.blocks.size();
    var blockIndex = 0;
    var elementIndex = 0;
    var sz = 0;
    var db : [var ?T] = [var];

    func generator(_ : Nat) : T {
      if (elementIndex == sz) {
        blockIndex += 1;
        if (blockIndex >= blocks) Prim.trap(INTERNAL_ERROR);
        db := list.blocks[blockIndex];
        sz := db.size();
        if (sz == 0) Prim.trap(INTERNAL_ERROR);
        elementIndex := 0
      };
      switch (db[elementIndex]) {
        case (?x) {
          elementIndex += 1;
          return x
        };
        case (_) Prim.trap(INTERNAL_ERROR)
      }
    };

    Array.tabulate<T>(size(list), generator)
  };

  /// Creates a List containing elements from an Array.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Iter "mo:core/Iter";
  ///
  /// let array = [2, 3];
  /// let list = List.fromArray<Nat>(array);
  /// assert Iter.toArray(List.values(list)) == [2, 3];
  /// ```
  ///
  /// Runtime: `O(size)`
  public func fromArray<T>(array : [T]) : List<T> {
    let (blockIndex, elementIndex) = locate(array.size());

    let blocks = newIndexBlockLength(Nat32.fromNat(if (elementIndex == 0) { blockIndex - 1 } else blockIndex));
    let dataBlocks = VarArray.repeat<[var ?T]>([var], blocks);

    func makeBlock(array : [T], p : Nat, len : Nat, fill : Nat) : [var ?T] {
      let block = VarArray.repeat<?T>(null, len);
      var j = 0;
      var pos = p;
      while (j < fill) {
        block[j] := ?array[pos];
        j += 1;
        pos += 1
      };
      block
    };

    var i = 1;
    var pos = 0;

    while (i < blockIndex) {
      let len = dataBlockSize(i);
      dataBlocks[i] := makeBlock(array, pos, len, len);
      pos += len;
      i += 1
    };
    if (elementIndex != 0 and blockIndex < blocks) {
      dataBlocks[i] := makeBlock(array, pos, dataBlockSize(i), elementIndex)
    };

    {
      var blocks = dataBlocks;
      var blockIndex = blockIndex;
      var elementIndex = elementIndex
    }
  };

  /// Creates a new mutable array containing all elements from the list.
  /// Elements appear in the same order as in the list.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Array "mo:core/Array";
  ///
  /// let list = List.fromArray<Nat>([1, 2, 3]);
  ///
  /// let varArray = List.toVarArray<Nat>(list);
  /// assert Array.fromVarArray(varArray) == [1, 2, 3];
  /// ```
  ///
  /// Runtime: `O(size)`
  public func toVarArray<T>(list : List<T>) : [var T] {
    let ?fs = first(list) else return [var];

    let array = VarArray.repeat<T>(fs, size(list));

    var index = 0;

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return array;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) array[index] := x;
          case null return array
        };
        j += 1;
        index += 1
      };
      i += 1
    };
    array
  };

  /// Creates a new List containing all elements from the mutable array.
  /// Elements appear in the same order as in the array.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Iter "mo:core/Iter";
  ///
  /// let array = [var 2, 3];
  /// let list = List.fromVarArray<Nat>(array);
  /// assert Iter.toArray(List.values(list)) == [2, 3];
  /// ```
  ///
  /// Runtime: `O(size)`
  public func fromVarArray<T>(array : [var T]) : List<T> {
    let (blockIndex, elementIndex) = locate(array.size());

    let blocks = newIndexBlockLength(Nat32.fromNat(if (elementIndex == 0) { blockIndex - 1 } else blockIndex));
    let dataBlocks = VarArray.repeat<[var ?T]>([var], blocks);

    func makeBlock(array : [var T], p : Nat, len : Nat, fill : Nat) : [var ?T] {
      let block = VarArray.repeat<?T>(null, len);
      var j = 0;
      var pos = p;
      while (j < fill) {
        block[j] := ?array[pos];
        j += 1;
        pos += 1
      };
      block
    };

    var i = 1;
    var pos = 0;

    while (i < blockIndex) {
      let len = dataBlockSize(i);
      dataBlocks[i] := makeBlock(array, pos, len, len);
      pos += len;
      i += 1
    };
    if (elementIndex != 0 and blockIndex < blocks) {
      dataBlocks[i] := makeBlock(array, pos, dataBlockSize(i), elementIndex)
    };

    {
      var blocks = dataBlocks;
      var blockIndex = blockIndex;
      var elementIndex = elementIndex
    }
  };

  /// Returns the first element of `list`, or `null` if the list is empty.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert List.first(List.fromArray<Nat>([1, 2, 3])) == ?1;
  /// assert List.first(List.empty<Nat>()) == null;
  /// ```
  ///
  /// Runtime: `O(1)`
  ///
  /// Space: `O(1)`
  public func first<T>(list : List<T>) : ?T {
    if (list.blockIndex == 1 and list.elementIndex == 0) null else list.blocks[1][0]
  };

  /// Returns the last element of `list`. Traps if `list` is empty.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert List.last(List.fromArray<Nat>([1, 2, 3])) == ?3;
  /// assert List.last(List.empty<Nat>()) == null;
  /// ```
  ///
  /// Runtime: `O(1)`
  ///
  /// Space: `O(1)`
  public func last<T>(list : List<T>) : ?T {
    let e = list.elementIndex;
    if (e > 0) return list.blocks[list.blockIndex][e - 1];

    let b = list.blockIndex - 1 : Nat;
    if (b == 0) null else {
      let block = list.blocks[b];
      block[block.size() - 1]
    }
  };

  public func forEachEntryChange<T>(
    list : List<T>,
    f : (i : Nat, oldValue : T) -> (newValue : T)
  ) {
    var index = 0;

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) db[j] := ?f(index, x);
          case null return
        };
        index += 1;
        j += 1
      };
      i += 1
    }
  };

  public func forEachChange<T>(
    list : List<T>,
    f : (oldValue : T) -> (newValue : T)
  ) {
    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) db[j] := ?f(x);
          case null return
        };
        j += 1
      };
      i += 1
    }
  };

  /// Applies `f` to each element in `list`.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Debug "mo:core/Debug";
  ///
  /// let list = List.fromArray<Nat>([1, 2, 3]);
  ///
  /// List.forEach<Nat>(list, func(x) {
  ///   Debug.print(Nat.toText(x)); // prints each element in list
  /// });
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  ///
  /// *Runtime and space assumes that `f` runs in O(1) time and space.
  public func forEach<T>(list : List<T>, f : T -> ()) {
    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) f(x);
          case null return
        };
        j += 1
      };
      i += 1
    }
  };

  /// Applies `f` to each item `(i, x)` in `list` where `i` is the key
  /// and `x` is the value.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Debug "mo:core/Debug";
  ///
  /// let list = List.fromArray<Nat>([1, 2, 3]);
  ///
  /// List.forEachEntry<Nat>(list, func (i,x) {
  ///   // prints each item (i,x) in list
  ///   Debug.print(Nat.toText(i) # Nat.toText(x));
  /// });
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  ///
  /// *Runtime and space assumes that `f` runs in O(1) time and space.
  public func forEachEntry<T>(list : List<T>, f : (Nat, T) -> ()) {
    var index = 0;
    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) f(index, x);
          case null return
        };
        j += 1;
        index += 1
      };
      i += 1
    }
  };

  func actualInterval(fromInclusive : Int, toExclusive : Int, size : Nat) : (Nat, Nat) {
    let startInt = if (fromInclusive < 0) {
      let s = size + fromInclusive;
      if (s < 0) { 0 } else { s }
    } else {
      if (fromInclusive > size) { size } else { fromInclusive }
    };
    let endInt = if (toExclusive < 0) {
      let e = size + toExclusive;
      if (e < 0) { 0 } else { e }
    } else {
      if (toExclusive > size) { size } else { toExclusive }
    };
    (Prim.abs(startInt), Prim.abs(endInt))
  };

  /// Returns an iterator over a slice of `list` starting at `fromInclusive` up to (but not including) `toExclusive`.
  ///
  /// Negative indices are relative to the end of the list. For example, `-1` corresponds to the last element in the list.
  ///
  /// If the indices are out of bounds, they are clamped to the list bounds.
  /// If the first index is greater than the second, the function returns an empty iterator.
  ///
  /// ```motoko include=import
  /// let list = List.fromArray([1, 2, 3, 4, 5]);
  /// let iter1 = List.range<Nat>(list, 3, list.size());
  /// assert iter1.next() == ?4;
  /// assert iter1.next() == ?5;
  /// assert iter1.next() == null;
  ///
  /// let iter2 = List.range<Nat>(list, 3, -1);
  /// assert iter2.next() == ?4;
  /// assert iter2.next() == null;
  ///
  /// let iter3 = List.range<Nat>(list, 0, 0);
  /// assert iter3.next() == null;
  /// ```
  ///
  /// Runtime: O(1)
  ///
  /// Space: O(1)
  public func range<T>(list : List<T>, fromInclusive : Int, toExclusive : Int) : Iter.Iter<T> = object {
    let (start, end) = actualInterval(fromInclusive, toExclusive, size(list));
    let blocks = list.blocks.size();
    var blockIndex = 0;
    var elementIndex = 0;
    if (start != 0) {
      let (block, element) = locate(start - 1);
      blockIndex := block;
      elementIndex := element + 1
    };
    var db : [var ?T] = list.blocks[blockIndex];
    var dbSize = db.size();
    var index = 0;

    public func next() : ?T {
      if (index >= end) return null;
      index += 1;

      if (elementIndex == dbSize) {
        blockIndex += 1;
        if (blockIndex >= blocks) return null;
        db := list.blocks[blockIndex];
        dbSize := db.size();
        if (dbSize == 0) return null;
        elementIndex := 0
      };
      let ret = db[elementIndex];
      elementIndex += 1;
      ret
    }
  };

  public func forEachRange<T>(list : List<T>, f : T -> (), fromInclusive : Nat, toExclusive : Nat) {
    if (not (fromInclusive <= toExclusive and toExclusive <= size(list))) Prim.trap("Invalid range");

    func traverseBlock(block : [var ?T], f : T -> (), from : Nat, to : Nat) {
      var i = from;
      while (i < to) {
        switch (block[i]) {
          case (?value) f(value);
          case null Prim.trap(INTERNAL_ERROR)
        };
        i += 1
      }
    };

    let (fromBlock, fromElement) = locate(fromInclusive);
    let (toBlock, toElement) = locate(toExclusive);

    let blocks = list.blocks;
    let sz = blocks.size();

    if (fromBlock == toBlock) {
      if (fromBlock < sz) traverseBlock(blocks[fromBlock], f, fromElement, toElement);
      return
    };

    traverseBlock(blocks[fromBlock], f, fromElement, blocks[fromBlock].size());

    var i = fromBlock + 1;
    let to = Nat.min(toBlock, sz);
    while (i < to) {
      traverseBlock(blocks[i], f, 0, blocks[i].size());
      i += 1
    };

    if (toBlock < sz) traverseBlock(blocks[toBlock], f, 0, toElement)
  };

  /// Returns a new array containing elements from `list` starting at index `fromInclusive` up to (but not including) index `toExclusive`.
  /// If the indices are out of bounds, they are clamped to the array bounds.
  ///
  /// ```motoko include=import
  /// let array = List.fromArray([1, 2, 3, 4, 5]);
  ///
  /// let slice1 = List.sliceToArray<Nat>(array, 1, 4);
  /// assert slice1 == [2, 3, 4];
  ///
  /// let slice2 = List.sliceToArray<Nat>(array, 1, -1);
  /// assert slice2 == [2, 3, 4];
  /// ```
  ///
  /// Runtime: O(toExclusive - fromInclusive)
  ///
  /// Space: O(toExclusive - fromInclusive)
  public func sliceToArray<T>(list : List<T>, fromInclusive : Int, toExclusive : Int) : [T] {
    let (start, end) = actualInterval(fromInclusive, toExclusive, size(list));
    let blocks = list.blocks.size();
    var blockIndex = 0;
    var elementIndex = 0;
    if (start != 0) {
      let (block, element) = locate(start - 1);
      blockIndex := block;
      elementIndex := element + 1
    };
    var db : [var ?T] = list.blocks[blockIndex];
    var dbSize = db.size();

    func generator(i : Nat) : T {
      if (elementIndex == dbSize) {
        blockIndex += 1;
        if (blockIndex >= blocks) Prim.trap(INTERNAL_ERROR);
        db := list.blocks[blockIndex];
        dbSize := db.size();
        if (dbSize == 0) Prim.trap(INTERNAL_ERROR);
        elementIndex := 0
      };
      switch (db[elementIndex]) {
        case (?x) {
          elementIndex += 1;
          return x
        };
        case null Prim.trap(INTERNAL_ERROR)
      }
    };
    Array.tabulate<T>(end - start, generator)
  };

  /// Like `forEachEntryRev` but iterates through the list in reverse order,
  /// from end to beginning.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Debug "mo:core/Debug";
  ///
  /// let list = List.fromArray<Nat>([1, 2, 3]);
  ///
  /// List.reverseForEachEntry<Nat>(list, func (i,x) {
  ///   // prints each item (i,x) in list
  ///   Debug.print(Nat.toText(i) # Nat.toText(x));
  /// });
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  ///
  /// *Runtime and space assumes that `f` runs in O(1) time and space.
  public func reverseForEachEntry<T>(list : List<T>, f : (Nat, T) -> ()) {
    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;
    var db : [var ?T] = if (blockIndex < list.blocks.size()) {
      list.blocks[blockIndex]
    } else { [var] };
    var i = size(list);

    loop {
      if (elementIndex != 0) {
        elementIndex -= 1
      } else {
        blockIndex -= 1;
        if (blockIndex == 0) return;
        db := list.blocks[blockIndex];
        elementIndex := db.size() - 1
      };
      i -= 1;
      switch (db[elementIndex]) {
        case (?x) f(i, x);
        case (_) Prim.trap(INTERNAL_ERROR)
      }
    }
  };

  /// Applies `f` to each element in `list` in reverse order.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Debug "mo:core/Debug";
  ///
  /// let list = List.fromArray<Nat>([1, 2, 3]);
  ///
  /// List.reverseForEach<Nat>(list, func (x) {
  ///   Debug.print(Nat.toText(x)); // prints each element in list in reverse order
  /// });
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  ///
  /// *Runtime and space assumes that `f` runs in O(1) time and space.
  public func reverseForEach<T>(list : List<T>, f : T -> ()) {
    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;
    var db : [var ?T] = if (blockIndex < list.blocks.size()) {
      list.blocks[blockIndex]
    } else { [var] };

    loop {
      if (elementIndex != 0) {
        elementIndex -= 1
      } else {
        blockIndex -= 1;
        if (blockIndex == 0) return;
        db := list.blocks[blockIndex];
        elementIndex := db.size() - 1
      };
      switch (db[elementIndex]) {
        case (?x) f(x);
        case (_) Prim.trap(INTERNAL_ERROR)
      }
    }
  };

  /// Returns true if the list contains the specified element according to the provided
  /// equality function. Uses the provided `equal` function to compare elements.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.empty<Nat>();
  /// List.add(list, 2);
  /// List.add(list, 0);
  /// List.add(list, 3);
  ///
  /// assert List.contains<Nat>(list, Nat.equal, 2);
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `equal` runs in O(1) time and space.
  public func contains<T>(list : List<T>, equal : (T, T) -> Bool, element : T) : Bool {
    Option.isSome(indexOf(list, equal, element))
  };

  /// Returns the greatest element in the list according to the ordering defined by `compare`.
  /// Returns `null` if the list is empty.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.empty<Nat>();
  /// List.add(list, 1);
  /// List.add(list, 2);
  ///
  /// assert List.max<Nat>(list, Nat.compare) == ?2;
  /// assert List.max<Nat>(List.empty<Nat>(), Nat.compare) == null;
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `compare` runs in O(1) time and space.
  public func max<T>(list : List<T>, compare : (T, T) -> Order.Order) : ?T {
    var maxSoFar : T = switch (first(list)) {
      case (?x) x;
      case null return null
    };

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return ?maxSoFar;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) switch (compare(x, maxSoFar)) {
            case (#greater) maxSoFar := x;
            case _ {}
          };
          case null return ?maxSoFar
        };
        j += 1
      };
      i += 1
    };

    ?maxSoFar
  };

  /// Returns the least element in the list according to the ordering defined by `compare`.
  /// Returns `null` if the list is empty.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.empty<Nat>();
  /// List.add(list, 1);
  /// List.add(list, 2);
  ///
  /// assert List.min<Nat>(list, Nat.compare) == ?1;
  /// assert List.min<Nat>(List.empty<Nat>(), Nat.compare) == null;
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `compare` runs in O(1) time and space.
  public func min<T>(list : List<T>, compare : (T, T) -> Order.Order) : ?T {
    var minSoFar : T = switch (first(list)) {
      case (?x) x;
      case null return null
    };

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return ?minSoFar;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) switch (compare(x, minSoFar)) {
            case (#less) minSoFar := x;
            case _ {}
          };
          case null return ?minSoFar
        };
        j += 1
      };
      i += 1
    };

    ?minSoFar
  };

  /// Tests if two lists are equal by comparing their elements using the provided `equal` function.
  /// Returns true if and only if both lists have the same size and all corresponding elements
  /// are equal according to the provided function.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list1 = List.fromArray<Nat>([1,2]);
  /// let list2 = List.empty<Nat>();
  /// List.add(list2, 1);
  /// List.add(list2, 2);
  ///
  /// assert List.equal<Nat>(list1, list2, Nat.equal);
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `equal` runs in O(1) time and space.
  public func equal<T>(list1 : List<T>, list2 : List<T>, equal : (T, T) -> Bool) : Bool {
    if (size(list1) != size(list2)) return false;

    let blocks1 = list1.blocks;
    let blocks2 = list2.blocks;
    let blockCount = Nat.min(blocks1.size(), blocks2.size());

    var i = 1;
    while (i < blockCount) {
      let db1 = blocks1[i];
      let db2 = blocks2[i];
      let sz = Nat.min(db1.size(), db2.size());
      if (sz == 0) return true;

      var j = 0;
      while (j < sz) {
        switch (db1[j], db2[j]) {
          case (?x, ?y) if (not equal(x, y)) return false;
          case (_, _) return true
        };
        j += 1
      };
      i += 1
    };
    return true
  };

  /// Compares two lists lexicographically using the provided `compare` function.
  /// Elements are compared pairwise until a difference is found or one list ends.
  /// If all elements compare equal, the shorter list is considered less than the longer list.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list1 = List.fromArray<Nat>([0, 1]);
  /// let list2 = List.fromArray<Nat>([2]);
  /// let list3 = List.fromArray<Nat>([0, 1, 2]);
  ///
  /// assert List.compare<Nat>(list1, list2, Nat.compare) == #less;
  /// assert List.compare<Nat>(list1, list3, Nat.compare) == #less;
  /// assert List.compare<Nat>(list2, list3, Nat.compare) == #greater;
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `compare` runs in O(1) time and space.
  public func compare<T>(list1 : List<T>, list2 : List<T>, compare : (T, T) -> Order.Order) : Order.Order {
    let blocks1 = list1.blocks;
    let blocks2 = list2.blocks;
    let blockCount = Nat.min(blocks1.size(), blocks2.size());

    var i = 1;
    while (i < blockCount) {
      let db1 = blocks1[i];
      let db2 = blocks2[i];
      let sz = Nat.min(db1.size(), db2.size());
      if (sz == 0) return Nat.compare(size(list1), size(list2));

      var j = 0;
      while (j < sz) {
        switch (db1[j], db2[j]) {
          case (?x, ?y) switch (compare(x, y)) {
            case (#less) return #less;
            case (#greater) return #greater;
            case _ {}
          };
          case (_, _) return Nat.compare(size(list1), size(list2))
        };
        j += 1
      };
      i += 1
    };
    return Nat.compare(size(list1), size(list2))
  };

  /// Creates a textual representation of `list`, using `toText` to recursively
  /// convert the elements into Text.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.fromArray<Nat>([1,2,3,4]);
  ///
  /// assert List.toText<Nat>(list, Nat.toText) == "List[1, 2, 3, 4]";
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(size)`
  ///
  /// *Runtime and space assumes that `toText` runs in O(1) time and space.
  public func toText<T>(list : List<T>, f : T -> Text) : Text {
    func toTextInternal(list : List<T>, f : T -> Text) : Text {
      var text = switch (first(list)) {
        case (?x) f(x);
        case null return ""
      };

      let blocks = list.blocks;
      let blockCount = blocks.size();

      var i = 2;
      while (i < blockCount) {
        let db = blocks[i];
        let sz = db.size();
        if (sz == 0) return text;

        var j = 0;
        while (j < sz) {
          switch (db[j]) {
            case (?x) text := text # ", " # f(x);
            case null return text
          };
          j += 1
        };
        i += 1
      };
      text
    };
    "List[" # toTextInternal(list, f) # "]"
  };

  /// Collapses the elements in `list` into a single value by starting with `base`
  /// and progessively combining elements into `base` with `combine`. Iteration runs
  /// left to right.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.fromArray<Nat>([1,2,3]);
  ///
  /// assert List.foldLeft<Text, Nat>(list, "", func (acc, x) { acc # Nat.toText(x)}) == "123";
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `combine` runs in O(1)` time and space.
  public func foldLeft<A, T>(list : List<T>, base : A, combine : (A, T) -> A) : A {
    var accumulation = base;

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return accumulation;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) accumulation := combine(accumulation, x);
          case null return accumulation
        };
        j += 1
      };
      i += 1
    };
    accumulation
  };

  /// Collapses the elements in `list` into a single value by starting with `base`
  /// and progessively combining elements into `base` with `combine`. Iteration runs
  /// right to left.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.fromArray<Nat>([1,2,3]);
  ///
  /// assert List.foldRight<Nat, Text>(list, "", func (x, acc) { Nat.toText(x) # acc }) == "123";
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `combine` runs in O(1)` time and space.
  public func foldRight<T, A>(list : List<T>, base : A, combine : (T, A) -> A) : A {
    var accumulation = base;

    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;
    var db : [var ?T] = if (blockIndex < list.blocks.size()) {
      list.blocks[blockIndex]
    } else { [var] };

    loop {
      if (elementIndex != 0) {
        elementIndex -= 1
      } else {
        blockIndex -= 1;
        if (blockIndex == 0) return accumulation;
        db := list.blocks[blockIndex];
        elementIndex := db.size() - 1
      };
      switch (db[elementIndex]) {
        case (?x) accumulation := combine(x, accumulation);
        case (_) Prim.trap(INTERNAL_ERROR)
      }
    }
  };

  /// Reverses the order of elements in `list` by overwriting in place.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Iter "mo:core/Iter";
  ///
  /// let list = List.fromArray<Nat>([1,2,3]);
  ///
  /// List.reverseInPlace<Nat>(list);
  /// assert Iter.toArray(List.values(list)) == [3, 2, 1];
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  public func reverseInPlace<T>(list : List<T>) {
    let vsize = size(list);
    if (vsize <= 1) return;

    let count = vsize / 2;
    var i = 0;

    let blocks = list.blocks.size();
    var blockIndexFront = 0;
    var elementIndexFront = 0;
    var sz = 0;
    var dbFront : [var ?T] = [var];

    var blockIndexBack = list.blockIndex;
    var elementIndexBack = list.elementIndex;
    var dbBack : [var ?T] = if (blockIndexBack < list.blocks.size()) {
      list.blocks[blockIndexBack]
    } else { [var] };

    while (i < count) {
      if (elementIndexFront == sz) {
        blockIndexFront += 1;
        if (blockIndexFront >= blocks) return;
        dbFront := list.blocks[blockIndexFront];
        sz := dbFront.size();
        if (sz == 0) return;
        elementIndexFront := 0
      };

      if (elementIndexBack == 0) {
        blockIndexBack -= 1;
        if (blockIndexBack == 0) return;
        dbBack := list.blocks[blockIndexBack];
        elementIndexBack := dbBack.size() - 1
      } else {
        elementIndexBack -= 1
      };

      let temp = dbFront[elementIndexFront];
      dbFront[elementIndexFront] := dbBack[elementIndexBack];
      dbBack[elementIndexBack] := temp;

      elementIndexFront += 1;

      i += 1
    }
  };

  /// Returns a new List with the elements from `list` in reverse order.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  /// import Iter "mo:core/Iter";
  ///
  /// let list = List.fromArray<Nat>([1,2,3]);
  ///
  /// let rlist = List.reverse<Nat>(list);
  /// assert Iter.toArray(List.values(rlist)) == [3, 2, 1];
  /// ```
  ///
  /// Runtime: `O(size)`
  ///
  /// Space: `O(1)`
  public func reverse<T>(list : List<T>) : List<T> {
    let rlist = repeatInternal<T>(null, size(list));

    let blocks = list.blocks.size();
    var blockIndexFront = 0;
    var elementIndexFront = 0;
    var sz = 0;
    var dbFront : [var ?T] = [var];

    var blockIndexBack = rlist.blockIndex;
    var elementIndexBack = rlist.elementIndex;
    var dbBack : [var ?T] = if (blockIndexBack < rlist.blocks.size()) {
      rlist.blocks[blockIndexBack]
    } else { [var] };

    loop {
      if (elementIndexFront == sz) {
        blockIndexFront += 1;
        if (blockIndexFront >= blocks) return rlist;
        dbFront := list.blocks[blockIndexFront];
        sz := dbFront.size();
        if (sz == 0) return rlist;
        elementIndexFront := 0
      };

      if (elementIndexBack == 0) {
        blockIndexBack -= 1;
        if (blockIndexBack == 0) return rlist;
        dbBack := rlist.blocks[blockIndexBack];
        elementIndexBack := dbBack.size() - 1
      } else {
        elementIndexBack -= 1
      };

      dbBack[elementIndexBack] := dbFront[elementIndexFront];

      elementIndexFront += 1
    }
  };

  /// Returns true if and only if the list is empty.
  ///
  /// Example:
  /// ```motoko include=import
  /// let list = List.fromArray<Nat>([2,0,3]);
  /// assert not List.isEmpty<Nat>(list);
  /// assert List.isEmpty<Nat>(List.empty<Nat>());
  /// ```
  ///
  /// Runtime: `O(1)`
  ///
  /// Space: `O(1)`
  public func isEmpty<T>(list : List<T>) : Bool {
    list.blockIndex == 1 and list.elementIndex == 0
  };

  /// Concatenates the provided slices into a new list.
  /// Each slice is a tuple of a list, a starting index (inclusive), and an ending index (exclusive).
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:base/Nat";
  /// import Iter "mo:base/Iter";
  ///
  /// let list1 = List.fromArray<Nat>([1,2,3]);
  /// let list2 = List.fromArray<Nat>([4,5,6]);
  /// let result = List.concatSlices<Nat>([(list1, 0, 2), (list2, 1, 3)]);
  /// assert Iter.toArray(List.values(result)) == [1,2,5,6];
  /// ```
  ///
  /// Runtime: `O(sum_size)` where `sum_size` is the sum of the sizes of all slices.
  ///
  /// Space: `O(sum_size)`
  public func concatSlices<T>(slices : [(List<T>, fromInclusive : Nat, toExclusive : Nat)]) : List<T> {
    var length = 0;
    for (slice in slices.vals()) {
      let (list, start, end) = slice;
      let sz = size<T>(list);
      let ok = start <= end and end <= sz;
      if (not ok) {
        Runtime.trap("Invalid slice in concat")
      };
      length += end - start
    };

    var result = repeatInternal<T>(null, length);
    result.blockIndex := 1;
    result.elementIndex := 0;

    for (slice in slices.vals()) {
      let (list, start, end) = slice;
      forEachRange<T>(
        list,
        func(value) = add(result, value),
        start,
        end
      )
    };

    result
  };

  /// Concatenates the provided lists into a new list.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:base/Nat";
  /// import Iter "mo:base/Iter";
  ///
  /// let list1 = List.fromArray<Nat>([1, 2, 3]);
  /// let list2 = List.fromArray<Nat>([4, 5, 6]);
  /// let result = List.concat<Nat>([list1, list2]);
  /// assert Iter.toArray(List.values(result)) == [1, 2, 3, 4, 5, 6];
  /// ```
  ///
  /// Runtime: `O(sum_size)` where `sum_size` is the sum of the sizes of all lists.
  ///
  /// Space: `O(sum_size)`
  public func concat<T>(lists : [List<T>]) : List<T> {
    concatSlices<T>(Array.tabulate<(List<T>, Nat, Nat)>(lists.size(), func(i) = (lists[i], 0, size(lists[i]))))
  };

}
