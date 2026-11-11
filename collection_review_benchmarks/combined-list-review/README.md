# CombinedListView review measurements

This experiment compares the collection code at `fa0c6b77d67b6837eb2891e251c40cdfbeab1f4d`, the original PR at `60b51d26cbe2dc71723e16be519fd777a4307fd3`, and the reviewer's child-list delegation applied to the baseline. The delegate falls back to ListBase for probes outside T to preserve cross-type equality.

Two fresh Dart 3.13.5 AOT processes ran on an i5-14500, Windows x64, pinned to logical CPU 6. Each recorded 11 randomized rounds with three variants in a single executable. Results in the CSVs are nanoseconds per call. The program checks the result of every case across all variants before timing.

From a new working directory containing these files, with a Git clone that has both revisions:

```powershell
python prepare.py C:/path/to/core
dart compile exe bench.dart -o bench.exe
(Get-Process -Id $PID).ProcessorAffinity = [IntPtr]64
./bench.exe 1729 | Set-Content -Encoding ascii timings-1729.csv
./bench.exe 3719 | Set-Content -Encoding ascii timings-3719.csv
New-Item -ItemType Directory -Force source | Out-Null
foreach ($v in 'base','full','delegate') {
  Copy-Item "$v/*.dart" source -Force
  dart compile aot-snapshot size.dart -o "$v.aot"
  dart compile js -O4 size.dart -o "$v.js"
  Get-Item "$v.aot","$v.js" | Select-Object Name,Length
}
```

The two-child miss took 0.205 and 0.206 times the baseline time with delegation, and the 128-child miss took 0.009 times baseline in both runs. The small harness calls all methods originally overridden. Its artifacts were 823,992/844,000/825,272 bytes (AOT snapshot) and 36,145/37,400/36,662 bytes (uncompressed JavaScript) for baseline/full/delegate respectively. These are whole-harness sizes, including compiler and reachability effects. The timings and sizes do not measure any application workload.