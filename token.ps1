if ([String]::IsNullOrWhiteSpace($GITHUB_HOST)) 
  { $_GITHUB_HOST="github.com" }
else
  { $_GITHUB_HOST=${GITHUB_HOST} }


# If URL is not github.com then use the enterprise api endpoint
if ( $_GITHUB_HOST -eq "github.com" )
  { $URI="https://api.${_GITHUB_HOST}" }
else
  { $URI="https://${_GITHUB_HOST}/api/v3" }


$API_VERSION="v3"
#$API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
#$AUTH_HEADER="Authorization: token ${ACCESS_TOKEN}"

switch -Wildcard ( "${RUNNER_SCOPE}" )
{
    "org*" { $_FULL_URL="${URI}/orgs/${ORG_NAME}/actions/runners/registration-token" }
    "ent*" { $_FULL_URL="${URI}/enterprises/${ENTERPRISE_NAME}/actions/runners/registration-token" }
    #default { 
    #    $_PROTO="https://"
    #    # shellcheck disable=SC2116
    #    $_URL="$(echo "${REPO_URL/$_PROTO/}")"
    #    $_PATH="$(echo "${_URL}" | grep / | cut -d/ -f2-)"
    #    $_ACCOUNT="$(echo "${_PATH}" | cut -d/ -f1)"
    #    $_REPO="$(echo "${_PATH}" | cut -d/ -f2)"
    #    $_FULL_URL="${URI}/repos/${_ACCOUNT}/${_REPO}/actions/runners/registration-token" }
}

$RUNNER_TOKEN = (Invoke-WebRequest -Headers @{ "Accept" = "application/vnd.github.${API_VERSION}+json"; "Authorization" = "token ${ACCESS_TOKEN}" } `
                -Method POST -Uri "${_FULL_URL}" |
                ConvertFrom-Json | Select token).token

echo @{token="${RUNNER_TOKEN}";full_url="${_FULL_URL}"} | ConvertTo-Json -Compress
