$GH_RUNNER_VERSION=$args[0]
$TARGETPLATFORM=$args[1]

$env:TARGET_ARCH="x64"
if ($TARGETPLATFORM -eq "linux/arm/v7")
{ 
    $env:TARGET_ARCH="arm"
}
elseif ($TARGETPLATFORM -eq "linux/arm64")
{
    $env:TARGET_ARCH="arm64"
}

# managing additional packages to install
if ($TARGET_ARCH -eq "x64")
{
  if (![String]::IsNullOrWhiteSpace($ADDITIONAL_PACKAGES))
  {
      $TO_BE_INSTALLED=${ADDITIONAL_PACKAGES} -replace(","," ")
      echo "Installing additional packages: ${TO_BE_INSTALLED}"
      scoop install ${TO_BE_INSTALLED}
  }
}

if ((Test-Path "actions.zip") -eq $false) 
{
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-win-${TARGET_ARCH}-${GH_RUNNER_VERSION}.zip" -OutFile "actions.zip"
    Expand-Archive -Path "actions.zip"  -DestinationPath actions-runner -Force
    Remove-Item -Path "actions.zip" -Force
    mkdir /_work
}
