#!/usr/bin/python

import os
import sys
import re

#
# This script is written to extract elapsed times from linux-backup-cloud.sh or vm-backup-cloud.sh
#
# Usage:
#
#     ./linux-backup-cloud.sh &> linux-backup-cloud.results
#     python tabulate.py linux-backup-cloud.results 

def getTime(minute, second):
    t = int(minute) * 60 + float(second)
    return "%.1f" % t

if len(sys.argv) <= 1:
    print "usage:", sys.argv[0], "<test result file>"
    sys.exit(1)

i = 0
for line in open(sys.argv[1]).readlines():
    if line.startswith("====") and "init" in line:
        print "\n| | ",
        i += 1 
        continue
    m = re.match(r"real\s+(\d+)m([\d.]+)s", line)
    if m:
        print getTime(m.group(1), m.group(2)), "|",
        continue
 
print "" 
     


