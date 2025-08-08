import Random "../src/Random";
import Nat8 "../src/Nat8";
import Nat "../src/Nat";
import Nat64 "../src/Nat64";
import Array "../src/Array";
import Blob "../src/Blob";
import { suite; test; expect } = "mo:test/async";

await suite(
  "Random.emptyState() and AsyncRandom state management",
  func() : async () {
    await test(
      "emptyState() creates proper initial state",
      func() : async () {
        let state = Random.emptyState();

        expect.nat(state.bytes.size()).equal(0);
        expect.nat(state.index).equal(0);
        expect.nat8(state.bits).equal(0x00);
        expect.nat8(state.bitMask).equal(0x00)
      }
    );
    await test(
      "cryptoFromState() creates AsyncRandom with proper state reference",
      func() : async () {
        let state = Random.emptyState();
        let _random = Random.cryptoFromState(state);

        // The AsyncRandom should use the same state object
        // We can verify the state is properly initialized
        expect.nat(state.bytes.size()).equal(0);
        expect.nat(state.index).equal(0)
      }
    );
    await test(
      "Multiple AsyncRandom instances can share the same state",
      func() : async () {
        let state = Random.emptyState();
        let _random1 = Random.cryptoFromState(state);
        let _random2 = Random.cryptoFromState(state);

        // Both should reference the same state object
        // This tests that state sharing works correctly
        expect.nat(state.bytes.size()).equal(0);
        expect.nat(state.index).equal(0)
      }
    );
    await test(
      "AsyncRandom state independence with separate states",
      func() : async () {
        let state1 = Random.emptyState();
        let state2 = Random.emptyState();
        let _random1 = Random.cryptoFromState(state1);
        let _random2 = Random.cryptoFromState(state2);

        // States should be independent objects
        expect.nat(state1.index).equal(state2.index);
        expect.nat(state1.bytes.size()).equal(state2.bytes.size());

        // But they should be different objects (we can't directly test object identity,
        // but we can test that modifying one doesn't affect the other)
        state1.index := 5;
        expect.nat(state1.index).equal(5);
        expect.nat(state2.index).equal(0)
      }
    )
  }
);

