/// Utility functions on 32-bit signed integers.
///
/// Note that most operations are available as built-in operators (e.g. `1 + 1`).
///
/// Import from the core package to use this module.
/// ```motoko name=import
/// import Int32 "mo:core/Int32";
/// ```
import Int "Int";
import Iter "Iter";
import Prim "mo:⛔";
import Order "Order";

module {

  /// 32-bit signed integers.
  public type Int32 = Prim.Types.Int32;

  /// Minimum 32-bit integer value, `-2 ** 31`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.minValue == -2_147_483_648;
  /// ```
  public let minValue : Int32 = -2_147_483_648;

  /// Maximum 32-bit integer value, `+2 ** 31 - 1`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.maxValue == +2_147_483_647;
  /// ```
  public let maxValue : Int32 = 2_147_483_647;

  /// Converts a 32-bit signed integer to a signed integer with infinite precision.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.toInt(123_456) == (123_456 : Int);
  /// ```
  public func toInt(self : Int32) : Int = Prim.int32ToInt(self);

  /// Converts a signed integer with infinite precision to a 32-bit signed integer.
  ///
  /// Traps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.fromInt(123_456) == (+123_456 : Int32);
  /// ```
  public let fromInt : Int -> Int32 = Prim.intToInt32;

  /// Converts a signed integer with infinite precision to a 32-bit signed integer.
  ///
  /// Wraps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.fromIntWrap(-123_456) == (-123_456 : Int);
  /// ```
  public let fromIntWrap : Int -> Int32 = Prim.intToInt32Wrap;

  /// Converts a 16-bit signed integer to a 32-bit signed integer.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.fromInt16(-123) == (-123 : Int32);
  /// ```
  public let fromInt16 : Int16 -> Int32 = Prim.int16ToInt32;

  /// Converts a 32-bit signed integer to a 16-bit signed integer.
  ///
  /// Traps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.toInt16(-123) == (-123 : Int16);
  /// ```
  public func toInt16(self : Int32) : Int16 = Prim.int32ToInt16(self);

  /// Converts a 64-bit signed integer to a 32-bit signed integer.
  ///
  /// Traps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.fromInt64(-123_456) == (-123_456 : Int32);
  /// ```
  public let fromInt64 : Int64 -> Int32 = Prim.int64ToInt32;

  /// Converts a 32-bit signed integer to a 64-bit signed integer.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.toInt64(-123_456) == (-123_456 : Int64);
  /// ```
  public func toInt64(self : Int32) : Int64 = Prim.int32ToInt64(self);

  /// Converts an unsigned 32-bit integer to a signed 32-bit integer.
  ///
  /// Wraps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.fromNat32(123_456) == (+123_456 : Int32);
  /// ```
  public let fromNat32 : Nat32 -> Int32 = Prim.nat32ToInt32;

  /// Converts a signed 32-bit integer to an unsigned 32-bit integer.
  ///
  /// Wraps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.toNat32(-1) == (4_294_967_295 : Nat32); // underflow
  /// ```
  public func toNat32(self : Int32) : Nat32 = Prim.int32ToNat32(self);

  /// Returns the Text representation of `x`. Textual representation _do not_
  /// contain underscores to represent commas.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.toText(-123456) == "-123456";
  /// ```
  public func toText(self : Int32) : Text {
    Int.toText(toInt(self))
  };

  /// Returns the absolute value of `x`.
  ///
  /// Traps when `x == -2 ** 31` (the minimum `Int32` value).
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.abs(-123456) == +123_456;
  /// ```
  public func abs(self : Int32) : Int32 {
    fromInt(Int.abs(toInt(self)))
  };

  /// Returns the minimum of `x` and `y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.min(+2, -3) == -3;
  /// ```
  public func min(self : Int32, other : Int32) : Int32 {
    if (self < other) { self } else { other }
  };

  /// Returns the maximum of `x` and `y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.max(+2, -3) == +2;
  /// ```
  public func max(self : Int32, other : Int32) : Int32 {
    if (self < other) { other } else { self }
  };

  /// Equality function for Int32 types.
  /// This is equivalent to `x == y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.equal(-1, -1);
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `==` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `==`
  /// as a function value at the moment.
  ///
  /// Example:
  /// ```motoko include=import
  /// let a : Int32 = -123;
  /// let b : Int32 = 123;
  /// assert not Int32.equal(a, b);
  /// ```
  public func equal(self : Int32, other : Int32) : Bool { self == other };

  /// Inequality function for Int32 types.
  /// This is equivalent to `x != y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.notEqual(-1, -2);
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `!=` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `!=`
  /// as a function value at the moment.
  public func notEqual(self : Int32, other : Int32) : Bool { self != other };

  /// "Less than" function for Int32 types.
  /// This is equivalent to `x < y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.less(-2, 1);
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `<` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `<`
  /// as a function value at the moment.
  public func less(self : Int32, other : Int32) : Bool { self < other };

  /// "Less than or equal" function for Int32 types.
  /// This is equivalent to `x <= y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.lessOrEqual(-2, -2);
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `<=` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `<=`
  /// as a function value at the moment.
  public func lessOrEqual(self : Int32, other : Int32) : Bool { self <= other };

  /// "Greater than" function for Int32 types.
  /// This is equivalent to `x > y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.greater(-2, -3);
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `>` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `>`
  /// as a function value at the moment.
  public func greater(self : Int32, other : Int32) : Bool { self > other };

  /// "Greater than or equal" function for Int32 types.
  /// This is equivalent to `x >= y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.greaterOrEqual(-2, -2);
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `>=` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `>=`
  /// as a function value at the moment.
  public func greaterOrEqual(self : Int32, other : Int32) : Bool {
    self >= other
  };

  /// General-purpose comparison function for `Int32`. Returns the `Order` (
  /// either `#less`, `#equal`, or `#greater`) of comparing `x` with `y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.compare(-3, 2) == #less;
  /// ```
  ///
  /// This function can be used as value for a high order function, such as a sort function.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Array "mo:core/Array";
  /// assert Array.sort([1, -2, -3] : [Int32], Int32.compare) == [-3, -2, 1];
  /// ```
  public func compare(self : Int32, other : Int32) : Order.Order {
    if (self < other) { #less } else if (self == other) { #equal } else {
      #greater
    }
  };

  /// Returns the negation of `x`, `-x`.
  ///
  /// Traps on overflow, i.e. for `neg(-2 ** 31)`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.neg(123) == -123;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `-` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `-`
  /// as a function value at the moment.
  public func neg(self : Int32) : Int32 { -self };

  /// Returns the sum of `x` and `y`, `x + y`.
  ///
  /// Traps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.add(100, 23) == +123;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `+` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `+`
  /// as a function value at the moment.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Array "mo:core/Array";
  /// assert Array.foldLeft<Int32, Int32>([1, -2, -3], 0, Int32.add) == -4;
  /// ```
  public func add(self : Int32, other : Int32) : Int32 { self + other };

  /// Returns the difference of `x` and `y`, `x - y`.
  ///
  /// Traps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.sub(1234, 123) == +1_111;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `-` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `-`
  /// as a function value at the moment.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Array "mo:core/Array";
  /// assert Array.foldLeft<Int32, Int32>([1, -2, -3], 0, Int32.sub) == 4;
  /// ```
  public func sub(self : Int32, other : Int32) : Int32 { self - other };

  /// Returns the product of `x` and `y`, `x * y`.
  ///
  /// Traps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.mul(123, 100) == +12_300;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `*` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `*`
  /// as a function value at the moment.
  ///
  /// Example:
  /// ```motoko include=import
  /// import Array "mo:core/Array";
  /// assert Array.foldLeft<Int32, Int32>([1, -2, -3], 1, Int32.mul) == 6;
  /// ```
  public func mul(self : Int32, other : Int32) : Int32 { self * other };

  /// Returns the signed integer division of `x` by `y`, `x / y`.
  /// Rounds the quotient towards zero, which is the same as truncating the decimal places of the quotient.
  ///
  /// Traps when `y` is zero.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.div(123, 10) == +12;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `/` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `/`
  /// as a function value at the moment.
  public func div(self : Int32, other : Int32) : Int32 { self / other };

  /// Returns the remainder of the signed integer division of `x` by `y`, `x % y`,
  /// which is defined as `x - x / y * y`.
  ///
  /// Traps when `y` is zero.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.rem(123, 10) == +3;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `%` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `%`
  /// as a function value at the moment.
  public func rem(self : Int32, other : Int32) : Int32 { self % other };

  /// Returns `x` to the power of `y`, `x ** y`.
  ///
  /// Traps on overflow/underflow and when `y < 0 or y >= 32`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.pow(2, 10) == +1_024;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `**` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `**`
  /// as a function value at the moment.
  public func pow(self : Int32, other : Int32) : Int32 { self ** other };

  /// Returns the bitwise negation of `x`, `^x`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitnot(-256 /* 0xffff_ff00 */) == +255 // 0xff;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `^` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `^`
  /// as a function value at the moment.
  public func bitnot(self : Int32) : Int32 { ^self };

  /// Returns the bitwise "and" of `x` and `y`, `x & y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitand(0xffff, 0x00f0) == +240 // 0xf0;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `&` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `&`
  /// as a function value at the moment.
  public func bitand(self : Int32, other : Int32) : Int32 { self & other };

  /// Returns the bitwise "or" of `x` and `y`, `x | y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitor(0xffff, 0x00f0) == +65_535 // 0xffff;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `|` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `|`
  /// as a function value at the moment.
  public func bitor(self : Int32, other : Int32) : Int32 { self | other };

  /// Returns the bitwise "exclusive or" of `x` and `y`, `x ^ y`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitxor(0xffff, 0x00f0) == +65_295 // 0xff0f;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `^` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `^`
  /// as a function value at the moment.
  public func bitxor(self : Int32, other : Int32) : Int32 { self ^ other };

  /// Returns the bitwise left shift of `x` by `y`, `x << y`.
  /// The right bits of the shift filled with zeros.
  /// Left-overflowing bits, including the sign bit, are discarded.
  ///
  /// For `y >= 32`, the semantics is the same as for `bitshiftLeft(x, y % 32)`.
  /// For `y < 0`,  the semantics is the same as for `bitshiftLeft(x, y + y % 32)`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitshiftLeft(1, 8) == +256 // 0x100 equivalent to `2 ** 8`.;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `<<` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `<<`
  /// as a function value at the moment.
  public func bitshiftLeft(self : Int32, other : Int32) : Int32 {
    self << other
  };

  /// Returns the signed bitwise right shift of `x` by `y`, `x >> y`.
  /// The sign bit is retained and the left side is filled with the sign bit.
  /// Right-underflowing bits are discarded, i.e. not rotated to the left side.
  ///
  /// For `y >= 32`, the semantics is the same as for `bitshiftRight(x, y % 32)`.
  /// For `y < 0`,  the semantics is the same as for `bitshiftRight (x, y + y % 32)`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitshiftRight(1024, 8) == +4 // equivalent to `1024 / (2 ** 8)`;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `>>` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `>>`
  /// as a function value at the moment.
  public func bitshiftRight(self : Int32, other : Int32) : Int32 {
    self >> other
  };

  /// Returns the bitwise left rotatation of `x` by `y`, `x <<> y`.
  /// Each left-overflowing bit is inserted again on the right side.
  /// The sign bit is rotated like other bits, i.e. the rotation interprets the number as unsigned.
  ///
  /// Changes the direction of rotation for negative `y`.
  /// For `y >= 32`, the semantics is the same as for `bitrotLeft(x, y % 32)`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitrotLeft(0x2000_0001, 4) == +18 // 0x12.;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `<<>` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `<<>`
  /// as a function value at the moment.
  public func bitrotLeft(self : Int32, other : Int32) : Int32 { self <<> other };

  /// Returns the bitwise right rotation of `x` by `y`, `x <>> y`.
  /// Each right-underflowing bit is inserted again on the right side.
  /// The sign bit is rotated like other bits, i.e. the rotation interprets the number as unsigned.
  ///
  /// Changes the direction of rotation for negative `y`.
  /// For `y >= 32`, the semantics is the same as for `bitrotRight(x, y % 32)`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitrotRight(0x0002_0001, 8) == +16_777_728 // 0x0100_0200.;
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `<>>` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `<>>`
  /// as a function value at the moment.
  public func bitrotRight(self : Int32, other : Int32) : Int32 {
    self <>> other
  };

  /// Returns the value of bit `p` in `x`, `x & 2**p == 2**p`.
  /// If `p >= 32`, the semantics is the same as for `bittest(x, p % 32)`.
  /// This is equivalent to checking if the `p`-th bit is set in `x`, using 0 indexing.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bittest(128, 7);
  /// ```
  public func bittest(self : Int32, p : Nat) : Bool {
    Prim.btstInt32(self, Prim.intToInt32(p))
  };

  /// Returns the value of setting bit `p` in `x` to `1`.
  /// If `p >= 32`, the semantics is the same as for `bitset(x, p % 32)`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitset(0, 7) == +128;
  /// ```
  public func bitset(self : Int32, p : Nat) : Int32 {
    self | (1 << Prim.intToInt32(p))
  };

  /// Returns the value of clearing bit `p` in `x` to `0`.
  /// If `p >= 32`, the semantics is the same as for `bitclear(x, p % 32)`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitclear(-1, 7) == -129;
  /// ```
  public func bitclear(self : Int32, p : Nat) : Int32 {
    self & ^(1 << Prim.intToInt32(p))
  };

  /// Returns the value of flipping bit `p` in `x`.
  /// If `p >= 32`, the semantics is the same as for `bitclear(x, p % 32)`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitflip(255, 7) == +127;
  /// ```
  public func bitflip(self : Int32, p : Nat) : Int32 {
    self ^ (1 << Prim.intToInt32(p))
  };

  /// Returns the count of non-zero bits in `x`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitcountNonZero(0xffff) == +16;
  /// ```
  public func bitcountNonZero(self : Int32) : Int32 = Prim.popcntInt32(self);

  /// Returns the count of leading zero bits in `x`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitcountLeadingZero(0x8000) == +16;
  /// ```
  public func bitcountLeadingZero(self : Int32) : Int32 = Prim.clzInt32(self);

  /// Returns the count of trailing zero bits in `x`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.bitcountTrailingZero(0x0201_0000) == +16;
  /// ```
  public func bitcountTrailingZero(self : Int32) : Int32 = Prim.ctzInt32(self);

  /// Returns the upper (i.e. most significant), lower (least significant)
  /// and in-between bytes of `x`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.explode 0x66885511 == (102, 136, 85, 17);
  /// ```
  public func explode(self : Int32) : (msb : Nat8, Nat8, Nat8, lsb : Nat8) = Prim.explodeInt32(self);

  /// Returns the sum of `x` and `y`, `x +% y`.
  ///
  /// Wraps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.addWrap(2 ** 30, 2 ** 30) == -2_147_483_648; // overflow
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `+%` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `+%`
  /// as a function value at the moment.
  public func addWrap(self : Int32, other : Int32) : Int32 { self +% other };

  /// Returns the difference of `x` and `y`, `x -% y`.
  ///
  /// Wraps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.subWrap(-2 ** 31, 1) == +2_147_483_647; // underflow
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `-%` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `-%`
  /// as a function value at the moment.
  public func subWrap(self : Int32, other : Int32) : Int32 { self -% other };

  /// Returns the product of `x` and `y`, `x *% y`. Wraps on overflow.
  ///
  /// Wraps on overflow/underflow.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.mulWrap(2 ** 16, 2 ** 16) == 0; // overflow
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `*%` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `*%`
  /// as a function value at the moment.
  public func mulWrap(self : Int32, other : Int32) : Int32 { self *% other };

  /// Returns `x` to the power of `y`, `x **% y`.
  ///
  /// Wraps on overflow/underflow.
  /// Traps if `y < 0 or y >= 32`.
  ///
  /// Example:
  /// ```motoko include=import
  /// assert Int32.powWrap(2, 31) == -2_147_483_648; // overflow
  /// ```
  ///
  /// Note: The reason why this function is defined in this library (in addition
  /// to the existing `**%` operator) is so that you can use it as a function
  /// value to pass to a higher order function. It is not possible to use `**%`
  /// as a function value at the moment.
  public func powWrap(self : Int32, other : Int32) : Int32 { self **% other };

  /// Returns an iterator over `Int32` values from the first to second argument with an exclusive upper bound.
  /// ```motoko include=import
  /// import Iter "mo:core/Iter";
  ///
  /// let iter = Int32.range(1, 4);
  /// assert iter.next() == ?1;
  /// assert iter.next() == ?2;
  /// assert iter.next() == ?3;
  /// assert iter.next() == null;
  /// ```
  ///
  /// If the first argument is greater than the second argument, the function returns an empty iterator.
  /// ```motoko include=import
  /// import Iter "mo:core/Iter";
  ///
  /// let iter = Int32.range(4, 1);
  /// assert iter.next() == null; // empty iterator
  /// ```
  public func range(self : Int32, toExclusive : Int32) : Iter.Iter<Int32> {
    if (self >= toExclusive) {
      Iter.empty()
    } else {
      object {
        var n = self;
        public func next() : ?Int32 {
          if (n == toExclusive) {
            null
          } else {
            let result = n;
            n += 1;
            ?result
          }
        }
      }
    }
  };

  /// Returns an iterator over `Int32` values from the first to second argument, inclusive.
  /// ```motoko include=import
  /// import Iter "mo:core/Iter";
  ///
  /// let iter = Int32.rangeInclusive(1, 3);
  /// assert iter.next() == ?1;
  /// assert iter.next() == ?2;
  /// assert iter.next() == ?3;
  /// assert iter.next() == null;
  /// ```
  ///
  /// If the first argument is greater than the second argument, the function returns an empty iterator.
  /// ```motoko include=import
  /// import Iter "mo:core/Iter";
  ///
  /// let iter = Int32.rangeInclusive(4, 1);
  /// assert iter.next() == null; // empty iterator
  /// ```
  public func rangeInclusive(self : Int32, to : Int32) : Iter.Iter<Int32> {
    if (self > to) {
      Iter.empty()
    } else {
      object {
        var n = self;
        var done = false;
        public func next() : ?Int32 {
          if (done) {
            null
          } else {
            let result = n;
            if (n == to) {
              done := true
            } else {
              n += 1
            };
            ?result
          }
        }
      }
    }
  };

  /// Returns an iterator over all Int32 values, from minValue to maxValue.
  /// ```motoko include=import
  /// import Iter "mo:core/Iter";
  ///
  /// let iter = Int32.allValues();
  /// assert iter.next() == ?-2_147_483_648;
  /// assert iter.next() == ?-2_147_483_647;
  /// assert iter.next() == ?-2_147_483_646;
  /// // ...
  /// ```
  public func allValues() : Iter.Iter<Int32> {
    rangeInclusive(minValue, maxValue)
  };

}
