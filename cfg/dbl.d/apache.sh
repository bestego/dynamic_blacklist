#!/bin/bash
# 071106 EvG: adapted for hongkong Debian
# 180198 EvG: adapted for amsterdam Ubuntu

ANALYSIS=apache_error
LIMIT=16

# analyze apache error log
awk -F'[] :[]' -f $DBL/get_ip.awk reg_expr='error' /var/log/apache2/*error.log
