param(
    [string]$vmId
)

$switchName = 'proxmox'

$vm = Get-VM -Id $vmId

$vmNetworkAdapter = @(Get-VMNetworkAdapter -VM $vm | Where-Object {$_.SwitchName -eq $switchName})
if (!$vmNetworkAdapter) {
    Write-Host "Connecting the VM to the $switchName switch..."
    Add-VMNetworkAdapter -VM $vm -SwitchName $switchName
}
