param(
    [string]$vmId
)

$switchName = 'proxmox'

$vm = Hyper-V\Get-VM -Id $vmId

$vmNetworkAdapter = @(Hyper-V\Get-VMNetworkAdapter -VM $vm | Where-Object {$_.SwitchName -eq $switchName})
if (!$vmNetworkAdapter) {
    Write-Host "Connecting the VM to the $switchName switch..."
    Hyper-V\Add-VMNetworkAdapter -VM $vm -SwitchName $switchName
}
