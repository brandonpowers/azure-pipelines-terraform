##############################################################################
# Configures Terraform state management in Azure Blob Storage                #
##############################################################################

$DEFAULT_APPNAME = 'mywebapp'
$DEFAULT_ENVNAME = 'dev'
$DEFAULT_LOCATION = 'eastus'
$DEFAULT_DEPARTMENT = 'IT'
$DEFAULT_PREFIX = 'company'
$DEFAULT_CONTAINER_REGISTRY = '[myregistry].azurecr.io'

Write-Host "***************************************************"
Write-Host "This script creates an Azure Resource Group for this app environment, configures CI/CD permissions for Pipelines, and sets up Terraform state management in Blob storage."
Write-Host
$Continue = Read-Host -Prompt "Would you like to continue? (y/n)"

If(-Not $Continue.StartsWith('y')) {
    exit
}

# Get the available subscriptions for the logged in user.
Write-Host "Checking Azure login status..." -BackgroundColor Green -ForegroundColor Black
$SubscriptionList = az account show | ConvertFrom-Json

# Make sure we're logged in to Azure
If($null -eq $SubscriptionList){
    Write-Host "Logging into Azure..." -BackgroundColor Green -ForegroundColor Black
    $SubscriptionList = (az login | ConvertFrom-Json)
}

# Print it out as a table so it's easier to read.
Write-Host "Here are your subscriptions:" -BackgroundColor Green -ForegroundColor Black
$SubscriptionList | Format-Table -AutoSize

# Get the default subscription
$DEFAULT_SUBSCRIPTION = ($SubscriptionList | Where-Object {$_.isDefault -eq 'true'}).id
# Prompt the user for the Subscription to use
Write-Host -BackgroundColor Blue -ForegroundColor White
$SubscriptionId = Read-Host -Prompt "Subscription Id [$DEFAULT_SUBSCRIPTION]"
If ([string]::IsNullOrWhiteSpace($SubscriptionId)){
    $SubscriptionId = $DEFAULT_SUBSCRIPTION;
}

# Prompt the user for the app name
$AppName = Read-Host -Prompt "App Name [$DEFAULT_APPNAME]"
If ([string]::IsNullOrWhiteSpace($AppName)){
    $AppName = $DEFAULT_APPNAME
}

# Prompt the user for the environment name
$EnvName = Read-Host -Prompt "Env Name [$DEFAULT_ENVNAME]"
If ([string]::IsNullOrWhiteSpace($EnvName)){
    $EnvName = $DEFAULT_ENVNAME
}

# Prompt the user for the Azure location to use
$Location = Read-Host -Prompt "Location [$DEFAULT_LOCATION]"
If ([string]::IsNullOrWhiteSpace($Location)){
    $Location = $DEFAULT_LOCATION
}

$Department = Read-Host -Prompt "Department [$DEFAULT_DEPARTMENT]"
if([string]::IsNullOrWhiteSpace($Department)){
    $Department = $DEFAULT_DEPARTMENT
}

# Prompt the user for the Azure location to use
$StoragePrefix = Read-Host -Prompt "Storage Account Prefix [$DEFAULT_PREFIX]"
If ([string]::IsNullOrWhiteSpace($StoragePrefix)){
    $StoragePrefix = $DEFAULT_PREFIX
}

$ContainerRegistry = Read-Host -Prompt "Container Registry [$DEFAULT_CONTAINER_REGISTRY]"
if([string]::IsNullOrWhiteSpace($ContainerRegistry)){
    $ContainerRegistry = $DEFAULT_CONTAINER_REGISTRY
}

##############################################################################
# The naming conventions used below are mirrored in the azure-pipelines.yml  #
# so that we don't have to pass a bunch of resource names around as variables#
##############################################################################

# Create our azure resource names from the user variables
$RESOURCE_GROUP_NAME = "$AppName-$EnvName"
# Storage account names can only be lowercase letters and numbers
# We prefix these with department because they have to be unique across all of azure
$STORAGE_ACCOUNT_NAME = ("$StoragePrefix$AppName$EnvName").ToLower()
# Container name for the Terraform State
$CONTAINER_NAME = "$AppName-$EnvName-tfstate"
# Since our blob storage is encrypted, we'll save the key in a Key Vault
$KEYVAULT_NAME = "$AppName-$EnvName"
$DB_ADMIN_PW = [System.Web.Security.Membership]::GeneratePassword(24,5)

