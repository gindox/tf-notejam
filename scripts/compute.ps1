
param(
    [Parameter(Mandatory = $True)]
    [string]
    $adminpass,

    [Parameter(Mandatory = $True)]
    [string]
    $instrumentationkey,

    [Parameter(Mandatory = $True)]
    [String]
    $domainName,

    [parameter(Mandatory = $True)]
    [String]
    $netBIOSName,

    [parameter(Mandatory = $True)]
    [String]
    $dockerPackageURL

)

$cmd = 'docker run -d -p 80:3000 -e APPINSIGHTS_KEY=' + $instrumentationkey + ' --restart always ' + $dockerPackageURL + ';  
Unregister-ScheduledTask -TaskName "dockerquickrun"  -ErrorAction SilentlyContinue -Confirm:$false;
rm -Force C:\Windows\dockerquickrun.ps1
' 
$cmd | Out-File "C:\Windows\dockerquickrun.ps1"


$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-File "C:\Windows\dockerquickrun.ps1"'
$trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay 00:00:30
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8
$principal = New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
$definition = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description "startup"
Register-ScheduledTask -TaskName "dockerquickrun" -InputObject $definition



$un = $netBIOSName + "\localadmin"
$pass = ConvertTo-SecureString -String $adminpass -AsPlainText -Force
$cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $un, $pass

Add-Computer -DomainName $domainName -Credential $cred -Restart -Force

