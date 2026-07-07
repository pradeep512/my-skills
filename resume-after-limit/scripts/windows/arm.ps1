<#
  Windows - arm a one-shot Scheduled Task to resume after the 5h limit resets.
  Usage:
    pwsh scripts/windows/arm.ps1 -ProjectDir <dir> -Handoff <file> [-Model <m>] [-AtEpoch <n> | -InSeconds <n>]
  Reset time resolution: -AtEpoch > -InSeconds > cache (~/.claude/rate-limit-cache.json).
  NOTE: written but not yet verified on a live Windows box - sanity-check the first run.
#>
param(
  [Parameter(Mandatory=$true)][string]$ProjectDir,
  [Parameter(Mandatory=$true)][string]$Handoff,
  [string]$Model = "claude-opus-4-8",
  [long]$AtEpoch = 0,
  [int]$InSeconds = 0
)
$ErrorActionPreference = "Stop"
$TaskName = "ClaudeResumeAfterLimit"
$Buffer   = if ($env:RESUME_BUFFER_SECONDS) { [int]$env:RESUME_BUFFER_SECONDS } else { 150 }
$Here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateDir = Join-Path $env:USERPROFILE ".claude\resume-after-limit"
$Cache    = Join-Path $env:USERPROFILE ".claude\rate-limit-cache.json"
New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

$ProjectDir = (Resolve-Path $ProjectDir).Path
if (-not (Test-Path $Handoff)) { throw "handoff not found: $Handoff" }
$Handoff = (Resolve-Path $Handoff).Path

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
if ($AtEpoch -gt 0)        { $fire = $AtEpoch }
elseif ($InSeconds -gt 0)  { $fire = $now + $InSeconds }
elseif (Test-Path $Cache)  {
  $r = (Get-Content $Cache -Raw | ConvertFrom-Json).five_hour.resets_at
  if (-not $r) { throw "cache has no five_hour.resets_at; pass -AtEpoch or -InSeconds." }
  $fire = [long]$r + $Buffer
} else { throw "No reset time: no cache and no -AtEpoch/-InSeconds." }
if ($fire -le $now) { $fire = $now + 60 }
$fireDt = [DateTimeOffset]::FromUnixTimeSeconds($fire).LocalDateTime

$watch = Join-Path $Here "watch.ps1"
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
$argline = "-NoProfile -ExecutionPolicy Bypass -File `"$watch`" -ProjectDir `"$ProjectDir`" -Handoff `"$Handoff`" -Model `"$Model`""

$action   = New-ScheduledTaskAction -Execute $psExe -Argument $argline -WorkingDirectory $ProjectDir
$trigger  = New-ScheduledTaskTrigger -Once -At $fireDt
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Resume Claude work after 5h rate limit reset" | Out-Null

@{ os="windows"; armed_at=$now; fire_at=$fire; fire_human="$fireDt"; project_dir=$ProjectDir; handoff=$Handoff; model=$Model; task=$TaskName } |
  ConvertTo-Json | Set-Content -Path (Join-Path $StateDir "armed.json")
Write-Host "Armed (Windows/Task Scheduler). Fires: $fireDt  (epoch $fire)"
Write-Host "  project=$ProjectDir  handoff=$Handoff  model=$Model"
Write-Host "Disarm: pwsh `"$Here\disarm.ps1`""
