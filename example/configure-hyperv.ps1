param(
    [string]$vmId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Host "ERROR: $_"
    Write-Host (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Host (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Exit 1
}

$switchName = 'proxmox'

$vm = Hyper-V\Get-VM -Id $vmId

# add the second network interface.
# NB the first network adapter is the vagrant management interface
#    which we do not modify.
$networkAdapters = @(Hyper-V\Get-VMNetworkAdapter -VM $vm | Select-Object -Skip 1)
if ($networkAdapters.Count -lt 1) {
    Write-Host "Adding the second network interface..."
    Hyper-V\Add-VMNetworkAdapter -VM $vm -SwitchName $switchName
}