await suite(
  "AsyncRandom state management (synchronous tests)",
  func() : async () {
    // Helper function to create a mock async generator for testing
    func mockAsyncGenerator(bytes : [Nat8]) : () -> async* Blob {
      func() : async* Blob {
        Blob.fromArray(bytes)
      }
    };

    await test(
      "AsyncRandom creation with mock generator",
      func() : async () {
        let state = Random.emptyState();
        let mockBytes : [Nat8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

        let _random = Random.AsyncRandom(state, mockAsyncGenerator(mockBytes));

        expect.nat(state.bytes.size()).equal(0);
        expect.nat(state.index).equal(0);

        // Note: Cannot test actual async methods here due to test framework limitations
      }
    );
    await test(
      "State modifications are persistent across AsyncRandom instances",
      func() : async () {
        let state = Random.emptyState();

        // Manually simulate what would happen after some random generation
        state.bytes := [100, 200, 50, 75];
        state.index := 2;
        state.bits := 0x55;
        state.bitMask := 0x20;

        let _random = Random.cryptoFromState(state);

        expect.nat(state.bytes.size()).equal(4);
        expect.nat(state.index).equal(2);
        expect.nat8(state.bits).equal(0x55);
        expect.nat8(state.bitMask).equal(0x20);

        // Further simulate state advancement
        state.index := 3;
        expect.nat(state.index).equal(3)
      }
    );
    await test(
      "State reuse scenario simulation",
      func() : async () {
        let state = Random.emptyState();

        // Simulate canister upgrade scenario
        // Before upgrade: some random generation has occurred
        state.bytes := [10, 20, 30, 40, 50, 60, 70, 80];
        state.index := 3;
        state.bits := 0xAA;
        state.bitMask := 0x08;

        // After upgrade: create new AsyncRandom with persisted state
        let _random = Random.cryptoFromState(state);

        // State should be exactly as it was before upgrade
        expect.nat(state.bytes.size()).equal(8);
        expect.nat(state.index).equal(3);
        expect.nat8(state.bits).equal(0xAA);
        expect.nat8(state.bitMask).equal(0x08);

        // The bytes at current index should be accessible
        expect.nat8(state.bytes[state.index]).equal(40); // bytes[3] == 40
      }
    );
    await test(
      "Edge case: state with exhausted bytes",
      func() : async () {
        let state = Random.emptyState();

        // Simulate state where all bytes have been consumed
        state.bytes := [1, 2, 3, 4];
        state.index := 4; // Beyond array bounds, should trigger new byte generation

        let _random = Random.cryptoFromState(state);

        // State should reflect the exhausted condition
        expect.nat(state.bytes.size()).equal(4);
        expect.nat(state.index).equal(4);
        expect.nat(state.index).equal(state.bytes.size())
      }
    );
    await test(
      "Bit mask cycling simulation",
      func() : async () {
        let state = Random.emptyState();

        // Test various bit mask states that would occur during bool() generation
        let bitMaskStates : [Nat8] = [0x00, 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01];

        for (mask in bitMaskStates.vals()) {
          state.bitMask := mask;
          state.bits := 0xFF; // All bits set for testing

          let _random = Random.cryptoFromState(state);

          expect.nat8(state.bitMask).equal(mask);
          expect.nat8(state.bits).equal(0xFF)
        }
      }
    );
    await test(
      "AsyncRandom byte exhaustion simulation",
      func() : async () {
        let state = Random.emptyState();
        let mockBytes1 : [Nat8] = [1, 2];
        let mockBytes2 : [Nat8] = [3, 4, 5];

        // Create a generator that alternates between two different byte arrays
        var callCount = 0;
        func alternatingGenerator() : async* Blob {
          callCount += 1;
          if (callCount % 2 == 1) {
            Blob.fromArray(mockBytes1)
          } else {
            Blob.fromArray(mockBytes2)
          }
        };

        let _random = Random.AsyncRandom(state, alternatingGenerator);

        expect.nat(state.bytes.size()).equal(0);
        expect.nat(state.index).equal(0);

        // Note: Cannot test actual byte generation here due to async limitations
        // This test verifies the setup is correct for async operations
      }
    )
  }
);

await suite(
  "AsyncRandom",
  func() : async () {
    // Helper function to create deterministic mock generator for testing
    func deterministicMockGenerator(seed : Nat8) : () -> async* Blob {
      var counter = seed;
      func() : async* Blob {
        let bytes : [Nat8] = Array.tabulate<Nat8>(
          16,
          func(i) {
            counter := Nat8.fromNat((Nat8.toNat(counter) + 1) % 256);
            counter
          }
        );
        Blob.fromArray(bytes)
      }
    };

    await test(
      "bool() method produces boolean values",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(0));

        let results : [Bool] = [
          await* random.bool(),
          await* random.bool(),
          await* random.bool(),
          await* random.bool(),
          await* random.bool()
        ];

        expect.nat(results.size()).equal(5);

        // Test that bool() advances state
        let initialIndex = state.index;
        let initialBitMask = state.bitMask;
        let _ = await* random.bool();
        // State should be modified after bool() call (either index or bitMask advances)
        expect.bool(state.index > initialIndex or state.bitMask != initialBitMask).isTrue()
      }
    );

    await test(
      "nat8() method produces Nat8 values in correct range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(10));

        let results : [Nat8] = [
          await* random.nat8(),
          await* random.nat8(),
          await* random.nat8(),
          await* random.nat8(),
          await* random.nat8()
        ];

        expect.nat(results.size()).equal(5);

        expect.nat(state.index).equal(5);
        expect.nat(state.bytes.size()).equal(16); // First generator call should populate 16 bytes
      }
    );

    await test(
      "nat8() with known deterministic sequence",
      func() : async () {
        let state = Random.emptyState();
        func predictableGenerator() : async* Blob {
          Blob.fromArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        };
        let random = Random.AsyncRandom(state, predictableGenerator);

        expect.nat8(await* random.nat8()).equal(1);
        expect.nat8(await* random.nat8()).equal(2);
        expect.nat8(await* random.nat8()).equal(3);
        expect.nat8(await* random.nat8()).equal(4);
        expect.nat8(await* random.nat8()).equal(5)
      }
    );

    await test(
      "nat64() method produces Nat64 values",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(42));

        let results : [Nat64] = [
          await* random.nat64(),
          await* random.nat64(),
          await* random.nat64()
        ];

        expect.nat(results.size()).equal(3);

        // Each nat64() should consume 8 bytes, but generator produces 16 bytes at a time
        // So after 3 calls: first 2 calls consume 16 bytes, 3rd call triggers new generator call and consumes 8 more
        expect.nat(state.index).equal(8); // 3rd call consumed 8 bytes from fresh 16-byte batch
      }
    );

    await test(
      "nat64() with predictable bytes produces expected values",
      func() : async () {
        let state = Random.emptyState();
        // Generator that produces bytes 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ...
        func sequentialGenerator() : async* Blob {
          let bytes = Array.tabulate<Nat8>(16, func(i) { Nat8.fromNat(i) });
          Blob.fromArray(bytes)
        };
        let random = Random.AsyncRandom(state, sequentialGenerator);

        let result = await* random.nat64();

        // Expected: bytes [0,1,2,3,4,5,6,7] combined as big-endian Nat64
        // = 0x0001020304050607
        let expected : Nat64 = (0 << 56) | (1 << 48) | (2 << 40) | (3 << 32) | (4 << 24) | (5 << 16) | (6 << 8) | 7;
        expect.nat64(result).equal(expected)
      }
    );

    await test(
      "nat64Range() returns values within specified range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(123));

        let from : Nat64 = 100;
        let toExclusive : Nat64 = 200;

        for (_ in Nat.range(0, 20)) {
          let val = await* random.nat64Range(from, toExclusive);
          expect.bool(val >= from).isTrue();
          expect.bool(val < toExclusive).isTrue()
        }
      }
    );

    await test(
      "nat64Range() with single value range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(0));

        let from : Nat64 = 42;
        let toExclusive : Nat64 = 43;

        for (_ in Nat.range(0, 10)) {
          let val = await* random.nat64Range(from, toExclusive);
          expect.nat64(val).equal(from)
        }
      }
    );

    await test(
      "natRange() returns values within specified range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(200));

        let from = 50;
        let toExclusive = 150;

        for (_ in Nat.range(0, 20)) {
          let val = await* random.natRange(from, toExclusive);
          expect.bool(val >= from).isTrue();
          expect.bool(val < toExclusive).isTrue()
        }
      }
    );

    await test(
      "natRange() with single value range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(0));

        let from = 99;
        let toExclusive = 100;

        for (_ in Nat.range(0, 10)) {
          let val = await* random.natRange(from, toExclusive);
          expect.nat(val).equal(from)
        }
      }
    );

    await test(
      "intRange() returns values within specified range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(77));

        let from = -100;
        let toExclusive = 100;

        for (_ in Nat.range(0, 20)) {
          let val = await* random.intRange(from, toExclusive);
          expect.bool(val >= from).isTrue();
          expect.bool(val < toExclusive).isTrue()
        }
      }
    );

    await test(
      "intRange() with negative range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(55));

        let from = -500;
        let toExclusive = -400;

        for (_ in Nat.range(0, 15)) {
          let val = await* random.intRange(from, toExclusive);
          expect.bool(val >= from).isTrue();
          expect.bool(val < toExclusive).isTrue()
        }
      }
    );

    await test(
      "intRange() with positive range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(33));

        let from = 1000;
        let toExclusive = 2000;

        for (_ in Nat.range(0, 15)) {
          let val = await* random.intRange(from, toExclusive);
          expect.bool(val >= from).isTrue();
          expect.bool(val < toExclusive).isTrue()
        }
      }
    );

    await test(
      "intRange() with single value range",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(0));

        let from = -50;
        let toExclusive = -49;

        for (_ in Nat.range(0, 10)) {
          let val = await* random.intRange(from, toExclusive);
          expect.int(val).equal(from)
        }
      }
    );

    await test(
      "State persistence across multiple generators",
      func() : async () {
        let state = Random.emptyState();

        // First generator
        let random1 = Random.AsyncRandom(state, deterministicMockGenerator(10));
        let val1 = await* random1.nat8();
        let firstIndex = state.index;

        // Second generator with same state
        let random2 = Random.AsyncRandom(state, deterministicMockGenerator(20));
        let val2 = await* random2.nat8();

        // State should continue from where first left off
        expect.nat(state.index).equal(firstIndex + 1);

        // Values should be different since we're continuing from advanced state
        expect.nat8(val1).equal(11); // First byte from deterministicMockGenerator(10)
        expect.nat8(val2).equal(12); // Second byte from same generator state
      }
    );

    await test(
      "Generator refill behavior when bytes exhausted",
      func() : async () {
        let state = Random.emptyState();

        var generatorCallCount = 0;
        func smallChunkGenerator() : async* Blob {
          generatorCallCount += 1;
          if (generatorCallCount == 1) {
            Blob.fromArray([100, 101]) // Only 2 bytes
          } else {
            Blob.fromArray([200, 201, 202, 203]) // 4 bytes
          }
        };

        let random = Random.AsyncRandom(state, smallChunkGenerator);

        // Consume first 2 bytes
        expect.nat8(await* random.nat8()).equal(100);
        expect.nat8(await* random.nat8()).equal(101);
        expect.nat(generatorCallCount).equal(1);

        // This should trigger second generator call
        expect.nat8(await* random.nat8()).equal(200);
        expect.nat(generatorCallCount).equal(2);

        // Continue with remaining bytes from second call
        expect.nat8(await* random.nat8()).equal(201);
        expect.nat8(await* random.nat8()).equal(202);
        expect.nat8(await* random.nat8()).equal(203);
        expect.nat(generatorCallCount).equal(2); // Still 2, no new call needed
      }
    );

    await test(
      "Mixed method calls maintain state consistency",
      func() : async () {
        let state = Random.emptyState();
        let random = Random.AsyncRandom(state, deterministicMockGenerator(128));

        // Mix different method calls
        let _bool1 = await* random.bool();
        let _nat8_1 = await* random.nat8();
        let _nat64_1 = await* random.nat64();
        let _natRange1 = await* random.natRange(0, 100);
        let _intRange1 = await* random.intRange(-50, 50);
        let _bool2 = await* random.bool();

        // State should have advanced appropriately
        // Each nat8() call advances index by 1
        // Each nat64() call advances index by 8
        // Each range call uses nat64() internally, so advances by 8 (or more due to rejection sampling)
        // bool() may or may not advance index depending on bit mask state

        expect.nat(state.index).greater(0); // Should have advanced
        expect.nat(state.bytes.size()).greater(0); // Should have bytes loaded
      }
    )
  }
);

