
param(
    [Parameter(Mandatory = $True)]
    [string]
    $adminpass,

    [parameter(Mandatory = $True)]
    [String]
    $domainName,

    [parameter(Mandatory = $True)]
    [String]
    $netBIOSName
)


Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools

$sadminpass = $adminpass | ConvertTo-SecureString -AsPlainText -Force


Import-Module ADDSDeployment
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\windows\NTDS" -DomainMode "WinThreshold" -DomainName $domainName -DomainNetbiosName $netBIOSName -ForestMode "WinThreshold" -InstallDns:$true -LogPath "C:\windows\NTDS" -NoRebootOnCompletion:$false -SafeModeAdministratorPassword $sadminpass -SysvolPath "C:\windows\SYSVOL" -Force:$true -Confirm:$false
