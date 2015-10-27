#!/bin/bash

#Ensure script has root permissions
(( EUID != 0 )) && exec sudo -- "$0" "$@"

#Get distribution name
linuxReleaseName=`lsb_release -a 2> /dev/null | grep "Distributor ID" | awk '{print $3,$4,$5,$6,$7,$8,$9}' | tr -d " "`;
if [ -z "$linuxReleaseName" ]; then
	# Fall back incase lsb_release does not exist / fails - use /etc/issue over /etc/*release*
	linuxReleaseName=`cat /etc/issue /etc/*release* 2>/dev/null | head -n1 | awk '{print $1}'`;
fi

cd "$(dirname "$(find / -type f -name installfog.sh | head -1)")"
pwd

#Set OSVersion
if [ -f /etc/os-release ]; then
		linuxReleaseName=`sed -n 's/^NAME=\(.*\)/\1/p' /etc/os-release | tr -d '"'`
		OSVersion=`sed -n 's/^VERSION_ID=\([^.]*\).*/\1/p' /etc/os-release | tr -d '"'`
	elif [ -f /etc/redhat-release ]; then
		linuxReleaseName=`cat /etc/redhat-release | awk '{print $1}'`;
		OSVersion=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
	elif [ -f /etc/debian_version ]; then
		linuxReleaseName='Debian'
		OSVersion=`cat /etc/debian_version`
fi

#Source config files
if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Fedora|Redhat|CentOS|Mageia'`" ]; then
	. ../lib/redhat/config.sh
fi

if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Arch'`" ]; then
	. ../lib/arch/config.sh
fi

if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Ubuntu|Debian'`" ]; then
	. ../lib/ubuntu/config.sh
fi

. /opt/fog-git/lib/common/config.sh

#set apache user variable
#if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Fedora|Redhat|CentOS'`" ]; then
#		apacheuser="apache";
#		tftpdirdst="/tftpboot";
#	if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Mageia'`" ]; then
#		apacheuser="apache";
#		tftpdirdst="/var/lib/tftpboot";
#	if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Arch'`" ]; then
#		apacheuser="http";
#		tftpdirdst="/srv/tftp";
#	if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Ubuntu|Debian'`" ]; then
#		apacheuser="http";
#		tftpdirdst="/tftpboot";
#	
#fi
#
#fogprogramdir="/opt/fog"
#fogutilsdir="${fogprogramdir}/utils";


chown -R ${apacheuser} ${fogutilsdir} >/dev/null 2>&1
chmod -R 700 ${fogutilsdir} >/dev/null 2>&1
find "${tftpdirdst}" ! -type d -exec chmod 644 {} \;
chown -R ${username} "${tftpdirdst}";
chown -R ${username} "${webdirdest}/service/ipxe";
find "${tftpdirdst}" -type d -exec chmod 755 {} \;
find "${webdirdest}" -type d -exec chmod 755 {} \;
find "${tftpdirdst}" ! -type d -exec chmod 644 {} \;
chmod 755 $initdpath/$serviceItem >/dev/null 2>&1
chown -R mysql:mysql /var/lib/mysql >/dev/null 2>&1
chmod 775 $snapindir
chown -R ${username}:${apacheuser} ${snapindir}
chown -R ${username} "/home/${username}" >/dev/null 2>&1;
chmod -R 777 "$storage" >/dev/null 2>&1
chmod -R 777 "$storage" >/dev/null 2>&1
chmod -R 777 "$storageupload" >/dev/null 2>&1
chown -R $apacheuser:$apacheuser $webdirdest/management/other >/dev/null 2>&1
chmod +rx $apachelogdir
chmod +rx $apacheerrlog
chmod +rx $apacheacclog
chown -R ${apacheuser}:${apacheuser} $webdirdest
chown -R ${apacheuser}:${apacheuser} "$webdirdest"
