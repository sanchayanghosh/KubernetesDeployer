#!/usr/local/bin/python3 
import sys
import re

input = sys.stdin.read()


print(re.compile("SystemdCgroup\s*=\s*[a-zA-Z]*", flags=re.DOTALL).sub("SystemdCgroup = true", input))
