#!/bin/bash
#
# Delete all 7 days old backup files 
#
# Set a cron to call this script once everydays
#
find /home/xxxx/backups-directory -type f -mtime +7 -exec /bin/rm -f {} \;
