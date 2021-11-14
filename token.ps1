$_GITHUB_HOST="$(if (Test-Path Env:GITHUB_HOST) { ${Env:GITHUB_HOST} } else { 'github.com' })"

# If URL is not github.com then use the enterprise api endpoint
$URI="$(if ( $_GITHUB_HOST -eq "github.com" ) { "https://api.${_GITHUB_HOST}" } else { "https://${_GITHUB_HOST}/api/v3" })"

$API_VERSION="v3"
#$API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
#$AUTH_HEADER="Authorization: token ${ACCESS_TOKEN}"

switch -Wildcard ( "${Env:RUNNER_SCOPE}" )
{
    "org*" { $_FULL_URL="${URI}/orgs/${Env:ORG_NAME}/actions/runners/registration-token" }
    "ent*" { $_FULL_URL="${URI}/enterprises/${Env:ENTERPRISE_NAME}/actions/runners/registration-token" }
    #default { 
    #    $_PROTO="https://"
    #    # shellcheck disable=SC2116
    #    $_URL="$(echo "${REPO_URL/$_PROTO/}")"
    #    $_PATH="$(echo "${_URL}" | grep / | cut -d/ -f2-)"
    #    $_ACCOUNT="$(echo "${_PATH}" | cut -d/ -f1)"
    #    $_REPO="$(echo "${_PATH}" | cut -d/ -f2)"
    #    $_FULL_URL="${URI}/repos/${_ACCOUNT}/${_REPO}/actions/runners/registration-token" }
}

$encrypted_pat=Get-Content "c:\\.PAT" | ConvertTo-SecureString
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($encrypted_pat)
$clear_pat = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr)
Clear-Variable -Name "ptr"
Clear-Variable -Name "encrypted_pat"

$RUNNER_TOKEN = (Invoke-WebRequest -UseBasicParsing -Headers @{ "Accept" = "application/vnd.github.${API_VERSION}+json"; "Authorization" = "token $clear_pat" } `
                -Method POST -Uri "${_FULL_URL}" |
                ConvertFrom-Json | Select token).token

Clear-Variable -Name "clear_pat"
eho @{token="${RUNNER_TOKEN}";full_url="${_FULL_URL}"} | ConvertTo-Json -Compress