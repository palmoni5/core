$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$sdk = 'C:\Users\otzaria\tools\flutter\bin\cache\dart-sdk'
& "$sdk\bin\dart.exe" compile exe "$root\measure.dart" -o "$root\measure.exe"
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed' }
@{
    sdk = (& "$sdk\bin\dart.exe" --version 2>&1 | Out-String).Trim()
    cpu = (Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors)
    prHead = 'a62023e5b99fe892bf91b0ed1ee7a5fb2b32145f'
    affinityMask = 16
    seeds = @(1042, 2317, 8129)
    protocol = '31 paired samples per mode, randomized BP/PB order, >=15ms baseline calibration, checksums checked before timing, one logical CPU (mask 16), three fresh AOT processes'
} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$root\metadata.json"
foreach ($seed in @(1042, 2317, 8129)) {
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = "$root\measure.exe"
    $start.Arguments = ('"{0}" {1}' -f "$root\samples-$seed.csv", $seed)
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    [void]$process.Start()
    $process.ProcessorAffinity = [IntPtr]16
    $process.StandardInput.WriteLine('go')
    $result = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "Measurement failed: $seed" }
    Write-Output $result.Trim()
}
