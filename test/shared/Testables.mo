import T "mo:matchers/Testable";

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
}