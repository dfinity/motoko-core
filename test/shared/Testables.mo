import T "mo:matchers/Testable";
import Order "../../src/Order";

module {
  public class Int8Testable(number : Int8) : T.TestableItem<Int8> {
    public let item = number;
    public func display(number : Int8) : Text {
      debug_show (number)
    };
    public let equals = func(x : Int8, y : Int8) : Bool {
      x == y
    }
  };

  public class Int16Testable(number : Int16) : T.TestableItem<Int16> {
    public let item = number;
    public func display(number : Int16) : Text {
      debug_show (number)
    };
    public let equals = func(x : Int16, y : Int16) : Bool {
      x == y
    }
  };

  public class Int32Testable(number : Int32) : T.TestableItem<Int32> {
    public let item = number;
    public func display(number : Int32) : Text {
      debug_show (number)
    };
    public let equals = func(x : Int32, y : Int32) : Bool {
      x == y
    }
  };

  public class Int64Testable(number : Int64) : T.TestableItem<Int64> {
    public let item = number;
    public func display(number : Int64) : Text {
      debug_show (number)
    };
    public let equals = func(x : Int64, y : Int64) : Bool {
      x == y
    }
  };

  public class Nat8Testable(number : Nat8) : T.TestableItem<Nat8> {
    public let item = number;
    public func display(number : Nat8) : Text {
      debug_show (number)
    };
    public let equals = func(x : Nat8, y : Nat8) : Bool {
      x == y
    }
  };

  public class Nat16Testable(number : Nat16) : T.TestableItem<Nat16> {
    public let item = number;
    public func display(number : Nat16) : Text {
      debug_show (number)
    };
    public let equals = func(x : Nat16, y : Nat16) : Bool {
      x == y
    }
  };

  public class Nat32Testable(number : Nat32) : T.TestableItem<Nat32> {
    public let item = number;
    public func display(number : Nat32) : Text {
      debug_show (number)
    };
    public let equals = func(x : Nat32, y : Nat32) : Bool {
      x == y
    }
  };

  public class Nat64Testable(number : Nat64) : T.TestableItem<Nat64> {
    public let item = number;
    public func display(number : Nat64) : Text {
      debug_show (number)
    };
    public let equals = func(x : Nat64, y : Nat64) : Bool {
      x == y
    }
  };

  public class OrderTestable(value : Order.Order) : T.TestableItem<Order.Order> {
    public let item = value;
    public func display(value : Order.Order) : Text {
      debug_show (value)
    };
    public let equals = func(x : Order.Order, y : Order.Order) : Bool {
      x == y
    }
  }
}
