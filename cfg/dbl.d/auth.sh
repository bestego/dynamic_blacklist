#!/bin/bash
# 180801 EvG: updated for amsterdam Ubuntu

ANALYSIS=authentication_failure
LIMIT=15

# analyze auth log
awk -f $DBL/get_ip.awk  reg_expr='sshd.*invalid user' /var/log/auth.log
awk -f $DBL/get_ip.awk  reg_expr='sshd.*failed[ ]*password' /var/log/auth.log
awk -F '[ =]' -f $DBL/get_ip.awk  reg_expr='auth:.*authentication[ ]*fail' /var/log/auth.log
