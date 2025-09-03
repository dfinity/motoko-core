import WeakReference "../src/WeakReference";
import { suite; test; expect } "mo:test"

test(
  "allocateWeakRef",
  func() {
    let arr = [123, 456, 789];
    let weakRef = WeakReference.allocate(arr);
    expect.bool(WeakReference.get(weakRef) == ?arr).equal(true)
  }
);

test(
  "deref",
  func() {
    let arr = [123, 456, 789];
    let weakRef = WeakReference.allocate(arr);
    switch (WeakReference.get(weakRef)) {
      case (?myArray) {
        let value = myArray[1];
        expect.nat(value).equal(456)
      };
      case null { expect.bool(false).equal(true) }
    }
  }
);

test(
  "isLive",
  func() {
    let arr = [123, 456, 789];
    let weakRef = WeakReference.allocate(arr);
    expect.bool(WeakReference.isLive(weakRef)).equal(true)
  }
)
