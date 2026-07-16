# Input bindings are passed in via param block.
param($Timer)

# Add all your Azure non-Production Subscriptions Ids below
# TechnipFMC-Global-C3-Production #
# TechnipFMC-Europe-non-Production #
# TechnipFMC-Global-EnterpriseApps-NonProd #
# TechnipFMC-Global-C0-Non-Production #
# TechnipFMC-Global-C1-Non-Production #
# TechnipFMC-Global-C2-Non-Production #
# TechnipFMC-Global-C3-Non-Production #

$subscriptionids = @"
[
"b5a4a6cc-efda-4640-9c1f-4290a871e43f",
"413524eb-1202-4d95-8e6c-9cfd9b0c1977",
"d2fe1e92-947e-4d1a-8845-864f512dd5a0",
"0115ea9c-e7b0-4142-a1d6-b670c9faf89f",
"efe879c5-0967-443a-9893-8708c9974f44",
"f7656649-21e8-4385-b1c7-7ff31de83fb2",
"1164a610-3045-4625-8105-8fce2ec53417"
]
"@ | ConvertFrom-Json

$currentUTCtime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,"UTC")

foreach ($subscriptionid in $subscriptionids) {
# Selecting Azure Subscription
Set-AzContext -SubscriptionId $SubscriptionID | Out-Null

$CurrentSub = (Get-AzContext).Subscription.Id
If ($CurrentSub -ne $SubscriptionID) {
Throw "Could not switch to SubscriptionID: $SubscriptionID"
}

$vms = Get-AzVM -Status | Where-Object {($_.tags.UTCTimeShutdown -ne $null) -and ($_.tags.UTCTimeStart -ne $null) -and ($_.tags.SundayPatching -ne $null)}

$now = $currentUTCtime

foreach ($vm in $vms) {

if (($vm.PowerState -eq 'VM running') -and ($currentUTCtime.dayofweek.value__ -in 1..6) -and ($now -gt $(get-date $($vm.tags.UTCTimeShutdown))) -and ($now.AddMinutes(-3) -lt $(get-date $($vm.tags.UTCTimeShutdown)))) {
Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Confirm:$false -NoWait -Force
Write-Warning "Stop VM [1..6] - $($vm.Name)"
}

elseif (($vm.PowerState -eq 'VM running') -and ($currentUTCtime.dayofweek.value__ -eq 0) -and ($vm.tags.SundayPatching -eq 'On') -and ($now -gt $(get-date $($vm.tags.UTCTimeShutdown))) ) {
Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Confirm:$false -NoWait -Force
Write-Warning "Stop VM [0] - $($vm.Name)"
}

elseif (($vm.PowerState -eq 'VM deallocated') -and ($currentUTCtime.dayofweek.value__ -in 1..6) -and ($now -gt $(get-date $($vm.tags.UTCTimeStart))) -and ($now -lt $(get-date $($vm.tags.UTCTimeShutdown))) ) {
Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -NoWait
Write-Warning "Start VM [1..6] - $($vm.Name)"
}

elseif (($vm.PowerState -eq 'VM deallocated') -and ($currentUTCtime.dayofweek.value__ -eq 0) -and ($vm.tags.SundayPatching -eq 'On') -and ($now -gt $(get-date $($vm.tags.UTCTimeStart))) -and ($now -lt $(get-date $($vm.tags.UTCTimeShutdown))) ) {
Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -NoWait
Write-Warning "Start VM [0] - $($vm.Name)"
}

}
}