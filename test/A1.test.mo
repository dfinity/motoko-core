import Array "mo:core/Array";

actor {
  func update0(members : [(Nat, Nat)]) {
    let _ = members.map(
      func(memberRole) {
        memberRole
      }
    )
  };
  func update1(members : [(Nat, Nat)]) {
    let _ = members.map<(Nat, Nat), (Nat, Nat)>(
      func(memberRole : (Nat, Nat)) : (Nat, Nat) {
        memberRole
      }
    )
  };
  func update2(members : [(Nat, Nat)]) {
    let _ = members.map<(Nat, Nat), (Nat, Nat)>(
      func(memberRole) {
        memberRole
      }
    )
  };
  func update3(members : [(Nat, Nat)]) {
    // TODO: Does not type check
    let _ = members.map(
      func(memberRole : (Nat, Nat)) : (Nat, Nat) {
        memberRole
      }
    )
  }
}
