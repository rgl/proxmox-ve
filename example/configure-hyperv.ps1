param(
    [string]$vmName
)

$switchName = 'proxmox'

$vmNetworkAdapter = @(Get-VMNetworkAdapter $vmName | Where-Object {$_.SwitchName -eq $switchName})
if (!$vmNetworkAdapter) {
    Write-Host "Connecting the VM to the $switchName switch..."
    Add-VMNetworkAdapter $vmName -SwitchName $switchName
}
