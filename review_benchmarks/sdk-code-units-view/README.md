# Direct UTF-16 range view prototype

Follow-up to [dart-lang/sdk#64901](https://github.com/dart-lang/sdk/issues/64901). The baseline calls the shipped `String.codeUnits.getRange`. The prototype stores the string, start, and checked length and indexes the string directly. It uses a copy of the installed SDK's `ListIterator` so both sides have the same iterator structure. It is a standalone experiment. It does not measure a patched SDK or the proposed `skip` and `take` overrides.

The runs used Dart 3.13.5 stable AOT on Windows x64, Intel Core i5-14500, logical CPU 4. Each fresh process ran 11 randomized pairs for each of 29 cases and checked outputs before measuring. The CSV's proposal column is the direct view.

```powershell
dart compile exe measure.dart -o measure.exe
(Get-Process -Id $PID).ProcessorAffinity = [IntPtr]16
'go' | ./measure.exe samples-1042.csv 1042
'go' | ./measure.exe samples-2317.csv 2317
```

The median paired ratios for two-unit iteration were 0.466–0.468 on the short string and 0.460–0.472 on the long string. For 8,192 units on the long string they were 0.338–0.349. These numbers describe this machine, workload and runtime.