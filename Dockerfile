# hadolint ignore=DL3007
# escape=

FROM mcr.microsoft.com/windows/servercore:ltsc2019
LABEL maintainer="mario.alesci@gmail.com"

ARG $TARGETPLATFORM
SHELL [ "powershell" ]

WORKDIR /actions-runner
COPY install_actions.ps1 /actions-runner
#COPY runner-setup.ps1 C:/runner-setup.ps1

RUN "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; iwr -useb get.scoop.sh | iex; scoop install git"

RUN $GH_RUNNER_VERSION=(Invoke-WebRequest -Uri "https://api.github.com/repos/actions/runner/releases/latest" -UseBasicParsing | ConvertFrom-Json | Select tag_name).tag_name.SubString(1); `
  ; /actions-runner/install_actions.ps1 ${GH_RUNNER_VERSION} ${TARGETPLATFORM} `
  ; Remove-Item -Path "/actions-runner/install_actions.ps1" -Force

COPY token.ps1 entrypoint.ps1 C:/
ENTRYPOINT ["/entrypoint.ps1"]

##CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]
