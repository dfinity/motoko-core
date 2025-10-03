/// Error values and inspection.
///
/// The `Error` type is the argument to `throw`, parameter of `catch`.
/// The `Error` type is opaque.

import Prim "mo:⛔";

module {

  /// Error value resulting from  `async` computations
  public type Error = Prim.Types.Error;

  /// Error code to classify different kinds of user and system errors:
  /// ```motoko
  /// type ErrorCode = {
  ///   // Fatal error.
  ///   #system_fatal;
  ///   // Transient error.
  ///   #system_transient;
  ///   // Destination invalid.
  ///   #destination_invalid;
  ///   // Canister error (e.g., trap, no response).
  ///   #canister_error;
  ///   // Explicit reject by canister code.
  ///   #canister_reject;
  ///   // Response unknown; system stopped waiting for it (e.g., timed out, or system under high load).
  ///   #system_unknown;
  ///   // Future error code (with unrecognized numeric code).
  ///   #future : Nat32;
  ///   // Error issuing inter-canister call
  ///   // (indicating destination queue full or freezing threshold crossed).
  ///   #call_error : { err_code :  Nat32 }
  /// };
  /// ```
  public type ErrorCode = Prim.ErrorCode;

  /// Create an error from the message with the code `#canister_reject`.
  ///
  /// Example:
  /// ```motoko
  /// import Error "mo:core/Error";
  ///
  /// Error.reject("Example error") // can be used as throw argument
  /// ```
  public let reject : (message : Text) -> Error = Prim.error;

  /// Returns the code of an error.
  ///
  /// Example:
  /// ```motoko
  /// import Error "mo:core/Error";
  ///
  /// let error = Error.reject("Example error");
  /// Error.code(error) // #canister_reject
  /// ```
  public let code : (error : Error) -> ErrorCode = Prim.errorCode;

  /// Returns the message of an error.
  ///
  /// Example:
  /// ```motoko
  /// import Error "mo:core/Error";
  ///
  /// let error = Error.reject("Example error");
  /// Error.message(error) // "Example error"
  /// ```
  public let message : (error : Error) -> Text = Prim.errorMessage;

  /// Checks if the error is a clean reject.
  /// A clean reject means that there must be no state changes on the callee side.
  //  See `isRetryPossible` for usage example.
  public func isCleanReject(error : Error) : Bool = switch (code error) {
    case (#system_fatal or #system_transient or #destination_invalid or #call_error _) true;
    case _ false
  };

  /// Determines if the failed call can be retried immediately within the update method
  /// that's handling the error, as opposed to relying on a background timer or heartbeat.
  ///
  /// A return value of `true` indicates that an immediate retry *might* succeed, i.e., not result in another error.
  /// However, the caller is responsible for ensuring that retries are safe in their specific context.
  /// For idempotent methods, immediate retries are generally safe. For non-idempotent ones,
  /// checking `isCleanReject` before retrying is recommended.
  ///
  /// Example:
  /// ```motoko
  /// import Error "mo:core/Error";
  /// import Debug "mo:core/Debug";
  ///
  /// persistent actor {
  ///   type CallableActor = actor {
  ///     call : () -> async ()
  ///   };
  ///
  ///   public func example(callableActor : CallableActor) {
  ///     try {
  ///       await (with timeout = 3) callableActor.call();
  ///     } catch e {
  ///       Debug.print(Error.message e);
  ///
  ///       // Check if an immediate retry might succeed.
  ///       if (Error.isRetryPossible e) {
  ///         Debug.print("Immediate retry may succeed. Consider retrying now.");
  ///       }
  ///
  ///       // Check if the previous call is clean (did not mutate state).
  ///       if (Error.isClean e) {
  ///         Debug.print("Previous call did not mutate state: safe to retry.");
  ///       } else {
  ///         Debug.print("Previous call may have mutated state: retry with caution.");
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  public func isRetryPossible(error : Error) : Bool = switch (code error) {
    case (#system_transient or #system_unknown) true;
    case _ false
  };

}
