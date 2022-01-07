
param(
    [Parameter(Mandatory = $True)]
    [string]
    $adminpass
)

#Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#choco install firefox conemu 7zip -y


Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools

$sadminpass = $adminpass | ConvertTo-SecureString -AsPlainText -Force


Import-Module ADDSDeployment
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\windows\NTDS" -DomainMode "WinThreshold" -DomainName "notejam.local" -DomainNetbiosName "NOTEJAM" -ForestMode "WinThreshold" -InstallDns:$true -LogPath "C:\windows\NTDS" -NoRebootOnCompletion:$false -SafeModeAdministratorPassword $sadminpass -SysvolPath "C:\windows\SYSVOL" -Force:$true -Confirm:$false
