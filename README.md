# Notejam Terraform Demo

Install required tools:
```
choco install azure-cli terraform -y
```
and suthenticate as following:
```
az login
az account set --subscription "__NAMEOFSUBSCRIPTION__"
```


Then simply run 
```
.\deploy.ps1
```