<# Windows - cancel a pending resume-after-limit run. #>
$TaskName = "ClaudeResumeAfterLimit"
$StateDir = Join-Path $env:USERPROFILE ".claude\resume-after-limit"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Force (Join-Path $StateDir "armed.json") -ErrorAction SilentlyContinue
Write-Host "Disarmed (Windows)."
