# Collection lookup and hashing measurements

This directory contains a Dart AOT microbenchmark for Otzaria/core [#18](https://github.com/Otzaria/core/pull/18) and [#21](https://github.com/Otzaria/core/pull/21), plus a deterministic workload check for [#24](https://github.com/Otzaria/core/pull/24).

| Source | Commit |
| --- | --- |
| Baseline, before these collection changes | `7f11cda89f00a7b04ce6d1e840138034005891c7` |
| #18 original | `f12ee261c1a2102733f6b6a9a1ffdf6bee135778` |
| #18 after review | `7cda5295d16777f5a71aa3167af769e7b05f6b2a` |
| #21 original | `f55122ea98ac87e3761dfc20cbdcc9dd4a967880` |
| #21 after review | `78ddf6bed8c6f1f4ce902d122f9fa4d4aec49aa2` |
| #24 proposal | `4a21cb32144644da4605d0274b3797e07c986073` |

The reviewed #18 tree is identical to the local timing revision. The only formatting between that compilation and the final tree reflows a loop header. The reviewed #21 tree is identical to the local timing revision. Its production change was already present in the original #21, so the two sets of #21 timings measure the same code twice.

## Reproduce

Requires Git, Python 3 and the Dart SDK. The original measurements used Dart 3.13.5 stable on Windows x64 with an Intel Core i5-14500. All runs used logical CPU 6 (affinity mask 64). Pinning reduces scheduler variability. Exact timings depend on the environment.

Clone Otzaria/core or use an existing clone. Fetch the PR head refs if the objects in the table are absent. The referenced revisions are the PR heads or ancestors of the heads.

```text
git clone https://github.com/Otzaria/core.git
git -C core fetch origin refs/pull/18/head refs/pull/21/head refs/pull/24/head
python prepare.py core repro
```

`prepare.py` extracts only the collection source trees at the exact commits and copies the Dart scripts into a new directory. The benchmark needs no Dart packages. Run `python prepare.py core repro-original --variant original` to reproduce the original candidates instead.

From the generated directory, compile one executable containing all implementations. The PowerShell affinity command is optional and uses the logical CPU selected for the original measurements.

```powershell
dart compile exe bench.dart -o bench.exe
(Get-Process -Id $PID).ProcessorAffinity = [intptr]64
./bench.exe 1729 list | Set-Content -Encoding ascii list-1729.csv
./bench.exe 3719 list | Set-Content -Encoding ascii list-3719.csv
./bench.exe 1729 map | Set-Content -Encoding ascii map-1729.csv
./bench.exe 3719 map | Set-Content -Encoding ascii map-3719.csv
dart prove24.dart
dart prove21.dart
dart prove18-mutation.dart
```

The benchmark checks the result of each operation against the baseline, warms up both implementations, and records 11 pairs per case and seed with randomized case and pair order. It consumes each result in a checksum. The supplied CSVs use the suffix `-fixed-` for reviewed timings. From this directory, run `python summary.py` for all raw files or pass CSV paths to summarize newly generated runs. The reported ratio is the median of each pair's candidate time divided by its baseline time. A ratio under 1 indicates a lower candidate time.

## Results and limits

- **#18.** In a list with 128 children, the original `lastIndexOf(value, 0)` took 1.733× and 1.732× baseline time. The reviewed version took 0.026× and 0.028×. With the default start and an immediate match at the end it took 0.533× and 0.521×. For a one-child list in that last case, the ratios were 1.063× and 0.915×. `prove18-mutation.dart` shows the separate behavior change when an element's equality operator resizes a backing list during lookup.
- **#21.** For 64 entries the reviewed ratios were 0.457× and 0.464× for LinkedHashMap, 0.585× and 0.603× for HashMap, and 0.233× in both runs for SplayTreeMap. The custom wrapper inheriting MapBase.forEach took 1.185× in both runs with one entry, and 1.051× and 1.098× with eight entries. `prove21.dart` demonstrates how the hash differs for a map that violates the Map contract by supplying different values through `forEach` and index lookup. These measurements are for local microbenchmarks in one runtime.
- **#24.** `prove24.dart` uses a mapped list of 100,000 entries. Both revisions return 99,999. The baseline invokes the mapping function once and the proposed change invokes it 100,000 times. This proof counts invocations and does not depend on the timing environment.
