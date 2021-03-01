function Get-RandomString($length) {
    $characters = "abcdefghijklmnopqstuvwxyz1234567890"
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs = ""
    return [String]$characters[$random]
}

$rgName = "rg-tfstate$(Get-RandomString(12))"
$stname = "sttfstate$(Get-RandomString(12))"

az group create --location northeurope --name $rgName
az storage account create --name $stname --resource-group $rgName --kind BlobStorage --location northeurope --access-tier Hot --sku Standard_LRS
az storage container create --name "tfstate" --account-name $stname --auth-mode login

$mainTf = Join-Path -Path (Get-Item .).FullName -ChildPath "main.tf"
$conf = Get-Content $mainTf

$conf = $conf.Replace('#stname#', $stname)
$conf = $conf.Replace('#rgName#', $rgName)

$conf | Set-Content $mainTf


terraform init
terraform apply -auto-approve
