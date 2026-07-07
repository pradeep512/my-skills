<#
  Windows - fired by the Scheduled Task at the reset. Fresh unattended Claude,
  Codex fallback, then unregisters its own task (one-shot).
  NOTE: written but not yet verified on a live Windows box.
#>
param(
  [Parameter(Mandatory=$true)][string]$ProjectDir,
  [Parameter(Mandatory=$true)][string]$Handoff,
  [string]$Model = "claude-opus-4-8"
)
$TaskName = "ClaudeResumeAfterLimit"
$Here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateDir = Join-Path $env:USERPROFILE ".claude\resume-after-limit"
$Tmpl     = Join-Path $Here "..\continue-prompt.md"
New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
$ts  = Get-Date -Format "yyyyMMdd-HHmmss"
$log = Join-Path $StateDir "run-$ts.log"
Start-Transcript -Path $log -Append | Out-Null

Write-Host "=== resume-after-limit fired $(Get-Date) ==="
Set-Location $ProjectDir
$branch = (& git rev-parse --abbrev-ref HEAD) 2>$null; if (-not $branch) { $branch = "unknown" }
$prompt = (Get-Content $Tmpl -Raw).Replace("{{HANDOFF}}", $Handoff).Replace("{{BRANCH}}", $branch)
$limitRe = 'rate.?limit|usage limit|exceeded your|Overloaded|\b429\b'

$success = $false; $engine = "none"
foreach ($attempt in 1..6) {
  Write-Host "--- claude attempt $attempt ($(Get-Date)) ---"
  $out = & claude -p --dangerously-skip-permissions --model $Model $prompt 2>&1
  $rc = $LASTEXITCODE
  $out | Out-Host
  if ($rc -eq 0) { $success = $true; $engine = "claude"; break }
  if ("$out" -match $limitRe) { Write-Host "still limited (rc=$rc); back off 5m"; Start-Sleep -Seconds 300; continue }
  Write-Host "claude failed rc=$rc (not a limit); go to fallback"; break
}

if (-not $success -and (Get-Command codex -ErrorAction SilentlyContinue)) {
  Write-Host "--- codex fallback ($(Get-Date)) ---"
  & codex exec --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check $prompt 2>&1 | Out-Host
  if ($LASTEXITCODE -eq 0) { $success = $true; $engine = "codex" }
}

@{ finished_at=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); success=$success; engine=$engine; branch=$branch; log=$log } |
  ConvertTo-Json | Set-Content -Path (Join-Path $StateDir "last-run.json")
try { msg * "Claude resume-after-limit finished - success=$success, engine=$engine" } catch {}

Write-Host "=== done (success=$success, engine=$engine); unregistering task ==="
Stop-Transcript | Out-Null
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
