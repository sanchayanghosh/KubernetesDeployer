#!/bin/python3 
import sys
import re

input = sys.stdin.read()

input = input.replace("KUBELET_KUBEADM_ARGS=--container-runtime=remote --container-runtime-endpoint=/run/containerd/containerd.sock\n", "")


print(re.compile("(ExecStart\s*\=\s*[^\n]*)", flags=re.DOTALL).sub("\\1\nKUBELET_KUBEADM_ARGS=--container-runtime=remote --container-runtime-endpoint=/run/containerd/containerd.sock\n", input))
