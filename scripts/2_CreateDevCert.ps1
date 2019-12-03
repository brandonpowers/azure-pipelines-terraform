##############################################################################
# Creates a dev cert so docker can expose the app on https on your machine   #
##############################################################################

$CERT_PATH = "$env:USERPROFILE\.aspnet\https\dev-cert.pfx"
$DEFAULT_PW = "12345"

Write-Host "***************************************************"
Write-Host "This script creates a self signed certificate and installs it so that docker can expose https on the localhost."
Write-Host
$Continue = Read-Host -Prompt "Would you like to continue? (y/n)"

If(-Not $Continue.StartsWith('y')) {
    exit
}

# There can only be one dev cert on a machine
Write-Host "Only one dev cert can be installed at a time, I'm going to remove any existing ones."
dotnet dev-certs https --clean

# Prompt the user for a certificate password
Write-Host
Write-Host "Kestral gets angry if your dev cert doesn't have a password." -ForegroundColor Green
Write-Host "I'm going to save this password in your sys user env variables so you don't have to remember it." -ForegroundColor Green
Write-Host "If it's ever lost, nothing bad happens just run me again and generate a new cert." -ForegroundColor Green
Write-Host
$PfxPassword = Read-Host -Prompt "Enter a certificate password [12345]"
If ([string]::IsNullOrWhiteSpace($PfxPassword)){
    $PfxPassword = $DEFAULT_PW
}

Write-Host ("Generating dev certificate...")

# Generate the cert
dotnet dev-certs https -ep $CERT_PATH -p $PfxPassword
# Add it to the local dev store
dotnet dev-certs https --trust

# Set the app name and cert password as environment variables so we don't have to type them in all the time
[System.Environment]::SetEnvironmentVariable("dev-cert-pw", $PfxPassword, [System.EnvironmentVariableTarget]::User)

Write-Host ("Created dev certificate at $CERT_PATH with password `"$PfxPassword`"")

Write-Warning "Powershell must be restarted for this cert to work."
