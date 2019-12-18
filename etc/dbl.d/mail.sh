#!/bin/bash
# 071106: EvG adapted for hongkong Debian
# 180108: EvG adapted for amsterdam Ubuntu
# 180522: EvG seems that all mail breaches are caught before in auth.log;
#             this test may be DISABLED

ANALYSIS=maillog
LIMIT=15

# analyze maillog
awk -F'[] ,()[ ]' -f $DBL/get_ip.awk reg_expr='authentication[ ]*fail' /var/log/mail.log
