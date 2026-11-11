
param(
  [string]$Dart = 'dart',
  [string]$SourceRepo = 'https://github.com/dart-lang/core.git',
  [string]$Destination = (Join-Path ([IO.Path]::GetTempPath()) ('collection-review-' + [guid]::NewGuid().ToString('N'))),
  [long[]]$Masks = @(4, 64),
  [switch]$Offline
)

$ErrorActionPreference = 'Stop'
$base = 'fa0c6b77d67b6837eb2891e251c40cdfbeab1f4d'
$root = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
if (Test-Path -LiteralPath $root) {
  throw "Destination already exists: $root"
}
New-Item -ItemType Directory -Path $root | Out-Null
$baseline = Join-Path $root 'core-review'
$boollist = Join-Path $root 'collection-b-qa-11'
$equality = Join-Path $root 'collection-b-qa-15'
$output = Join-Path $root 'raw'
New-Item -ItemType Directory -Path $output | Out-Null

function Invoke-Checked {
  param([string]$Command, [string[]]$Arguments)
  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Command failed with exit code $LASTEXITCODE"
  }
}

Invoke-Checked $Dart @('--version')
Invoke-Checked git @('clone', '--no-checkout', $SourceRepo, $baseline)
Invoke-Checked git @('-C', $baseline, 'checkout', '--detach', $base)
Invoke-Checked git @('-C', $baseline, 'worktree', 'add', '--detach', $boollist, $base)
Invoke-Checked git @('-C', $baseline, 'worktree', 'add', '--detach', $equality, $base)
Invoke-Checked git @('-C', $equality, 'apply', (Join-Path $PSScriptRoot 'list-equality.patch'))

$package = Join-Path $boollist 'pkgs/collection'
Push-Location $package
try {
  $pubArgs = @('pub', 'get')
  if ($Offline) { $pubArgs += '--offline' }
  Invoke-Checked $Dart $pubArgs
  $main = Join-Path $package '.dart_tool/review_bench.dart'
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'review_bench.dart') -Destination $main

  $previousPatch = $null
  foreach ($variant in @('original', 'optimized')) {
    if ($previousPatch) {
      Invoke-Checked git @('-C', $boollist, 'apply', '-R', $previousPatch)
    }
    $patch = Join-Path $PSScriptRoot "boollist-$variant.patch"
    Invoke-Checked git @('-C', $boollist, 'apply', $patch)
    $previousPatch = $patch
    $exe = Join-Path $package ".dart_tool/review-bench-$variant.exe"
    Invoke-Checked $Dart @('compile', 'exe', $main, '-o', $exe)

    foreach ($mask in $Masks) {
      $name = if ($variant -eq 'original') { "bench-$mask" } else { "bench-optimized-$mask" }
      $stdout = Join-Path $output "$name.csv"
      $stderr = Join-Path $output "$name.stderr"
      $p = Start-Process -FilePath $exe -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
      [void] $p.Handle
      $p.ProcessorAffinity = [IntPtr] $mask
      $p.WaitForExit()
      if ($p.ExitCode -ne 0) { throw "Benchmark failed. See $stderr" }
      $lines = @(Get-Content -LiteralPath $stdout)
      if ($lines.Count -ne 107 -or $lines[-1] -notlike '# checksum *') {
        throw "Incomplete benchmark output: $stdout"
      }
    }
  }
} finally {
  Pop-Location
}
Write-Output "CSV results are in $output"
