#!/bin/sh

chmod +x operator_sdk_install.sh

sudo ./operator_sdk_install.sh

cat <<EOF | tee -a ~/.bash_profile

export PATH=$PATH:/usr/local/go/bin

EOF

source ~/.bash_profile
