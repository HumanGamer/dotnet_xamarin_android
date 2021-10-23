# Docker build script for dotnet on android

FROM ubuntu:20.04

# Ensure there are no prompts
ARG DEBIAN_FRONTEND=noninteractive

# Android Platform Versions
ENV D_INST_ANDROID_PKG_VERSIONS=28;29

# Required Packages
ENV D_INST_REQ_PACKAGES sudo unzip curl gnupg2 ca-certificates apt-transport-https openjdk-8-jdk android-sdk lxd

# Install the required packages
RUN apt update && apt upgrade -y
RUN apt -y install $D_INST_REQ_PACKAGES

# Download Android SDK command line tools and install them to the android sdk directory
RUN curl https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip --output cmdlinetools.zip
RUN mkdir -p /usr/lib/android-sdk/cmdline-tools/latest
RUN unzip cmdlinetools.zip
RUN mv cmdline-tools/* /usr/lib/android-sdk/cmdline-tools/latest
RUN rm cmdlinetools.zip
RUN rm -rf cmdline-tools

# Pre-accept Android SDKManager license agreement
RUN yes | /usr/lib/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses

# Install desired android platform versions
RUN (IFS=';'; for p in $D_INST_ANDROID_PKG_VERSIONS; do /usr/lib/android-sdk/cmdline-tools/latest/bin/sdkmanager "platforms;android-$p"; done)

# Install Mono
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt update

RUN apt -y install mono-devel monodoc-base

# Download Xamarin.Android (latest functional build from azure as of July 24th)
RUN curl https://artprodcus3.artifacts.visualstudio.com/Ad0adf05a-e7d7-4b65-96fe-3f3884d42038/6fd3d886-57a5-4e31-8db7-52a1b47c07a8/_apis/artifact/cGlwZWxpbmVhcnRpZmFjdDovL3hhbWFyaW4vcHJvamVjdElkLzZmZDNkODg2LTU3YTUtNGUzMS04ZGI3LTUyYTFiNDdjMDdhOC9idWlsZElkLzQwMzE3L2FydGlmYWN0TmFtZS9pbnN0YWxsZXJzLXVuc2lnbmVkKy0rTGludXg1/content?format=zip --output xamarin.zip
RUN unzip xamarin.zip
RUN rm xamarin.zip

# Install Xamarin.Android
RUN dpkg -i "installers-unsigned - Linux/xamarin.android-oss_11.3.99.0_amd64.deb"
RUN rm -rf "installers-unsigned - Linux"

# Install dotnet microsoft packages
RUN curl https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb --output packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb

# Install dotnet 5 and core3.1
RUN apt update
RUN apt -y install dotnet-sdk-5.0 dotnet-runtime-5.0 dotnet-sdk-3.1 dotnet-runtime-3.1

# Symlink for Xamarin.Android in msbuild
RUN find /usr/share/dotnet/sdk/ -maxdepth 1 -name "5.*" -exec mkdir "{}/Xamarin" \; -exec ln -s "/usr/lib/xamarin.android/xbuild/Xamarin/Android" "{}/Xamarin/Android" \;

# Set SDK Variable
ENV AndroidSdkDirectory=/usr/lib/android-sdk

# Add docker user with sudo permissions and password of "docker"
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
USER docker

# Setup docker entry point
CMD /bin/bash
