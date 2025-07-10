/// Setup motoko debugger:
/// - git clone https://github.com/scalebit/ic-sdk to ~/ic-sdk
/// - cd ~/ic-sdk && cargo build
///
/// Run:
/// moc $(mops sources) -o MoDe.wasm -g src/SimpleDebuggerTestWithBase.mo && ~/ic-sdk/target/debug/dfx debug MoDe.wasm
///
/// Commands:
/// bp set -n main
/// run
/// bt
/// list  Output: File not found: "./internals"
/// thread step-in  Note: wrong line?
/// thread step-over  Output: File not found: "./internals"
/// thread step-over  Output: File not found: "./internals"
/// list  Output: File not found: "./internals"
import List "List";
import Debug "Debug";
import BaseArray "mo:base/Array";

func main() {
  let baseArray = BaseArray.tabulate<Nat>(3, func i = i);
  let list = List.fromArray<Nat>(baseArray);
  List.addAll(list, [4, 5, 6].vals());
  Debug.print(debug_show (List.toArray(list)))
};

main()
