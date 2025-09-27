/// A mutable growable array data structure with efficient random access and dynamic resizing.
/// `List` provides O(1) access time and O(sqrt(n)) memory overhead. In contrast, `pure/List` is a purely functional linked list.
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
import Nat32 "Nat32";
import Array "Array";
import Iter "Iter";
import Nat "Nat";
import Order "Order";
import Option "Option";
import VarArray "VarArray";
import Types "Types";

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

  func repeatInternal<T>(initValue : ?T, size : Nat) : List<T> {
    let (blockIndex, elementIndex) = locate(size);

    let blocks = newIndexBlockLength(Nat32.fromNat(if (elementIndex == 0) { blockIndex - 1 } else blockIndex));
    let dataBlocks = VarArray.repeat<[var ?T]>([var], blocks);
    var i = 1;
    while (i < blockIndex) {
      dataBlocks[i] := VarArray.repeat<?T>(initValue, dataBlockSize(i));
      i += 1
    };
    if (elementIndex != 0) {
      let block = VarArray.repeat<?T>(null, dataBlockSize(i));
      if (Option.isSome(initValue)) {
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

    let blocks = list.blocks;
    let blockIndex = list.blockIndex;
    let elementIndex = list.elementIndex;

    var i = blockIndex;
    if (elementIndex == 0) i -= 1;

    while (i > 0) {
      let db = blocks[i];
      let sz = db.size();
      var j = if (i == blockIndex) elementIndex else sz;
      while (j > 0) {
        j -= 1;
        switch (db[j]) {
          case (?x) result := ?(x, result);
          case null Prim.trap INTERNAL_ERROR
        }
      };
      i -= 1
    };

    result
  };

  /// Converts a purely functional `PureList` to a mutable `List`.
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
  public func fromPure<T>(pure : PureList.List<T>) : List<T> {
    var p = pure;
    var list = empty<T>();
    loop {
      switch (p) {
        case (?(x, xs)) {
          add(list, x);
          p := xs
        };
        case null return list
      }
    }
  };

  func addRepeatInternal<T>(list : List<T>, initValue : ?T, count : Nat) {
    let (b, e) = locate(size(list) + count);
    let blocksCount = newIndexBlockLength(Nat32.fromNat(if (e == 0) b - 1 else b));

    let oldBlocksCount = list.blocks.size();
    if (oldBlocksCount < blocksCount) {
      let oldBlocks = list.blocks;
      let blocks = VarArray.repeat<[var ?T]>([var], blocksCount);
      var i = 0;
      while (i < oldBlocksCount) {
        blocks[i] := oldBlocks[i];
        i += 1
      };
      list.blocks := blocks
    };

    let blocks = list.blocks;
    var blockIndex = list.blockIndex;
    var elementIndex = list.elementIndex;

    var cnt = count;
    label L while (cnt > 0) {
      if (blocks[blockIndex].size() == 0) {
        let dbSize = dataBlockSize(blockIndex);
        if (cnt >= dbSize) {
          blocks[blockIndex] := VarArray.repeat<?T>(initValue, dbSize);
          blockIndex += 1;
          cnt -= dbSize;
          continue L
        };
        blocks[blockIndex] := VarArray.repeat<?T>(null, dbSize)
      };

      let block = blocks[blockIndex];
      let dbSize = block.size();
      let to = Nat.min(elementIndex + cnt, dbSize);
      cnt -= to - elementIndex;

      while (elementIndex < to) {
        block[elementIndex] := initValue;
        elementIndex += 1
      };

      if (elementIndex == dbSize) {
        elementIndex := 0;
        blockIndex += 1
      }
    };

    list.blockIndex := blockIndex;
    list.elementIndex := elementIndex
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

  func indexByBlockElement(block : Nat, element : Nat) : Nat {
    let d = Nat32.fromNat(block);

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
    Nat32.toNat((d -% (1 <>> lz)) <>> lz +% Nat32.fromNat(element))
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
    // due to the design of List (blockIndex, elementIndex) pair points
    // exactly to the place where size-th element should be added
    // so, it's the inlined version of indexByBlockElement
    let d = Nat32.fromNat(list.blockIndex);
    let lz = Nat32.bitcountLeadingZero(d / 3);
    Nat32.toNat((d -% (1 <>> lz)) <>> lz +% Nat32.fromNat(list.elementIndex))
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
      var blockIndex = list.blockIndex;
      if (blockIndex == 1) {
        return null
      };

      shrinkIndexBlockIfNeeded(list);

      blockIndex -= 1;
      elementIndex := list.blocks[blockIndex].size();

      // Keep one totally empty block when removing
      if (blockIndex + 2 < list.blocks.size()) list.blocks[blockIndex + 2] := [var];

      list.blockIndex := blockIndex
    };
    elementIndex -= 1;

    let lastDataBlock = list.blocks[list.blockIndex];

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
  /// assert List.at(list, 0) == 10;
  /// ```
  ///
  /// Runtime: `O(1)`
  public func at<T>(list : List<T>, index : Nat) : T {
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
  /// assert List.get(list, 0) == ?10;
  /// assert List.get(list, 2) == null;
  /// ```
  ///
  /// Runtime: `O(1)`
  ///
  /// Space: `O(1)`
  public func get<T>(list : List<T>, index : Nat) : ?T {
    // inlined version of locate
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
  /// Traps if `index` >= size, error message may not be descriptive. Indexing is zero-based.
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
    let i = Nat32.fromNat(index);
    let lz = Nat32.bitcountLeadingZero(i);
    let lz2 = lz >> 1;
    let (block, element) = if (lz & 1 == 0) {
      (list.blocks[Nat32.toNat(((i << lz2) >> 16) ^ (0x10000 >> lz2))], Nat32.toNat(i & (0xFFFF >> lz2)))
    } else {
      (list.blocks[Nat32.toNat(((i << lz2) >> 15) ^ (0x18000 >> lz2))], Nat32.toNat(i & (0x7FFF >> lz2)))
    };

    switch (block[element]) {
      case (?_) block[element] := ?value;
      case _ Prim.trap "List index out of bounds in put"
    }
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
    let array = toVarArray(list);

    VarArray.sortInPlace(array, compare);

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
          case (?_) db[j] := ?array[index];
          case _ return
        };
        index += 1;
        j += 1
      };
      i += 1
    }
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
    // inlined version of findIndex
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
          case (?x) if (equal(x, element)) return ?indexByBlockElement(i, j);
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
    // inlined version of findLastIndex
    let blocks = list.blocks;
    let blockIndex = list.blockIndex;
    let elementIndex = list.elementIndex;

    var i = blockIndex;
    if (elementIndex == 0) i -= 1;

    while (i > 0) {
      let db = blocks[i];
      let sz = db.size();
      var j = if (i == blockIndex) elementIndex else sz;
      while (j > 0) {
        j -= 1;
        switch (db[j]) {
          case (?x) if (equal(x, element)) return ?indexByBlockElement(i, j);
          case null Prim.trap INTERNAL_ERROR
        }
      };
      i -= 1
    };

    null
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
    Option.map<Nat, T>(findIndex<T>(list, predicate), func(i) = at(list, i))
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
          case (?x) if (predicate(x)) return ?indexByBlockElement(i, j);
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
    let blocks = list.blocks;
    let blockIndex = list.blockIndex;
    let elementIndex = list.elementIndex;

    var i = blockIndex;
    if (elementIndex == 0) i -= 1;

    while (i > 0) {
      let db = blocks[i];
      let sz = db.size();
      var j = if (i == blockIndex) elementIndex else sz;
      while (j > 0) {
        j -= 1;
        switch (db[j]) {
          case (?x) if (predicate(x)) return ?indexByBlockElement(i, j);
          case null Prim.trap INTERNAL_ERROR
        }
      };
      i -= 1
    };

    null
  };

  /// Performs binary search on a sorted list to find the index of the `element`.
  /// Returns `#found(index)` if the element is found, or `#insertionIndex(index)` with the index
  /// where the element would be inserted according to the ordering if not found.
  ///
  /// If there are multiple equal elements, no guarantee is made about which index is returned.
  /// The list must be sorted in ascending order according to the `compare` function.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Nat "mo:core/Nat";
  ///
  /// let list = List.fromArray<Nat>([1, 3, 5, 7, 9, 11]);
  /// assert List.binarySearch<Nat>(list, Nat.compare, 5) == #found(2);
  /// assert List.binarySearch<Nat>(list, Nat.compare, 6) == #insertionIndex(3);
  /// ```
  ///
  /// Runtime: `O(log(size))`
  ///
  /// Space: `O(1)`
  ///
  /// *Runtime and space assumes that `compare` runs in `O(1)` time and space.
  public func binarySearch<T>(list : List<T>, compare : (T, T) -> Order.Order, element : T) : {
    #found : Nat;
    #insertionIndex : Nat
  } {
    // We call all data blocks of the same capacity an "epoch". We number the epochs 0,1,2,...
    // A data block is in epoch e iff the data block has capacity 2 ** e.
    // Each epoch starting with epoch 1 spans exactly two super blocks.
    // Super block s falls in epoch ceil(s/2).
    // Each epoch except e=0 contains 3 * 2 ** (e - 1) data blocks

    let blocks = list.blocks;
    let b = list.blockIndex - (if (list.elementIndex == 0) 1 else 0) : Nat;

    // block index x such that blocks[x][0] <= element
    let lessOrEqual = do {
      // epoch of the last data block
      let epoch = 32 - Nat32.bitcountLeadingZero(Nat32.fromNat(b) / 3);
      // initially block index is the first in the epoch
      var lessOrEqual = Nat32.toNat((1 << epoch) / 2);

      // lessOrEqual * 3 is always the first data block in an epoch
      // while the first element of the first data block in an epoch is actually grater then element go to the previous epoch
      // as the last epoch is half of the array we each iteration of the search divides the interval in four
      while (lessOrEqual != 0 and compare(Option.unwrap(blocks[lessOrEqual * 3][0]), element) == #greater) {
        lessOrEqual /= 2
      };

      lessOrEqual * 3
    };

    // Linear search in e=0, there are just two elements
    if (lessOrEqual == 0) {
      let to = Nat.min(size(list), 2);
      for (i in Nat.range(0, to)) {
        let x = at(list, i);
        switch (compare(x, element)) {
          case (#less) {};
          case (#equal) return #found(i);
          case (#greater) return #insertionIndex(i)
        }
      };
      return #insertionIndex(to)
    };

    // binary search the blockIndex in [left, right)
    let blockIndex = do {
      // guarateed less or equal to element
      var left = lessOrEqual;
      // right is either outside of the array or greater than element
      var right = Nat.min(b + 1, lessOrEqual * 2);
      while (right - left : Nat > 1) {
        let mid = (left + right) / 2;
        switch (compare(Option.unwrap(blocks[mid][0]), element)) {
          case (#less) left := mid;
          case (#greater) right := mid;
          case (#equal) return #found(indexByBlockElement(mid, 0))
        }
      };
      left
    };

    // binary search the elementIndex
    let elementIndex = do {
      let block = blocks[blockIndex];
      var left = 0;
      var right = if (blockIndex == list.blockIndex) list.elementIndex else block.size();
      while (left != right) {
        let mid = (left + right) / 2;
        switch (compare(Option.unwrap(block[mid]), element)) {
          case (#less) left := mid + 1;
          case (#greater) right := mid;
          case (#equal) return #found(indexByBlockElement(blockIndex, mid))
        }
      };
      left
    };

    #insertionIndex(indexByBlockElement(blockIndex, elementIndex))
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
  public func any<T>(list : List<T>, predicate : T -> Bool) : Bool = findIndex<T>(list, predicate) != null;

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
    if (elementIndex != 0) {
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
    if (elementIndex != 0) {
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
    if (list.blockIndex == 1) null else list.blocks[1][0]
  };

  /// Returns the last element of `list`, or `null` if the list is empty.
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
    var index = 0;

    let blocks = list.blocks;
    let blockIndex = list.blockIndex;
    let elementIndex = list.elementIndex;

    var i = blockIndex;
    if (elementIndex == 0) i -= 1;

    while (i > 0) {
      let db = blocks[i];
      let sz = db.size();
      var j = if (i == blockIndex) elementIndex else sz;
      while (j > 0) {
        j -= 1;
        switch (db[j]) {
          case (?x) f(index, x);
          case null Prim.trap INTERNAL_ERROR
        };
        index += 1
      };
      i -= 1
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
    let blocks = list.blocks;
    let blockIndex = list.blockIndex;
    let elementIndex = list.elementIndex;

    var i = blockIndex;
    if (elementIndex == 0) i -= 1;

    while (i > 0) {
      let db = blocks[i];
      let sz = db.size();
      var j = if (i == blockIndex) elementIndex else sz;
      while (j > 0) {
        j -= 1;
        switch (db[j]) {
          case (?x) f(x);
          case null Prim.trap INTERNAL_ERROR
        }
      };
      i -= 1
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

    var i = 2;
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

    var i = 2;
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
    label l while (i < blockCount) {
      let db1 = blocks1[i];
      let db2 = blocks2[i];
      let sz = Nat.min(db1.size(), db2.size());
      if (sz == 0) break l;

      var j = 0;
      while (j < sz) {
        switch (db1[j], db2[j]) {
          case (?x, ?y) switch (compare(x, y)) {
            case (#less) return #less;
            case (#greater) return #greater;
            case _ {}
          };
          case (_, _) break l
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
    var text = switch (first(list)) {
      case (?x) f(x);
      case null ""
    };

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var i = 2;
    label l while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) break l;

      var j = 0;
      while (j < sz) {
        switch (db[j]) {
          case (?x) text #= ", " # f(x);
          case null break l
        };
        j += 1
      };
      i += 1
    };

    "List[" # text # "]"
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

    let blocks = list.blocks;
    let blockIndex = list.blockIndex;
    let elementIndex = list.elementIndex;

    var i = blockIndex;
    if (elementIndex == 0) i -= 1;

    while (i > 0) {
      let db = blocks[i];
      let sz = db.size();
      var j = if (i == blockIndex) elementIndex else sz;
      while (j > 0) {
        j -= 1;
        switch (db[j]) {
          case (?x) accumulation := combine(x, accumulation);
          case null Prim.trap INTERNAL_ERROR
        }
      };
      i -= 1
    };

    accumulation
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

    let (finalBlock, finalElement) = locate(vsize / 2);

    let blocks = list.blocks;

    var blockIndexBack = list.blockIndex;
    var elementIndexBack = list.elementIndex;
    var dbBack : [var ?T] = if (blockIndexBack < list.blocks.size()) {
      list.blocks[blockIndexBack]
    } else { [var] };

    var i = 1;
    var index = 0;
    while (i <= finalBlock) {
      let db = blocks[i];
      let sz = if (i == finalBlock) finalElement else db.size();

      var j = 0;
      while (j < sz) {
        if (elementIndexBack == 0) {
          blockIndexBack -= 1;
          dbBack := list.blocks[blockIndexBack];
          elementIndexBack := dbBack.size() - 1
        } else {
          elementIndexBack -= 1
        };

        let temp = db[j];
        db[j] := dbBack[elementIndexBack];
        dbBack[elementIndexBack] := temp;

        j += 1;
        index += 1
      };
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

    let blocks = list.blocks;
    let blockCount = blocks.size();

    var blockIndexBack = rlist.blockIndex;
    var elementIndexBack = rlist.elementIndex;
    var dbBack : [var ?T] = if (blockIndexBack < rlist.blocks.size()) {
      rlist.blocks[blockIndexBack]
    } else { [var] };

    var i = 1;
    while (i < blockCount) {
      let db = blocks[i];
      let sz = db.size();
      if (sz == 0) return rlist;

      var j = 0;
      while (j < sz) {
        if (elementIndexBack == 0) {
          blockIndexBack -= 1;
          if (blockIndexBack == 0) return rlist;
          dbBack := rlist.blocks[blockIndexBack];
          elementIndexBack := dbBack.size() - 1
        } else {
          elementIndexBack -= 1
        };

        dbBack[elementIndexBack] := db[j];
        j += 1
      };
      i += 1
    };
    rlist
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
    list.blockIndex == 1
  };

}
