#!/bin/bash

rsync -rv  --ignore-existing --exclude 'SecondSTEP' /media/shared/ /encode/shared/
rsync -rv  --ignore-existing /media/shared/SecondSTEP/ /medialibrary/SecondSTEP/
pyhb.py -s "/encode/shared/" -d "/medialibrary/" -r -L "/root/pyhb-logs/" -- -e x264 -O -Z=Normal -f mp4
chown -R emby:root /medialibrary
chmod -R 755 /medialibrary
