$GH_RUNNER_VERSION=$args[0]
$TARGETPLATFORM=$args[1]

$TARGET_ARCH="x64"
if ($TARGETPLATFORM -eq "linux/arm/v7") { 
    $TARGET_ARCH="arm"
}
elseif ($TARGETPLATFORM -eq "linux/arm64") {
    $TARGET_ARCH="arm64"
}

# managing additional packages to install
if ($TARGET_ARCH -eq "x64") {
  if (Test-Path Env:ADDITIONAL_PACKAGES) {
  #if (![String]::IsNullOrWhiteSpace($ADDITIONAL_PACKAGES)) {
      $TO_BE_INSTALLED=${Env:ADDITIONAL_PACKAGES} -replace(","," ")
      echo "Installing additional packages: ${TO_BE_INSTALLED}"
      scoop install ${TO_BE_INSTALLED}
  }
}

#if ((Test-Path "actions.zip") -eq $false) {
if (-not (Test-Path "actions.zip")) {
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-win-${TARGET_ARCH}-${GH_RUNNER_VERSION}.zip" -OutFile "actions.zip"
    Expand-Archive -Path "actions.zip" -DestinationPath "/actions-runner" -Force
    Remove-Item -Path "actions.zip" -Force
    mkdir /_work
}
