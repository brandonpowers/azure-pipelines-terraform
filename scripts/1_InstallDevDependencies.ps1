##############################################################################
# Installs the tools and dependencies needed for developer to run and debug  #
# this application and run with docker                                       #
##############################################################################
#Requires -RunAsAdministrator

Write-Host "***************************************************"
Write-Host "This script installs everything your machine needs for development on this project if they aren't already installed:"
Write-Host "    - Chocolatey"
Write-Host "    - Git cli & Poshgit"
Write-Host "    - Terraform"
Write-Host "    - Docker-Desktop"
Write-Host "    - Dotnet Core SDK"
Write-Host
$Continue = Read-Host -Prompt "Would you like to continue? (y/n)"

If(-Not $Continue.StartsWith('y')) {
    exit
}

# Function that tests if a command exists.
function Test-Command($cmdname){
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

$IsRestartRequired = $false

# Install Chocolatey
If (Test-Command -cmdname 'choco'){
    Write-Host "Chocolatey found!"
} Else {
    Write-Host "***************************************************"
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install Git and Poshgit
If (Test-Command -cmdname 'git'){
    Write-Host "Git found!"
} Else {
    Write-Host "***************************************************"
    Write-Host "Installing git and poshgit..."
    choco install git -y
    choco install poshgit -y
}

# Install Terraform
If(Test-Command -cmdname 'terraform'){
    Write-Host "Terraform found!"
} Else {
    Write-Host "***************************************************"
    Write-Host "Installing terraform..."
    choco install terraform -y
}

# Install Docker
If(Test-Command -cmdname 'docker'){
    Write-Host "Docker found!"
} Else {
    Write-Host "***************************************************"
    Write-Host "Installing docker-desktop..."
    choco install docker-desktop -y
    $IsRestartRequired = $true
}

# Check that Visual Studio is installed
If(Test-Command -cmdname 'dotnet'){
    Write-Host "Dotnet found!"
} Else {
    Write-Host "***************************************************"
    Write-Host "Installing Dotnet Core SDK..."
    choco install dotnetcore-sdk -y
    $IsRestartRequired = $true
}

# Refresh the powershell env so we can use our commands added to path
# This command comes with Chocolatey
Write-Host "Refreshing powershell environment variables..."
refreshenv

If($IsRestartRequired){
    Write-Host "***************************************************"
    Write-Host "Restart your computer. If prompted, enable Hyper-V."
    Write-Host "If Docker fails on startup, refer to the README.md "
    Write-Host "***************************************************"
}
