#!/bin/bash
#
# PROGRAM:	lvm_new.sh
# AUTHOR:	Erin Maxwell
# PURPOSE:	Initialize new disk(s) and assign them to a NEW volgroup
# LICENSE:	GPLv3
#

# Exit if a command fails
set -o errexit

cmd_tput="/usr/bin/tput"
cmd_partprobe="/usr/sbin/partprobe"
cmd_pvcreate="/usr/sbin/pvcreate"
cmd_vgcreate="/usr/sbin/vgcreate"
cmd_pvdisplay="/usr/sbin/pvdisplay"
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

# Initialize phys vols for use with LVM
function pv_create()
{
    for dev in ${devices[*]} ; do
	tput setaf 15
	echo "pvcreate ${dev}"
	tput sgr0
	${cmd_pvcreate} ${dev}
	${cmd_pvdisplay} ${dev}
	dsp_pause
    done
}

# Create vol group with specified phys vols
function vg_create()
{
    tput setaf 15
    echo "vgcreate ${volgrp} ${devices[@]}"
    tput sgr0
    ${cmd_vgcreate} ${volgrp} ${devices[@]} 
    ${cmd_vgdisplay} ${volgrp}
    dsp_pause
}

# echo "- - -" > $scsihost/hostX/scan
function usage()
{
    echo "Usage: $0 -v <volgroup> -d <dev1> [-d <dev2>] ... [-d <devN>]" 1>&2;
    exit 0
}

#######
## Main
#######
while getopts ":v:d:" opt; do
    case "${opt}" in
	v)
	    volgrp="${OPTARG}"
	    ;;
	d)
	    devices+=("${OPTARG}")
	    ;;
	*)
	    usage
	    ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "${volgrp}" ]] || [[ -z "${devices}" ]]; then
    usage
fi

${cmd_tput} setaf 9
cat <<WARN1
**
** Please read the following very carefully!
**
I am about to create a new volume group called 
    ${volgrp}

It will include the following disks:
WARN1
for dev in ${devices[*]} ; do
    printf "    %s\n" ${dev}
done
${cmd_tput} sgr0

dsp_pause

##############
## Do the deed
##############
# Re-read partition tables:
${cmd_partprobe}

pv_create
vg_create

cat <<END

All done - please inspect everything and then create filesystems on
the new volumes as needed.

END

exit 0