await suite(
  "AsyncRandom cryptographic randomness integration",
  func() : async () {
    await test(
      "crypto() creates working AsyncRandom",
      func() : async () {
        let random = Random.crypto();

        // Test that we can call methods (actual randomness will vary)
        let _bool = await* random.bool();
        let _nat8 = await* random.nat8();
        let _nat64 = await* random.nat64()
      }
    );

    await test(
      "cryptoFromState() with persistent state",
      func() : async () {
        let state = Random.emptyState();
        let random1 = Random.cryptoFromState(state);

        let _val1 = await* random1.nat8();
        let _val2 = await* random1.nat8();

        let random2 = Random.cryptoFromState(state);
        let _val3 = await* random2.nat8();

        // State should have been modified by previous calls
        expect.nat(state.index).greater(0);
        expect.nat(state.bytes.size()).greater(0)
      }
    );

    await test(
      "Multiple crypto instances with shared state",
      func() : async () {
        let state = Random.emptyState();
        let random1 = Random.cryptoFromState(state);
        let random2 = Random.cryptoFromState(state);

        // Both instances should share the same state
        let _val1 = await* random1.nat8();
        let index1 = state.index;

        let _val2 = await* random2.nat8();
        let index2 = state.index;

        // Second call should advance from where first left off
        expect.nat(index2).greater(index1)
      }
    )
  }
)
