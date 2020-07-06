# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM node:10.16-stretch-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        bash \
        netbase \
        wget \
    &&    set -ex; \
        if ! command -v gpg > /dev/null; then \
                apt-get install -y --no-install-recommends \
                    gnupg \
                    dirmngr \
                ; \
                rm -rf /var/lib/apt/lists/*; \
        fi \

    # procps is very common in build systems, and is a reasonably small package

    &&  apt-get install -y --no-install-recommends \
                bzr \
                git \
                mercurial \
                openssh-client \
                subversion \
                \
                procps \

    # Install .NET CLI dependencies

    &&  apt-get install -y --no-install-recommends \
                make \
                g++ \
                libc6 \
                libgcc1 \
                libgssapi-krb5-2 \
                libicu57 \
                liblttng-ust0 \
                libssl1.0.2 \
                libstdc++6 \
                zlib1g \
    &&  rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 3.1.301

ENV HOME=/home/theia

RUN mkdir /projects ${HOME} && \
    # Change permissions to let any arbitrary user
    for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

RUN curl -SL --output dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/8db2b522-7fa2-4903-97ec-d6d04d297a01/f467006b9098c2de256e40d2e2f36fea/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='dd39931df438b8c1561f9a3bdb50f72372e29e5706d3fb4c490692f04a3d55f5acc0b46b8049bc7ea34dedba63c71b4c64c57032740cbea81eef1dce41929b4e' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && mkdir ${HOME}/.dotnet && chmod -R 777 ${HOME}/.dotnet \
    && mkdir /usr/share/dotnet/sdk/NuGetFallbackFolder && chmod 777 /usr/share/dotnet/sdk/NuGetFallbackFolder \
    && mkdir ${HOME}/.nuget && chmod -R 777 ${HOME}/.nuget \
    && mkdir ${HOME}/.templateengine && chmod -R 777 ${HOME}/.templateengine \
    && chmod -R 777 ${HOME}

# Configure web servers to bind to port 80 when present
ENV ASPNETCORE_URLS=http://+:80 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

# Trigger first run experience by running arbitrary cmd to populate local package cache
RUN dotnet help

WORKDIR /projects

ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
