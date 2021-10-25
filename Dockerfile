# escape=`

#FROM mcr.microsoft.com/windows/servercore:2004
#FROM mcr.microsoft.com/windows/nanoserver:1803-amd64
FROM mcr.microsoft.com/windows/servercore:ltsc2019

LABEL org.opencontainers.image.source https://github.com/rajyraman/docker-github-self-hosted-runner
LABEL org.opencontainers.image.documentation https://github.com/rajyraman/docker-github-self-hosted-runner/README.md
LABEL org.opencontainers.image.authors Natraj Yegnaraman
LABEL org.opencontainers.image.title Self Hosted GitHub Runner on Docker
LABEL org.opencontainers.image.description This image helps you to develop debug GitHub Workflow by running it in a self-hosted runner on Docker

ADD runner-setup.ps1 C:/runner-setup.ps1

WORKDIR /actions-runner

SHELL [ "powershell" ]

RUN "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; `
    iwr -useb get.scoop.sh | iex; `
    scoop install git"

#RUN "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force"
#RUN "iwr -useb get.scoop.sh | iex"
#RUN "scoop install git"

#ENV ChocolateyUseWindowsCompression false 
#RUN powershell Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
#RUN powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
#RUN choco install git.install -y --no-progress

ADD runner.ps1 C:/runner.ps1
CMD C:/runner.ps1
