import Order "mo:core/Order";

module M {
  module Order {
    public func compare(a : Int, b : Int) : Order.Order { #less }
  }
};

// module UnexpectedTokenEq {
//   func f1() {
//     let x = 1;
//     y = 3
//   };
//   func _f2() : { x : Int; y : Int } {
//     var x = 1;
//     y = 2
//   }
// };

module UnexpectedTokenLet {
  // func f1() {
  //   let obj = {
  //     let x = 1
  //   }
  // };
  // func f2() {
  //   let x = 1 let y = 2
  // };
};

// module RecordSyntax {
//   func _f0() : { x : Int; y : Int } { { x = 1; y = 2 } };
//   func _f1() : { x : Int; y : Int } {
//     x = 1;
//     y = 2
//   }
// }

module MultipleWrongTypes {
  module AccessControl {
    public type AccessControlState = ()
  };
  module Storage {
    public type State = ()
  };
  type OldActor = {
    accessControlState : AccessControl.State;
    storage : Storage.Storage
  }
}
