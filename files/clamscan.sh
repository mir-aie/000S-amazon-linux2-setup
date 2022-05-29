#!/bin/sh

# update virus database
/usr/bin/freshclam > /dev/null 2>&1

# check virus
/usr/bin/clamscan / --infected --recursive --log=/var/log/clamscan.log --exclude-dir=^/sys --exclude-dir=^/proc --exclude-dir=^/dev > /dev/null 2>&1
