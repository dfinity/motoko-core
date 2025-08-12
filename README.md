# Benchmark Results



<details>

<summary>bench/ArrayBuilding.bench.mo $({\color{gray}0\%})$</summary>

### Large known-size array building

_Compares performance of different data structures for building arrays of known size._


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                  |    1000 |     100000 |     1000000 |
| :--------------- | ------: | ---------: | ----------: |
| List             | 548_233 | 48_324_535 | 478_161_875 |
| Buffer           | 342_005 | 33_903_435 | 339_003_650 |
| pure/List        | 302_135 | 30_003_590 | 300_055_972 |
| VarArray ?T      | 180_526 | 17_802_956 | 178_003_171 |
| VarArray T       | 160_813 | 15_803_243 | 158_003_458 |
| Array (baseline) |  42_695 |  4_003_125 |  40_003_340 |


**Heap**

|                  |  1000 | 100000 | 1000000 |
| :--------------- | ----: | -----: | ------: |
| List             | 272 B |  272 B |   272 B |
| Buffer           | 272 B |  272 B |   272 B |
| pure/List        | 272 B |  272 B |   272 B |
| VarArray ?T      | 272 B |  272 B |   272 B |
| VarArray T       | 272 B |  272 B |   272 B |
| Array (baseline) | 272 B |  272 B |   272 B |


**Garbage Collection**

|                  |      1000 |     100000 |   1000000 |
| :--------------- | --------: | ---------: | --------: |
| List             | 10.05 KiB | 797.56 KiB |  7.67 MiB |
| Buffer           |  8.71 KiB | 782.15 KiB |  7.63 MiB |
| pure/List        | 19.95 KiB |   1.91 MiB | 19.07 MiB |
| VarArray ?T      |  8.24 KiB | 781.68 KiB |  7.63 MiB |
| VarArray T       |  8.23 KiB | 781.67 KiB |  7.63 MiB |
| Array (baseline) |   4.3 KiB | 391.02 KiB |  3.82 MiB |


</details>
Saving results to .bench/ArrayBuilding.bench.json

<details>

<summary>bench/FromIters.bench.mo $({\color{gray}0\%})$</summary>

### Benchmarking the fromIter functions

_Columns describe the number of elements in the input iter._


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                              |    100 |    10_000 |    100_000 |
| :--------------------------- | -----: | --------: | ---------: |
| Array.fromIter               | 48_764 | 4_712_025 | 47_103_135 |
| List.fromIter                | 31_698 | 3_061_541 | 30_603_553 |
| List.fromIter . Iter.reverse | 50_297 | 4_832_522 | 48_305_436 |


**Heap**

|                              |   100 | 10_000 | 100_000 |
| :--------------------------- | ----: | -----: | ------: |
| Array.fromIter               | 272 B |  272 B |   272 B |
| List.fromIter                | 272 B |  272 B |   272 B |
| List.fromIter . Iter.reverse | 272 B |  272 B |   272 B |


**Garbage Collection**

|                              |      100 |     10_000 |  100_000 |
| :--------------------------- | -------: | ---------: | -------: |
| Array.fromIter               | 2.76 KiB | 234.79 KiB | 2.29 MiB |
| List.fromIter                | 3.51 KiB | 312.88 KiB | 3.05 MiB |
| List.fromIter . Iter.reverse | 5.11 KiB | 469.17 KiB | 4.58 MiB |


</details>
Saving results to .bench/FromIters.bench.json

<details>

<summary>bench/ListBufferNewArray.bench.mo $({\color{gray}0\%})$</summary>

### List vs. Buffer for creating known-size arrays

_Performance comparison between List and Buffer for creating a new array._


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|           | 0 (baseline) |     1 |     5 |     10 | 100 (for loop) |
| :-------- | -----------: | ----: | ----: | -----: | -------------: |
| List      |        1_547 | 2_916 | 9_046 | 13_948 |         74_564 |
| pure/List |        1_247 | 1_355 | 2_439 |  3_801 |         31_868 |
| Buffer    |        2_119 | 2_271 | 3_518 |  5_085 |         36_640 |


**Heap**

|           | 0 (baseline) |     1 |     5 |    10 | 100 (for loop) |
| :-------- | -----------: | ----: | ----: | ----: | -------------: |
| List      |        272 B | 272 B | 272 B | 272 B |          272 B |
| pure/List |        272 B | 272 B | 272 B | 272 B |          272 B |
| Buffer    |        272 B | 272 B | 272 B | 272 B |          272 B |


**Garbage Collection**

|           | 0 (baseline) |     1 |     5 |    10 | 100 (for loop) |
| :-------- | -----------: | ----: | ----: | ----: | -------------: |
| List      |        576 B | 616 B | 776 B | 884 B |       1.93 KiB |
| pure/List |        360 B | 380 B | 460 B | 560 B |        2.3 KiB |
| Buffer    |        856 B | 864 B | 896 B | 936 B |       1.62 KiB |


