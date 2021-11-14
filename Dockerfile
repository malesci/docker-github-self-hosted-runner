# hadolint ignore=DL3007
# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019
LABEL maintainer="mario.alesci@gmail.com"

ARG $TARGETPLATFORM
SHELL [ "powershell" ]

WORKDIR c:\\actions-runner
COPY install_actions.ps1 .

RUN Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; \
    iwr -useb get.scoop.sh | iex; \
    scoop install git

# PATH isn't actually set in the Docker image, so we have to set it from within the container
RUN $newPath = ('{0}\docker;{1}' -f $env:ProgramFiles, $env:PATH); \
	Write-Host ('Updating PATH: {0}' -f $newPath); \
	[Environment]::SetEnvironmentVariable('PATH', $newPath, [EnvironmentVariableTarget]::Machine);
# doing this first to share cache across versions more aggressively

ENV DOCKER_VERSION 20.10.10
ENV DOCKER_URL https://download.docker.com/win/static/stable/x86_64/docker-20.10.10.zip
# TODO ENV DOCKER_SHA256
# https://github.com/docker/docker-ce/blob/5b073ee2cf564edee5adca05eee574142f7627bb/components/packaging/static/hash_files !!
# (no SHA file artifacts on download.docker.com yet as of 2017-06-07 though)

RUN Write-Host ('Downloading {0} ...' -f $env:DOCKER_URL); \
	Invoke-WebRequest -Uri $env:DOCKER_URL -OutFile 'docker.zip'; \
	\
	Write-Host 'Expanding ...'; \
	Expand-Archive docker.zip -DestinationPath $env:ProgramFiles; \
# (this archive has a "docker/..." directory in it already)
	\
	Write-Host 'Removing ...'; \
	Remove-Item @( \
			'docker.zip', \
			('{0}\docker\dockerd.exe' -f $env:ProgramFiles) \
		) -Force; \
	\
	Write-Host 'Verifying install ("docker --version") ...'; \
	docker --version; \
	\
	Write-Host 'Complete.';

#RUN Install-Module -Name DockerMsftProvider -Repository PSGallery -Force; \
#    Install-Package -Name docker -ProviderName DockerMsftProvider -Force

RUN $GH_RUNNER_VERSION=(Invoke-WebRequest -Uri "https://api.github.com/repos/actions/runner/releases/latest" -UseBasicParsing | ConvertFrom-Json | Select tag_name).tag_name.SubString(1) ; \
    .\install_actions.ps1 ${GH_RUNNER_VERSION} ${TARGETPLATFORM} ; \
    Remove-Item -Path "install_actions.ps1" -Force

COPY token.ps1 entrypoint.ps1 c:/
#ENTRYPOINT ["c:\\entrypoint.ps1"]
##CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]

CMD c:\\entrypoint.ps1
