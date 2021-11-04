$env:RUNNER_ALLOW_RUNASROOT = 1
$env:Path += ";C:\actions-runner"

# Un-export these, so that they must be passed explicitly to the environment of
# any command that needs them.  This may help prevent leaks.
#TBD
#export -n ACCESS_TOKEN
#export -n RUNNER_TOKEN


function deregister_runner {
  echo "Caught SIGTERM. Deregistering runner"
  if ([String]::IsNullOrWhiteSpace($ACCESS_TOKEN)) 
  {
    $_TOKEN = &".\token.ps1"
    $RUNNER_TOKEN=$(${_TOKEN} | ConvertFrom-Json | Select token).token
  }
  ./config.cmd remove --token "${RUNNER_TOKEN}"
}

if ( $DISABLE_AUTOMATIC_DEREGISTRATION -eq $null ) { $DISABLE_AUTOMATIC_DEREGISTRATION=$false }
$_DISABLE_AUTOMATIC_DEREGISTRATION=${DISABLE_AUTOMATIC_DEREGISTRATION}

if ([String]::IsNullOrWhiteSpace($RUNNER_NAME_PREFIX)) { $RUNNER_NAME_PREFIX="github-runner" }

if ([String]::IsNullOrWhiteSpace($RUNNER_NAME)) { $RUNNER_NAME="${RUNNER_NAME_PREFIX}-$( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 8 | % {[char]$_}) )" }
$_RUNNER_NAME=${RUNNER_NAME}

if ([String]::IsNullOrWhiteSpace($RUNNER_WORKDIR)) { $RUNNER_WORKDIR="/_work" }
$_RUNNER_WORKDIR=${RUNNER_WORKDIR}

if ([String]::IsNullOrWhiteSpace($LABELS)) { $LABELS="/default" }
$_LABELS=${LABELS}

if ([String]::IsNullOrWhiteSpace($RUNNER_GROUP)) { $RUNNER_GROUP="Default" }
$_RUNNER_GROUP=${RUNNER_GROUP}

if ([String]::IsNullOrWhiteSpace($GITHUB_HOST)) { $GITHUB_HOST="github.com" }
$_GITHUB_HOST=${GITHUB_HOST}

# ensure backwards compatibility
if ([String]::IsNullOrWhiteSpace($RUNNER_SCOPE))
{
  if (${ORG_RUNNER} -eq $true)
  {
    echo 'ORG_RUNNER is now deprecated. Please use RUNNER_SCOPE="org" instead.'
    $env:RUNNER_SCOPE="org"
  }
  else
  {
    $env:RUNNER_SCOPE="repo"
  }    
}

$RUNNER_SCOPE=${RUNNER_SCOPE}.ToLower() # to lowercase

switch -Wildcard ( "${RUNNER_SCOPE}" )
{
    "org*"  {  if ([String]::IsNullOrWhiteSpace($ORG_NAME)) { echo "ORG_NAME required for org runners"; exit 1 }
              $_SHORT_URL="https://${_GITHUB_HOST}/${ORG_NAME}"
              $RUNNER_SCOPE="org" 
            }
    "ent*"  {  if ([String]::IsNullOrWhiteSpace($ENTERPRISE_NAME)) { echo "ENTERPRISE_NAME required for enterprise runners"; exit 1 }
              $_SHORT_URL="https://${_GITHUB_HOST}/enterprises/${ENTERPRISE_NAME}"
              $RUNNER_SCOPE="enterprise" 
            }
    Default {  if ([String]::IsNullOrWhiteSpace($REPO_URL)) { echo "REPO_URL required for repo runners"; exit 1 }
              $_SHORT_URL=${REPO_URL}
              $RUNNER_SCOPE="repo"
            }
}

function configure_runner {
  if ([String]::IsNullOrWhiteSpace($ACCESS_TOKEN)) 
  {
    $_TOKEN = &".\token.ps1"
    $RUNNER_TOKEN=$(${_TOKEN} | ConvertFrom-Json | Select token).token
  }
  echo "Configuring"
  ./config.cmd \
      --url "${_SHORT_URL}" \
      --token "${RUNNER_TOKEN}" \
      --name "${_RUNNER_NAME}" \
      --work "${_RUNNER_WORKDIR}" \
      --labels "${_LABELS}" \
      --runnergroup "${_RUNNER_GROUP}" \
      --unattended \
      --replace
}

# Opt into runner reusage because a value was given
if (![String]::IsNullOrWhiteSpace($CONFIGURED_ACTIONS_RUNNER_FILES_DIR))
{ 
  echo "Runner reusage is enabled"

  # directory exists, copy the data
  if (Test-Path -Path ${CONFIGURED_ACTIONS_RUNNER_FILES_DIR})
  { 
    echo "Copying previous data"
    cp -p -r "${CONFIGURED_ACTIONS_RUNNER_FILES_DIR}/." "/actions-runner"
  }
  
  if (Test-Path -Path "/actions-runner/.runner")
  { 
    echo "The runner has already been configured"
  }
  else
  {
    configure_runner
  }
else
  echo "Runner reusage is disabled"
  configure_runner
}

if (![String]::IsNullOrWhiteSpace($CONFIGURED_ACTIONS_RUNNER_FILES_DIR))
{ 
  echo "Reusage is enabled. Storing data to ${CONFIGURED_ACTIONS_RUNNER_FILES_DIR}"
  # Quoting (even with double-quotes) the regexp brokes the copying
  #cp -p -r "/actions-runner/_diag" "/actions-runner/svc.sh" /actions-runner/.[^.]* "${CONFIGURED_ACTIONS_RUNNER_FILES_DIR}"
  cp -p -r "/actions-runner/_diag" /actions-runner/.[^.]* "${CONFIGURED_ACTIONS_RUNNER_FILES_DIR}"
}

if (${_DISABLE_AUTOMATIC_DEREGISTRATION} -eq $false )
{
    trap {deregister_runner} SIGINT SIGQUIT SIGTERM INT TERM QUIT
}

# Container's command (CMD) execution
"$@"
