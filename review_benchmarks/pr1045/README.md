# Evidence for dart-lang/core#1045

This experiment measures the cost of the proposed ASCII/Hebrew checks against
the PR's exact upstream base. It also tests a discarded alternative that uses
the existing Unicode category lookup and skips the transition lookup only for
`Other -> Other`. The alternative is an experiment, not a proposed fix.

## Reproduce

Install Python 3.9+, Git and a Dart SDK. From this directory:

```sh
python run.py --dart /path/to/dart --cpu 2 --output new-results.csv
```

The runner clones the upstream repository, fetches PR #1045, checks out the
exact commits recorded in `core-pr1045-metadata.json`, applies `generic.patch`
only to the experimental copy, and rejects unexpected source differences.
It compiles all three implementations into one AOT executable and sets process
affinity before releasing the benchmark's start gate. Windows uses AboveNormal
priority; Linux uses affinity without changing priority. CPU numbers are
zero-based and must be available to the current process.

Each phrase is measured once and repeated 1024 times, using forward iteration,
`length`, and reverse iteration. Each timing traverses the complete input;
the checksum must match the upstream grapheme count. Seven rounds randomize
implementation order with seed 1045. Each timing targets about 30 ms based on
baseline calibration. Raw rows include elapsed microseconds, iteration count,
checksum and graphemes per second. The summary reports the median, minimum,
maximum and number of winning paired ratios. A speedup below 1 means slower.

## Recorded runs

Dart 3.13.5 stable, Windows x64, Intel Core i5-14500. The first run used logical
CPU 2; the repeat used CPU 6. No other benchmark agent ran during these runs,
but other desktop tasks were active. Affinity and randomized pairing reduce
noise; they do not eliminate scheduling, frequency, cache and GC effects.
These are synthetic AOT results on one machine, not cross-runtime guarantees.

Selected **median throughput ratios** (original / baseline):

| Input and operation | Run 1 | Repeat |
| --- | ---: | ---: |
| ASCII short, forward | 1.1377 | 1.0923 |
| ASCII long, forward | 1.1616 | 1.1852 |
| Hebrew long, forward | 0.9133 | 1.0229 |
| Arabic short, forward | 0.9171 | 0.9075 |
| Arabic long, forward | 0.8037 | 0.8529 |
| Latin extended short, length | 0.8556 | 0.8626 |
| Latin extended long, length | 0.8754 | 0.7965 |

All seven Latin-extended short `length` pairs were slower in **both** runs.
Other cases have wider ranges; consult both complete summaries and raw files.
The generic alternative also has regressions and is not justified by these
results. The global checks benefit some inputs while repeatedly penalizing
others; these measurements do not justify shipping the proposed optimization.

The recorded CSV files came from the same benchmark body before adding the
start gate and the portable bootstrap runner. The gate only delays measurement
until affinity is set; it does not change the timed loops.
