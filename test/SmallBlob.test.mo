/// Setup motoko debugger:
/// - git clone https://github.com/scalebit/ic-sdk to ~/ic-sdk
/// - cd ~/ic-sdk && cargo build
///
/// Run:
/// moc $(mops sources) -o MoDe.wasm -g test/SmallBlob.test.mo && ~/ic-sdk/target/debug/dfx debug MoDe.wasm
///
/// Commands:
/// bp set -n breakpoint
/// run
/// bt
/// list  Output: File not found: "<moc-asset>/prelude"
/// thread step-in  Note: output seems to be wrong, points to a wrong line
/// bt
/// thread step-out
/// list  Note: no output?
/// bt
/// thread step-out  Output: File not found: "<moc-asset>/prelude"
/// thread step-over Output: File not found: "./internals"
import Blob "../src/Blob";
import { suite; test; expect } "mo:test";
import Debug "../src/Debug";

// placeholder for debugger breakpoint
func breakpoint() {
  Debug.print("breakpoint"); // must be non-empty otherwise the debugger seems to skip it
};

suite(
  "basic operations",
  func() {
    test(
      "empty creates an empty blob",
      func() {
        let emptyBlob = Blob.empty();
        breakpoint();
        expect.nat(emptyBlob.size()).equal(0)
      }
    );

    test(
      "isEmpty identifies empty blobs",
      func() {
        breakpoint();
        expect.bool(Blob.isEmpty(Blob.empty())).equal(true);
        expect.bool(Blob.isEmpty("\FF\00" : Blob)).equal(false)
      }
    );

    test(
      "size returns correct byte count",
      func() {
        breakpoint();
        expect.nat(Blob.size("\FF\00\AA" : Blob)).equal(3);
        expect.nat(Blob.size(Blob.empty())).equal(0)
      }
    )
  }
)
