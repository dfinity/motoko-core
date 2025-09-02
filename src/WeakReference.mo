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
  type WeakReference<T> = {
    ref : weak T
  };

  public func allocateWeakRef<T>(obj : T) : WeakReference<T> {
    return { ref = Prim.allocWeakRef<T>(obj) }
  };

  public func deref<T>(weakRef : WeakReference<T>) : ?T {
    return Prim.weakGet<T>(weakRef.ref)
  };

  public func isLive(weakRef : weak Any) : Bool {
    return Prim.isLive(weakRef)
  };

}
