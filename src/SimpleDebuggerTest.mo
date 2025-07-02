/// Setup motoko debugger:
/// - git clone https://github.com/scalebit/ic-sdk to ~/ic-sdk
/// - cd ~/ic-sdk && cargo build
///
/// Run:
/// moc $(mops sources) -o MoDe.wasm -g src/SimpleDebuggerTest.mo && ~/ic-sdk/target/debug/dfx debug MoDe.wasm
///
/// Commands:
/// bp set -n main
/// run
/// bt
/// list
/// thread step-in  Note: wrong line?
/// thread step-over  Note: correct line!
/// thread step-over
/// thread step-out
/// local read  Output: 1  . list      : "HeapAddress: 2133695, tagged: Object, I32"
import List "List";
import Debug "Debug";

func main() {

  let list = List.fromArray<Nat>([1, 2, 3]);
  List.addAll(list, [4, 5, 6].vals());
  Debug.print(debug_show (List.toArray(list)))
};

main()
