##############################################################################
# Bulds the Docker image and runs it locally, exposing app on https          #
##############################################################################

$DEFAULT_APPNAME = 'mywebapp'
$CERT_PATH = "/https/dev-cert.pfx"

# Prompt the user for the app name
$AppName = Read-Host -Prompt "App Name [$DEFAULT_APPNAME]"
If ([string]::IsNullOrWhiteSpace($AppName)){
    $AppName = $DEFAULT_APPNAME
}

# Fetch the pfx password set by ./scripts/2-create-dev-cert.ps1
$PfxPassword = [System.Environment]::GetEnvironmentVariable('dev-cert-pw', [System.EnvironmentVariableTarget]::User)

# If the pfx password is null, then prompt the user for it
#If($null -eq $PfxPassword){
#    $PfxPassword = Read-Host -Prompt 'Enter your dev cert password'
#}

# Using $PSScriptRoot so we can find the Dockerfile relative to this script location, not where we are running it
docker build -t $AppName "$PSScriptRoot/../"
docker run --rm -it -p 8000:80 -p 8001:443 -e ASPNETCORE_URLS="https://+;http://+" -e ASPNETCORE_HTTPS_PORT=8001 -e ASPNETCORE_Kestrel__Certificates__Default__Password=$PfxPassword -e "ASPNETCORE_Kestrel__Certificates__Default__Path=$CERT_PATH" -v $env:USERPROFILE\.aspnet\https:/https/ $AppName

Start-Process https://localhost:8001/