Write-Host "We need to create a ARM Service Principal for this pipeline and subscription if there isn't one."  -BackgroundColor Green -ForegroundColor Black
Write-Host "Browse to 'DevOps->[Project]->Project Settings->Service Connections' and look for a connection to this subscription." -BackgroundColor Green -ForegroundColor Black
Write-Host "If there isn't one, create a new connection of type 'Azure Resource Manager'." -BackgroundColor Green -ForegroundColor Black
Write-Host "Then select it and click Manage Service Principal, then copy the Application (Client) ID and paste it below." -BackgroundColor Green -ForegroundColor Black
$AppClientId = Read-Host -Prompt "AD Application (client) Id"

# Create resource group
Write-Host "Creating Resource Group: $RESOURCE_GROUP_NAME" -BackgroundColor Green -ForegroundColor Black
az group create --name $RESOURCE_GROUP_NAME --location $Location --tags app=$AppName env=$EnvName department=$Department

# Create storage account
Write-Host "Creating Storage Account: $STORAGE_ACCOUNT_NAME" -BackgroundColor Green -ForegroundColor Black
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --kind StorageV2 --sku Standard_LRS --encryption-services blob --tags app=$AppName env=$EnvName department=$Department

# Get storage account key
Write-Host "Getting Storage Account Key." -BackgroundColor Green -ForegroundColor Black
$STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create storage container for the Terraform state
Write-Host "Creating Storage Container: $CONTAINER_NAME" -BackgroundColor Green -ForegroundColor Black
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_ACCOUNT_KEY

# Create an Azure Key Vault
Write-Host "Creating Key Vault: $KEYVAULT_NAME" -BackgroundColor Green -ForegroundColor Black
az keyvault create -g $RESOURCE_GROUP_NAME -l $LOCATION --name $KEYVAULT_NAME

# Store the Terraform State storage key into Key Vault
Write-Host "Saving the Terraform state storage key in the Key Vault." -BackgroundColor Green -ForegroundColor Black
az keyvault secret set --name "TfStateKey" --value $STORAGE_ACCOUNT_KEY --vault-name $KEYVAULT_NAME --tags app=$AppName env=$EnvName department=$Department

# Save the db admin password in our Key Vault
Write-Host "Saving the db admin password in the Key Vault." -BackgroundColor Green -ForegroundColor Black
az keyvault secret set --name "DbAdminPw" --value "`"${DB_ADMIN_PW}`"" --vault-name $KEYVAULT_NAME --tags app=$AppName env=$EnvName department=$Department

# Setting permissions so that the Pipeline can access this Key Vault
If (-Not [string]::IsNullOrWhiteSpace($AppClientId)){
    Write-Host "Permissioning the pipeline to access this Key Vault: $AppClientId" -BackgroundColor Green -ForegroundColor Black
    az keyvault set-policy -n $KEYVAULT_NAME --spn $AppClientId --secret-permissions get list
}

# This format is used by Terraform's .tfvars files if you'd like to create one, but we're using env vars and key vault instead.
$TfVarsFile = "app_name = `"$AppName`"
env_name = `"$EnvName`"
location = `"$Location`"
department = `"$Department`"
storagePrefix = `"$StoragePrefix`"
container_registry = `"$ContainerRegistry`"
resource_group = `"$RESOURCE_GROUP_NAME`"
storage_account_name = `"$STORAGE_ACCOUNT_NAME`"
storage_account_key = `"$STORAGE_ACCOUNT_KEY`"
tf_container_name = `"$CONTAINER_NAME`"
db_admin_username = `"${AppName}${EnvName}admin`" 
db_admin_password = `"$DB_ADMIN_PW`"" 

Write-Host
Write-Host "These are the variables configured for Terraform, they should match in the pipeline and terraform configs"
Write-Host
Write-Host $TfVarsFile -BackgroundColor Black -ForegroundColor Green

If ([string]::IsNullOrWhiteSpace($AppClientId)){
    Write-Host
    Write-Warning "Locate the app client id at Azure->Active Directory->App Registrations and run this command so that the pipeline can access the key vault keys."
    Write-Host "az keyvault set-policy -n $KEYVAULT_NAME --spn [app-client-id-guid] --secret-permissions get list" -BackgroundColor Black -ForegroundColor Green
}
Write-Host "***"
Write-Host
