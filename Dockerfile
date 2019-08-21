FROM alpine:3.10

ARG KUBECFG_VERSION=v0.12.4
ARG KUBEVAL_VERSION=0.13.0
ARG CONFTEST_VERSION=0.11.0

RUN apk add --no-cache make ca-certificates && \
    apk add --no-cache --virtual install-deps curl && \
    curl -L -o /bin/kubecfg https://github.com/bitnami/kubecfg/releases/download/"$KUBECFG_VERSION"/kubecfg-linux-amd64 && \
    chmod +x /bin/kubecfg && \
    curl -L -o /tmp/kubeval.tar.gz https://github.com/instrumenta/kubeval/releases/download/"$KUBEVAL_VERSION"/kubeval-linux-amd64.tar.gz && \
    tar -C /tmp -xvf /tmp/kubeval.tar.gz && \
    mv /tmp/kubeval /bin/kubeval && \
    chmod +x /bin/kubeval && \
    curl -L -o /tmp/conftest.tar.gz https://github.com/instrumenta/conftest/releases/download/v"$CONFTEST_VERSION"/conftest_"$CONFTEST_VERSION"_Linux_x86_64.tar.gz && \
    tar -C /tmp -xvf /tmp/conftest.tar.gz && \
    mv /tmp/conftest /bin/conftest && \
    chmod +x /bin/conftest && \
    apk del install-deps && \
    adduser tests -u 1197 -D

USER tests

CMD kubecfg version && kubeval --version && conftest --version
