$GH_RUNNER_VERSION=$args[0]
$TARGETPLATFORM=$args[1]

## TBD: remove linux arch
$TARGET_ARCH="x64"
if ($TARGETPLATFORM -eq "linux/arm/v7") { 
    $TARGET_ARCH="arm"
}
elseif ($TARGETPLATFORM -eq "linux/arm64") {
    $TARGET_ARCH="arm64"
}

if (-not (Test-Path "actions.zip")) {
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-win-${TARGET_ARCH}-${GH_RUNNER_VERSION}.zip" -OutFile "actions.zip"
    Expand-Archive -Path "actions.zip" -DestinationPath "/actions-runner" -Force
    Remove-Item -Path "actions.zip" -Force
    New-Item -Path "C:\" -Name "_work" -ItemType "directory"
}