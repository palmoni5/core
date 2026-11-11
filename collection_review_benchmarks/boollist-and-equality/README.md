# Collection microbenchmarks

The bundled microbenchmarks compare the base revision with the proposed changes through public package entry points.

| Role | Revision |
| --- | --- |
| Base for both comparisons | `fa0c6b77d67b6837eb2891e251c40cdfbeab1f4d` |
| Original BoolList proposal | `638d90b7ea92691e35741bd51db26155ebece6e1` |
| Revised BoolList proposal | `dfd17fe9f54470df715ba6f7bdaab26c0c18ac5d` |
| List equality and hashing proposal | `5afd424395f127649101a0d72f40ff8c1f7940af` |

The patches contain the exact library differences against the base. They make the benchmark reproducible independently of the availability of the topic branches. The revised BoolList hash identifies the commit tested locally.

The measurements used Dart 3.13.5 stable AOT on Windows x64 with an Intel Core i5-14500. Each executable contained both implementations and ran in two fresh processes pinned to logical processors 2 and 6, using affinity masks 4 and 64. Each process warmed up each operation for 40 ms, then measured seven paired rounds, with seeded randomized case and variant order. A timed sample ran for at least 60 ms in batches of 64 calls. The program checks that each pair of implementations gives the same result before timing and accumulates a checksum in the timed loop.

Run on Windows with PowerShell, Git and the Dart SDK on PATH. Choose valid logical-processor affinity masks if the defaults do not apply to your machine.

```powershell
.\run.ps1
.\run.ps1 -Masks @(1, 2) -Dart 'C:\tools\dart-sdk\bin\dart.exe'
```

The runner prepares a fresh directory, applies the bundled patches, and prints the location of the new CSV files. Use `-Destination` to choose a new directory and `-SourceRepo` to use an existing Git clone. `-Offline` tells Dart to resolve dependencies from its local cache. The original runs resolved `meta` 1.19.0.

Run `python summary.py` to summarize the bundled raw samples, or pass the path to a directory of newly generated CSVs. The `after/before` column is the median of the seven individual paired ratios. `before ns` and `after ns` are the separate medians in nanoseconds per call.

The BoolList cases time a shrink followed by regrowth to the original length and a checksum read of a retained bit. `bool-reallocate` includes allocations. `bool-reserved` is a synthetic case with 1,048,576 reserved bits and only 128 visible bits. The equality cases use ordinary lists of eight or 128 integers and combined views with four or 32 lists of 16 integers. The mismatch cases differ at the first element. The list equality code is the same in all four processes. The original pair of runs also covers the original BoolList change, and the second pair covers the revised BoolList change. The final checksum can differ across runs because the number of calls in each time window varies.

The samples come from one desktop configuration with other system activity. The magnitude of the results depends on the workload and runtime. The combined views are synthetic and the timings do not measure application performance.