</details>
Saving results to .bench/ListBufferNewArray.bench.json

<details>

<summary>bench/PureListStackSafety.bench.mo $({\color{gray}0\%})$</summary>

### List Stack safety

_Check stack-safety of the following `pure/List`-related functions._


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                     |             |
| :------------------ | ----------: |
| pure/List.split     |  24_602_524 |
| pure/List.all       |   7_901_014 |
| pure/List.any       |   8_001_390 |
| pure/List.map       |  23_103_767 |
| pure/List.filter    |  21_104_188 |
| pure/List.filterMap |  27_404_742 |
| pure/List.partition |  21_304_994 |
| pure/List.join      |  33_105_326 |
| pure/List.flatten   |  24_805_667 |
| pure/List.take      |  24_605_664 |
| pure/List.drop      |   9_904_119 |
| pure/List.foldRight |  19_105_768 |
| pure/List.merge     |  31_808_584 |
| pure/List.chunks    |  51_510_344 |
| pure/Queue          | 142_662_505 |


**Heap**

|                     |       |
| :------------------ | ----: |
| pure/List.split     | 272 B |
| pure/List.all       | 272 B |
| pure/List.any       | 272 B |
| pure/List.map       | 272 B |
| pure/List.filter    | 272 B |
| pure/List.filterMap | 272 B |
| pure/List.partition | 272 B |
| pure/List.join      | 272 B |
| pure/List.flatten   | 272 B |
| pure/List.take      | 272 B |
| pure/List.drop      | 272 B |
| pure/List.foldRight | 272 B |
| pure/List.merge     | 272 B |
| pure/List.chunks    | 272 B |
| pure/Queue          | 272 B |


**Garbage Collection**

|                     |           |
| :------------------ | --------: |
| pure/List.split     |  3.05 MiB |
| pure/List.all       |     328 B |
| pure/List.any       |     328 B |
| pure/List.map       |  3.05 MiB |
| pure/List.filter    |  3.05 MiB |
| pure/List.filterMap |  3.05 MiB |
| pure/List.partition |  3.05 MiB |
| pure/List.join      |  3.05 MiB |
| pure/List.flatten   |  3.05 MiB |
| pure/List.take      |  3.05 MiB |
| pure/List.drop      |     328 B |
| pure/List.foldRight |  1.53 MiB |
| pure/List.merge     |  4.58 MiB |
| pure/List.chunks    |  7.63 MiB |
| pure/Queue          | 18.31 MiB |


</details>
Saving results to .bench/PureListStackSafety.bench.json

<details>

<summary>bench/Queues.bench.mo $({\color{gray}0\%})$</summary>

### Different queue implementations

_Compare the performance of the following queue implementations_:
- `pure/Queue`: The default immutable double-ended queue implementation.
  * Pros: Good amortized performance, meaning that the average cost of operations is low `O(1)`.
  * Cons: In worst case, an operation can take `O(size)` time rebuilding the queue as demonstrated in the `Pop front 2 elements` scenario.
- `pure/RealTimeQueue`
  * Pros: Every operation is guaranteed to take at most `O(1)` time and space.
  * Cons: Poor amortized performance: Instruction cost is on average 3x for *pop* and 8x for *push* compared to `pure/Queue`.
- mutable `Queue`
  * Pros: Also `O(1)` guarantees with a lower constant factor than `pure/RealTimeQueue`. Amortized performance is comparable to `pure/Queue`.
  * Cons: It is mutable and cannot be used in `shared` types (not shareable)_._


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                            | pure/Queue | pure/RealTimeQueue | mutable Queue |
| :------------------------- | ---------: | -----------------: | ------------: |
| Initialize with 2 elements |      3_092 |              2_304 |         3_040 |
| Push 500 elements          |     90_713 |            744_219 |       219_284 |
| Pop front 2 elements       |     86_966 |              4_446 |         3_847 |
| Pop 150 front&back         |     92_095 |            304_908 |       124_581 |


**Heap**

|                            | pure/Queue | pure/RealTimeQueue | mutable Queue |
| :------------------------- | ---------: | -----------------: | ------------: |
| Initialize with 2 elements |      324 B |              300 B |         352 B |
| Push 500 elements          |   8.08 KiB |           8.17 KiB |      19.8 KiB |
| Pop front 2 elements       |      240 B |              240 B |         192 B |
| Pop 150 front&back         |  -4.42 KiB |             -492 B |    -11.45 KiB |


**Garbage Collection**

|                            | pure/Queue | pure/RealTimeQueue | mutable Queue |
| :------------------------- | ---------: | -----------------: | ------------: |
| Initialize with 2 elements |      508 B |              444 B |         456 B |
| Push 500 elements          |   10.1 KiB |         137.84 KiB |         344 B |
| Pop front 2 elements       |  12.19 KiB |              528 B |         424 B |
| Pop 150 front&back         |  15.61 KiB |          49.66 KiB |      12.1 KiB |


</details>
Saving results to .bench/Queues.bench.json
