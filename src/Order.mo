/// Utilities for `Order` (comparison between two values).

import Types "Types";

module {

  /// A type to represent an order.
  public type Order = Types.Order;

  /// Check if an order is #less.
  public func isLess(self : Order) : Bool {
    switch self {
      case (#less) { true };
      case _ { false }
    }
  };

  /// Check if an order is #equal.
  public func isEqual(self : Order) : Bool {
    switch self {
      case (#equal) { true };
      case _ { false }
    }
  };

  /// Check if an order is #greater.
  public func isGreater(self : Order) : Bool {
    switch self {
      case (#greater) { true };
      case _ { false }
    }
  };

  /// Returns true if only if  `order1` and `order2` are the same.
  public func equal(self : Order, other : Order) : Bool {
    switch (self, other) {
      case (#less, #less) { true };
      case (#equal, #equal) { true };
      case (#greater, #greater) { true };
      case _ { false }
    }
  };

  /// Returns an iterator that yields all possible `Order` values:
  /// `#less`, `#equal`, `#greater`.
  public func allValues() : Types.Iter<Order> {
    var nextState : ?Order = ?#less;
    {
      next = func() : ?Order {
        let state = nextState;
        switch state {
          case (?#less) { nextState := ?#equal };
          case (?#equal) { nextState := ?#greater };
          case (?#greater) { nextState := null };
          case (null) {}
        };
        state
      }
    }
  }

}
