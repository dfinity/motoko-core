/// Module that implements a weak reference to an object.
///
/// ATTENTION: This functionality does not work with classical persistence (`--legacy-persistence` moc flag).
///
/// Usage example:
/// Import from the core package to use this module.
/// ```motoko name=import
/// import WeakReference "mo:core/WeakReference";
/// ```

import Prim "mo:⛔"

module {
  public type WeakReference<T> = {
    ref : weak T
  };

  /// Allocate a new weak reference to the given object.
  ///
  /// @param obj The object to allocate a weak reference to.
  /// @return A new weak reference to the given object.
  /// ```motoko include=import
  /// let obj = { x = 1 };
  /// let weakRef = WeakReference.allocate(obj);
  /// ```
  public func allocate<T>(obj : T) : WeakReference<T> {
    return { ref = Prim.allocWeakRef<T>(obj) }
  };

  /// Get the value that the weak reference is pointing to.
  ///
  /// @param self The weak reference to get the value from.
  /// @return The value that the weak reference is pointing to, or `null` if the value has been collected by the garbage collector.
  /// ```motoko include=import
  /// let obj = { x = 1 };
  /// let weakRef = WeakReference.allocate(obj);
  /// let value = weakRef.get();
  /// ```
  public func get<T>(self : WeakReference<T>) : ?T {
    return Prim.weakGet<T>(self.ref)
  };

  /// Check if the weak reference is still alive.
  ///
  /// @param self The weak reference to check if it is alive.
  /// @return `true` if the weak reference is still alive, `false` otherwise.
  /// False means that the value has been collected by the garbage collector.
  /// ```motoko include=import
  /// let obj = { x = 1 };
  /// let weakRef = WeakReference.allocate(obj);
  /// let isLive = weakRef.isLive();
  /// assert isLive == true;
  /// ```
  public func isLive<T>(self : WeakReference<T>) : Bool {
    return Prim.isLive(self.ref)
  };

}
