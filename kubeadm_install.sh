#!/bin/bash

CNI_PLUGINS_VERSION="v1.1.2"
ARCH="amd64"
DEST="/opt/cni/bin"
sudo mkdir -p "$DEST"
#curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-#plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | sudo tar -C "$DEST" -xz

DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"

CRICTL_VERSION="v1.27.0"
ARCH="amd64"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz


RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"
pushd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubectl,kubeadm,kubelet}
sudo chmod +x {kubectl,kubeadm,kubelet}

popd

RELEASE_VERSION="v0.4.0"
sudo rm -rf /etc/systemd/system/kubelet.service

sudo mkdir -p /etc/systemd/system/kubelet.service.d
cat kubeadm.conf | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf


cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

CONTAINERD_VERSION="1.7.1"

wget --no-check-certificate https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz


tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

cp containerd.service /usr/lib/systemd/system/

#pushd /usr/lib/systemd/system

#wget --no-check-certificate https://raw.githubusercontent.com/containerd/containerd/main/#containerd.service

#popd

systemctl daemon-reload
systemctl enable --now containerd

RUNC_VERSION="1.1.7"

CNI_PLUGINS="1.3.0"

wget --no-check-certificate https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64

install -m 755 runc.amd64 /usr/local/sbin/runc

wget --no-check-certificate https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS}/cni-plugins-linux-amd64-v${CNI_PLUGINS}.tgz

mkdir -p /opt/cni/bin

tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v${CNI_PLUGINS}.tgz

git clone https://git.netfilter.org/libnetfilter_cttimeout/

pushd libnetfilter_cttimeout

autoreconf -i

./configure

make

make install

popd

git clone https://git.netfilter.org/libnetfilter_cthelper/

pushd libnetfilter_cthelper

autoreconf -i

./configure

make

make install

popd

git clone https://git.netfilter.org/libnetfilter_queue/

pushd libnetfilter_queue

autoreconf -i

./configure

make

make install

popd

git clone https://git.netfilter.org/libnetfilter_log/

pushd libnetfilter_log

autoreconf -i

./configure

make

make install

popd

git clone https://git.netfilter.org/libnetfilter_acct/

pushd libnetfilter_acct

autoreconf -i

./configure

make

make install

popd

git clone https://git.netfilter.org/libnfnetlink/

pushd libnfnetlink

autoreconf -i

./configure

make

make install

popd

git clone https://git.netfilter.org/libnftnl/

pushd libnftnl

autoreconf -i

./configure

make

make install

popd

CONNTRACK_VERSION="1.4.7"

SOCAT_VERSION="1.7.4.4"
ASCIDOC_VERSION="3.2.3"


wget --no-check-certificate https://www.netfilter.org/projects/conntrack-tools/files/conntrack-tools-${CONNTRACK_VERSION}.tar.bz2 && tar xvf conntrack-tools-${CONNTRACK_VERSION}.tar.bz2

pushd conntrack-tools-${CONNTRACK_VERSION}

PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure -enable-systemd

make

make install

popd


wget --no-check-certificate http://www.dest-unreach.org/socat/download/socat-${SOCAT_VERSION}.tar.gz && tar -xvzf socat-${SOCAT_VERSION}.tar.gz

pushd socat-${SOCAT_VERSION}

PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure -enable-systemd

make

make install

popd


git clone git://git.netfilter.org/iptables

pushd iptables

./autogen.sh

PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure --enable-libipq --enable-bpf-compiler --enable-nfsynproxy --enable-profiling --enable-static --enable-devel

make

make install 

popd

mkdir -p asciidoc3-${ASCIDOC_VERSION}

python3 -m ensurepip

python3 -m pip install virtualenv

python3 -m venv ascii_venv

chmod +x ascii_venv/bin/activate

./ascii_venv/bin/activate

pushd asciidoc3-${ASCIDOC_VERSION}

wget https://asciidoc3.org/asciidoc3-${ASCIDOC_VERSION}.tar.gz && tar -xvzf asciidoc3-${ASCIDOC_VERSION}.tar.gz

./installscript



popd

#git clone git://git.netfilter.org/nftables

#pushd nftables
#
#./autogen.sh
#
#PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure --enable-libipq --enable-bpf-compiler --enable-nfsynproxy --enable-profiling --enable-static --enable-devel
#
#make
#
#make install 
#
#popd


echo "Writing kubelet"

cat kubelet.service | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service

echo "Reading the file"

cat /etc/systemd/system/kubelet.service

echo "Finished displaying the kubelet.service file"

systemctl enable --now kubelet

mkdir -p /etc/containerd

containerd config default > /etc/containerd/config.toml

chmod +x systemd_cgroup.py

cat /etc/containerd/config.toml | ./systemd_cgroup.py | tee /etc/containerd/config.toml

chmod +x kubelet_substitution.py

cat /etc/systemd/system/kubelet.service | ./kubelet_substitution.py | tee /etc/systemd/system/kubelet.service

systemctl enable --now containerd



