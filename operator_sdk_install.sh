#!/bin/sh

export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')


export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.26.0
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}


gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E



curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt.asc
gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc



grep operator-sdk_${OS}_${ARCH} checksums.txt | sha256sum -c -



chmod +x operator-sdk_${OS}_${ARCH} && sudo mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk



mkdir -p go_package

pushd go_package

wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz 

rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz

popd

mkdir -p docker_package

pushd docker_package

wget https://download.docker.com/linux/static/stable/x86_64/docker-20.10.22.tgz

tar -xvzf docker-20.10.22.tgz

sudo cp docker/* /usr/bin/

wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.service

sudo cp docker.service /etc/systemd/system/

wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.socket

sudo cp docker.socket /etc/systemd/system/

popd

groupadd docker

usermod -aG docker netest

systemctl enable --now docker



