#!/bin/bash
#
# PROGRAM:	rescan_disks.sh
# AUTHOR:	Erin Maxwell
# PURPOSE:	Friendly and slightly colorful script to
# 		perform a rescan of the scsi bus when adding
# 		a new physical or virtual disk to a running host.
# LICENSE:	GPLv3
#

# Exit if a command fails
set -o errexit

scsihost="/sys/class/scsi_host"		# host* dirs get "- - -" > scan
scsidev="/sys/class/scsi_device"	# echo 1 > .../x:0:0:0/device/rescan 

cmd_fdisk="/usr/sbin/fdisk"
cmd_cat="/bin/cat"
cmd_ls="/bin/ls"
cmd_tput="/usr/bin/tput"

############
## Functions
############

# Generic screen pause, requires user input.
function dsp_pause()
{
    $cmd_tput setaf 5		# I'm colorful, so I've been told...
    printf "\nPress [Return] to continue, Control-C aborts..."
    $cmd_tput sgr0		# color back to normal
    read pause < /dev/tty
}

# display contents of /dev/sd* and fdisk -l before proceeding
function dsp_devs()
{
    echo ""
    echo "*****> Contents of /dev/sd* and fdisk -l output"
    $cmd_ls /dev/sd*
    $cmd_fdisk -l
}

# echo "- - -" > $scsihost/hostX/scan
function w_scsi_host_scan()
{
    local dir=""
    for dir in ${scsihost}/host*; do
	if [[ ! -f ${dir}/scan ]]; then
	    echo "${dir}/scan does not exist!"
	fi
	echo "- - -" > ${dir}/scan
    done
}

# echo 1 > $scsihost/hostX/scan
function w_scsi_dev_rescan()
{
    local dir=""
    for dir in ${scsidev}/*:*:*:*; do
	if [[ ! -f ${dir}/device/rescan ]]; then
	    echo "${dir}/device/rescan does not exist!"
	    exit 255
	fi
	echo 1 > ${dir}/device/rescan
    done
}

## [MAIN]
$cmd_tput clear
$cmd_tput setaf 9	# term color DANGER-red :)
cat <<STARTUP_WARN
**
** README!
**
This program will perform the routine setup steps when
you add a new disk to make that disk visible to the OS.  
You must run this program with root permissions.

Please note that this script assumes you have already physically
(or virtually) added the new disk to a live, running host.

Take note of the following information before we proceed.

STARTUP_WARN
$cmd_tput sgr0		# term color back to default

dsp_devs
dsp_pause

printf "\n\nRe-scanning SCSI bus\n"
printf "\nUpdating ${scsihost}/host*/scan...\n"
w_scsi_host_scan
printf "\nUpdating ${scsidev}/*:*:*:*/device/rescan...\n"
w_scsi_dev_rescan

cat <<END

All done!  Note the changes below.

Next step, run fdisk on the new disk and create the partition table.

END

dsp_devs
dsp_pause

exit 0
