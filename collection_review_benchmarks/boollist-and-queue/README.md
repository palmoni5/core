# BoolList.of and QueueList.from

This benchmark compares changes proposed in [Otzaria/core #22](https://github.com/Otzaria/core/pull/22) and [#23](https://github.com/Otzaria/core/pull/23) against their common base. The production files come from these commits.

| Variant | Commit |
| --- | --- |
| Common baseline | `7f11cda89f00a7b04ce6d1e840138034005891c7` |
| Original BoolList change | `a996328297e76f1e3bc00f570cdd715f6c450852` |
| Reviewed BoolList change in isolation | `5831c688fb080fffa7e5c9f9f6860101549e4aec` |
| Proposed QueueList change | `107a63f520036d16e4d148cf2e86a96821d1ebfc` |

The patches let you reconstruct each version from the baseline, including the reviewed version if its isolated commit is unavailable. The runner checks the Git blob IDs for all five production files before compiling them together into one AOT executable. Git, Dart SDK, and Python 3.12 or newer are required.

```shell
git clone https://github.com/Otzaria/core.git
python run.py --repo core --output reproduction
python summary.py reproduction/run1.csv reproduction/run2.csv
```

`--dart` accepts a specific SDK executable. `--offline` is available if the Dart package cache is populated. The runner builds and benchmarks in a temporary copy. Each CSV row records elapsed nanoseconds per operation for one variant in one round. The summary reports the median of the per-round candidate/baseline time ratios. A ratio below 1 means the candidate completed the operation faster.

Each scenario has one warm-up per variant followed by 11 rounds. Variant order changes within each round using a seeded RNG. The two data files come from separate processes with different seeds. The timed work includes a read and a length check to consume the constructed collection. The checksum is recorded in `data/metadata.json`. Both processes ran with Dart 3.13.5 AOT on Windows x64 and an Intel Core i5-14500, with no CPU affinity set. These measurements describe the tested inputs on this machine. They do not establish application-level impact or performance on other runtimes.

The BoolList scenarios cover a concrete list, a two-element bool set, a mapped list with inexpensive length, and a replayable `sync*` iterable. They use the default fixed-length constructor. The reviewed implementation accumulates a word before writing it to storage and allocates the final list directly for short input. The QueueList scenarios compare creation alone with creation immediately followed by an append, at and around powers of two. Capacity follows directly from the ring-size calculation. At lengths such as 7, 15, and 31, the proposal halves the initial backing table and the first append triggers a grow-and-copy.

Selected candidate/baseline time ratios from the 2,992 observations in `data/`:

| Scenario | Run 1 | Run 2 |
| --- | ---: | ---: |
| Original BoolList, 64 mapped elements | 1.329 | 1.243 |
| Reviewed BoolList, 64 mapped elements | 0.718 | 0.762 |
| Reviewed BoolList, 64 `sync*` elements | 0.523 | 0.517 |
| Reviewed BoolList, concrete list of 2 | 1.005 | 1.086 |
| QueueList proposal, create 31 elements | 0.782 | 0.905 |
| QueueList proposal, create 31 then append | 1.959 | 1.790 |

The reviewed BoolList improved the mapped-list and `sync*` cases in both processes. Concrete-list results varied by length and process. For example, 33 elements took 1.210 times the baseline time in run 1 and 0.965 times in run 2. The QueueList append case at capacity boundaries (7, 15, 31, 63, 1023) was 1.66–2.09 times the baseline time across both processes.

For correctness, the four BoolList suites on the integrated `86ac482dc0e3ff5a00a40afae1999826cee5f522` commit passed 24 tests each on the VM, Chrome Dart2Js, and Chrome Dart2Wasm. The included `integrated_smoke_test.dart` also passed on all three targets. It constructs a growable packed list from a mapped iterable, performs an empty fill, then shrinks and regrows the same list at nine lengths. Copy it to the collection package's `test/` directory to run it with `dart test -p vm,chrome test/integrated_smoke_test.dart` and `dart test -p chrome --compiler dart2wasm test/integrated_smoke_test.dart`.
