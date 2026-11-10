# UTF-16 range iteration measurements for dart-lang/core#1042

Candidate: a62023e5b99fe892bf91b0ed1ee7a5fb2b32145f. No product code changed during this measurement.

## Reproduce

On Windows with the recorded Dart SDK, adjust `run.ps1`'s SDK path and run it in a quiet CPU window, then run `python summarize.py`. It compiles `measure.dart` to AOT and launches three fresh processes. Each process is paused until the parent pins affinity to logical CPU 4 (mask 16). Metadata records CPU, SDK, candidate, affinity and seeds; source hashes identify the examined SDK files.

For each workload, the runner calibrates the baseline to at least 15ms and collects 31 pairs in randomized baseline/proposal order. `samples-*.csv` records all 2,697 pairs and checksums. `summary.csv` reports medians, paired ratio bootstrap intervals (5,000 resamples, fixed seed) and the minimum/maximum of the three process median ratios. Ratios below 1 favor the proposal. Bootstrap intervals describe these samples, not hardware/SDK population uncertainty; process medians expose between-process variation.

## Workloads and limits

The two adapters reproduce the exact before/after getter bodies; consumers run through a common abstract interface. Each operation creates a fresh iterable and consumes its length, isEmpty, elementAt, one traversal, three traversals, or a snapshot after the mutable range is collapsed. Selection start alternates between neighboring code units. This is UTF-16 iteration, so starts need not be grapheme boundaries. The source mixes Hebrew letters, niqqud and supplementary emoji; source sizes are 56 and 1,400,000 UTF-16 units, selections 0/2/32/8192 units. Every case checks equal outputs before timing. Snapshot capture is tested by mutating the range before consumption. The checksum is used outside timed work; the work function is not inlined.

These are getter/consumer microbenchmarks, not public CharacterRange construction/navigation or whole-app workloads. No allocation-byte measurement, JIT/web/Wasm timing, or alternate SDK/hardware timing is claimed. CPU affinity and an agreed quiet measurement window reduce noise, but do not eliminate OS/background load or compiler specialization effects.

## Results on the recorded host

All 29 case/mode combinations favor the proposal in each of the three process medians. Pooled median ratios range from 0.425 to 0.776.

| Workload | Baseline | Proposal | Median ratio | Paired bootstrap 95% |
| --- | ---: | ---: | ---: | ---: |
| short source, two units, iterate | 74.1ns | 48.0ns | 0.643 | 0.639–0.651 |
| long source, two units, iterate | 80.7ns | 53.4ns | 0.670 | 0.654–0.683 |
| long source, 8192 units, iterate | 143.1µs | 88.9µs | 0.616 | 0.610–0.620 |
| short source, two units, length | 25.9ns | 18.5ns | 0.711 | 0.702–0.729 |
| short source, two units, elementAt | 31.0ns | 21.4ns | 0.711 | 0.700–0.715 |
| short source, two units, snapshot | 82.9ns | 56.7ns | 0.675 | 0.669–0.680 |

## SDK inspection and recommendation

In this SDK, VM `string_patch.dart`, JS `js_string.dart` (including dev runtime), and both Wasm string implementations all return `CodeUnits(this)`. `CodeUnits` stores the original string; length reads string.length and indexing uses codeUnitAt. It never materializes all source units. `ListBase.getRange` validates bounds and constructs a `SubListIterable`, whose length/elementAt repeatedly consult the wrapped iterable; the proposed generated iterable stores a length and uses a closure over the string/start. Both remain O(1) in source length for a fixed selection and retain the backing string. Source inspection is not a web/Wasm performance measurement.

The local speedup is reproducible here, so the original reviewer suspicion of no possible speedup is not supported by these measurements. The proposed SDK target is nevertheless sound: specializing CodeUnits.getRange can benefit all callers without changing Characters. Otzaria's current lib/test code has no direct utf16CodeUnits/codeUnits.getRange call site; these measurements establish no direct Otzaria gain. Prefer reporting the SDK performance opportunity with this reproducer and deferring/withdrawing the package workaround if maintainers prefer the SDK solution. Do not claim a whole-string allocation fix or app-wide speedup.
