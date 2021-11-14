$Env:RUNNER_ALLOW_RUNASROOT = 1
$Env:Path += ";c:\actions-runner"

# encrypt access token
if (Test-Path Env:ACCESS_TOKEN) { 
    ${Env:ACCESS_TOKEN} | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "c:\\.PAT"
    Remove-Item Env:ACCESS_TOKEN
}

# managing additional packages to install
if (Test-Path Env:ADDITIONAL_PACKAGES) {
    $TO_BE_INSTALLED=${Env:ADDITIONAL_PACKAGES} -replace(","," ")
    echo "Installing additional packages: ${TO_BE_INSTALLED}"
    scoop install ${TO_BE_INSTALLED}
}

function deregister_runner {
  Write-Host "Caught SIGTERM. Deregistering runner"
  if (Test-Path "c:\\.PAT") {
    $_TOKEN = &"c:\\token.ps1"
    $RUNNER_TOKEN=$(${_TOKEN} | ConvertFrom-Json | Select token).token
  }
  else {
    Write-Error "error: missing ACCESS_TOKEN environment variable"
    exit 1
  }
  ./config.cmd remove --token "${RUNNER_TOKEN}"
  Clear-Variable -Name "RUNNER_TOKEN"
}

$_DISABLE_AUTOMATIC_DEREGISTRATION="$(if (Test-Path Env:DISABLE_AUTOMATIC_DEREGISTRATION) { ${Env:DISABLE_AUTOMATIC_DEREGISTRATION} } else { $false })"
$_RUNNER_NAME_PREFIX="$(if (Test-Path Env:RUNNER_NAME_PREFIX) { ${Env:RUNNER_NAME_PREFIX} } else { 'github-runner' })"
$_RUNNER_NAME       ="$(if (Test-Path Env:RUNNER_NAME)        { ${Env:RUNNER_NAME} }        else { "${_RUNNER_NAME_PREFIX}$( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 8 | % {[char]$_}) )" })"
$_RUNNER_WORKDIR    ="$(if (Test-Path Env:RUNNER_WORKDIR)     { ${Env:RUNNER_WORKDIR} }     else { '_work' })"
$_LABELS            ="$(if (Test-Path Env:RUNNER_WORKDIR)     { ${Env:LABELS} }             else { 'default' })"
$_RUNNER_GROUP      ="$(if (Test-Path Env:RUNNER_GROUP)       { ${Env:RUNNER_GROUP} }       else { 'Default' })"
$_GITHUB_HOST       ="$(if (Test-Path Env:GITHUB_HOST)        { ${Env:GITHUB_HOST} }        else { 'github.com' })"


# ensure backwards compatibility
if (-not (Test-Path Env:RUNNER_SCOPE)) {
  if (${Env:ORG_RUNNER} -eq $true) {
    Write-Host 'ORG_RUNNER is now deprecated. Please use RUNNER_SCOPE="org" instead.'
    $Env:RUNNER_SCOPE="org"
  }
  else {
    $Env:RUNNER_SCOPE="repo"
  }    
}

$RUNNER_SCOPE=${Env:RUNNER_SCOPE}.ToLower() # to lowercase

switch -Wildcard ( "${RUNNER_SCOPE}" )
{
    "org*"  {  if (-not (Test-Path Env:ORG_NAME)) { Write-Error "error: ORG_NAME required for org runners"; exit 1 }
              $_SHORT_URL="https://${_GITHUB_HOST}/${Env:ORG_NAME}"
              $RUNNER_SCOPE="org" 
            }
    "ent*"  {  if (-not (Test-Path Env:ENTERPRISE_NAME)) { Write-Error "error: ENTERPRISE_NAME required for enterprise runners"; exit 1 }
              $_SHORT_URL="https://${_GITHUB_HOST}/enterprises/${Env:ENTERPRISE_NAME}"
              $RUNNER_SCOPE="enterprise" 
            }
    Default {  if (-not (Test-Path Env:REPO_URL)) { Write-Error "error: REPO_URL required for repo runners"; exit 1 }
              $_SHORT_URL=${Env:REPO_URL}
              $RUNNER_SCOPE="repo"
            }
}

function configure_runner {
  if (Test-Path "c:\\.PAT") {
    $_TOKEN = &"c:\\token.ps1"
    $RUNNER_TOKEN=$(${_TOKEN} | ConvertFrom-Json | Select token).token
  }
  else {
    Write-Error "error: missing ACCESS_TOKEN environment variable"
    exit 1
  }

  Write-Host "Configuring"
  ./config.cmd `
      --url "${_SHORT_URL}" `
      --token "${RUNNER_TOKEN}" `
      --name "${_RUNNER_NAME}" `
      --work "${_RUNNER_WORKDIR}" `
      --labels "${_LABELS}" `
      --runnergroup "${_RUNNER_GROUP}" `
      --unattended `
      --replace
  Clear-Variable -Name "RUNNER_TOKEN"
}

# Opt into runner reusage because a value was given
if (Test-Path Env:CONFIGURED_ACTIONS_RUNNER_FILES_DIR) {
  Write-Host "Runner reusage is enabled"

  # directory exists, copy the data
  if (Test-Path -Path ${Env:CONFIGURED_ACTIONS_RUNNER_FILES_DIR}) { 
    Write-Host "Copying previous data"
    cp -p -r "${Env:CONFIGURED_ACTIONS_RUNNER_FILES_DIR}/." "/actions-runner"
  }
  
  if (Test-Path -Path "/actions-runner/.runner") { 
    Write-Host "The runner has already been configured"
  }
  else {
    configure_runner
  }
}
else {
  Write-Host "Runner reusage is disabled"
  configure_runner
}

if (Test-Path Env:CONFIGURED_ACTIONS_RUNNER_FILES_DIR) {
  Write-Host "Reusage is enabled. Storing data to ${Env:CONFIGURED_ACTIONS_RUNNER_FILES_DIR}"
  # Quoting (even with double-quotes) the regexp brokes the copying
  cp -p -r "/actions-runner/_diag" /actions-runner/.[^.]* "${Env:CONFIGURED_ACTIONS_RUNNER_FILES_DIR}"
}

if (${_DISABLE_AUTOMATIC_DEREGISTRATION} -eq $false )
{
    trap {deregister_runner}
}

# Container's command (CMD) execution
#"$@"
./run.cmd