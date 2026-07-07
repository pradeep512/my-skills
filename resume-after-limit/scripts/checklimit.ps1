<# Print when the Claude 5h/7d windows reset, from ~/.claude/rate-limit-cache.json (Windows). #>
$cache = Join-Path $env:USERPROFILE ".claude\rate-limit-cache.json"
if (-not (Test-Path $cache)) { Write-Host "No cache yet. Set up the statusline tee (REFERENCE.md) or open a session first."; exit 1 }
$j = Get-Content $cache -Raw | ConvertFrom-Json
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
function Show($label, $node) {
  if (-not $node -or -not $node.resets_at) { return }
  $p = if ($node.used_percentage -ne $null) { "{0:N0}%" -f $node.used_percentage } else { "--" }
  $res = [long]$node.resets_at
  if ($res -gt $now) {
    $dt = [DateTimeOffset]::FromUnixTimeSeconds($res).LocalDateTime
    $rem = [TimeSpan]::FromSeconds($res - $now)
    "{0,-3} {1} used · resets {2:ddd hh:mm tt} (in {3}h {4:D2}m)" -f $label, $p, $dt, [int]$rem.TotalHours, $rem.Minutes
  } else { "{0,-3} {1} used · window already reset" -f $label, $p }
}
Write-Host "Claude usage limits:"
Show "5h" $j.five_hour
Show "7d" $j.seven_day
