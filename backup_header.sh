# Tools
AWK=/usr/bin/awk
CHMOD=/bin/chmod
CP=/bin/cp
DPKG=/usr/bin/dpkg
DATE=/bin/date
ECHO=/bin/echo
FIND=/usr/bin/find
GUNZIP=/bin/gunzip
GZIP=/bin/gzip
HEAD=/usr/bin/head
HOSTNAME=/bin/hostname
INSTALL=/usr/bin/install
LN=/bin/ln
LS=/bin/ls
MD5SUM=/usr/bin/md5sum
MKDIR=/bin/mkdir
MKTEMP=/bin/mktemp
MOUNT=/bin/mount
RM=/bin/rm
RMDIR=/bin/rmdir
TAIL=/usr/bin/tail
TAR=/bin/tar
TIME=/bin/time
UNAME=/bin/uname
UMOUNT=/bin/umount
WC=/usr/bin/wc
ZENITY=/usr/bin/zenity

# Tags
TAG_HOSTNAME=`${HOSTNAME}`_`${UNAME} -m`
TAG_KERNEL=`${UNAME} -r`
TAG_YEARMONTH=`${DATE} +%y%m`
TAG_DATE_DIR=Backup_${TAG_YEARMONTH}
TAG_DATE_FILE=`${DATE} +%y%m%d_%H%M%S`
TAG_TITLE="${TAG_HOSTNAME} - ${TAG_KERNEL}"

# Enable the following line for debugging
#set -x

isRoot()
{
    if [ `id -u` -ne "0" ]; then
	return 1
    fi
    return 0
}

backup_Mount()
{
    # Do we have a target device?
    if [ -z "${TARGET_DEVICE}" ]; then
        backup_printError "No (valid) target device found!"
        return 1
    fi
    if [ -z "${TARGET_DEVICE_UUID}" ]; then
        backup_printError "No (valid) target device UUID found!"
        return 1
    fi

    # Device not mounted? Then specify a default mount point
    if [ -z "${TARGET_MOUNTPOINT}" ]; then
        backup_printInfo "Mounting device ..."

        # Try to mount it
        TARGET_MOUNTPOINT="/media/device_${TARGET_DEVICE_UUID}"
        ${MKDIR} -p -m 700 ${TARGET_MOUNTPOINT}
        ${MOUNT} -v -t auto /dev/${TARGET_DEVICE} ${TARGET_MOUNTPOINT} # -t ntfs ?
        if [ $? -ne "0" ]; then
            backup_printError "Error mounting target device!"
            return 1
        fi
    fi

    # Set final target directory
    BACKUP_TARGET_DIR=${TARGET_MOUNTPOINT}

    # Set file specs
    BACKUP_SPEC_DIR=${BACKUP_TARGET_DIR}/${TAG_DATE_DIR}
    BACKUP_SPEC_FILE=${BACKUP_SPEC_DIR}/${TAG_DATE_FILE}_${TAG_HOSTNAME}
    BACKUP_SPEC_CATALOG=${BACKUP_SPEC_DIR}/${TAG_YEARMONTH}_${TAG_HOSTNAME}

    BACKUP_LOG_FILE_DEST=${BACKUP_SPEC_FILE}.log

    ${MKDIR} -p -m 0755 ${BACKUP_SPEC_DIR}
    if [ $? -ne "0" ]; then
        backup_printError "Error creating target directory: ${BACKUP_SPEC_DIR}"
        return 1
    fi

    # TODO: Return value!
    return 0
}

backup_Unmount()
{
    # Unmount (lazy, clean up later if not busy anymore)
    if [ ! -z "${TARGET_MOUNTPOINT}" ]; then
        ${UMOUNT} -l ${TARGET_MOUNTPOINT}
        return $?
    fi
    return 0
}

backup_Init()
{
    isRoot
    if [ $? -eq "1" ]; then
        backup_printError "Please start as root user!"
        return 1
    fi

    # Log stdout/stderr to a file if not running in a terminal.
    if [[ ! -t 1 ]]; then
        BACKUP_LOG_FILE_SRC=`${MKTEMP} --tmpdir backup-XXX.log`
        ${ECHO} "Writing to logfile: ${BACKUP_LOG_FILE_SRC}"
        exec > ${BACKUP_LOG_FILE_SRC} >&1
    fi

    # Close stdin -- we never should need input for this script.
    exec < /dev/null 2<&1

    if [ -e "${ZENITY}" ]; then
        exec 3> >(DISPLAY=:0 ${ZENITY} --notification --display=:0.0 --listen)
    fi

    backup_printInfo "Backup initialized"

    BACKUP_DIRS="
        /etc
        /home"

    #
    # UUIDs by "ls -l /dev/disk/by-uuid":
    # or do a "sudo blkid":
    # Iomega Ego 1TB: 4f5cdf0a-baee-484d-a21a-a1a0239a6464
    #
    if [ -z "${BACKUP_TARGET_DIR}" ]; then
        TARGET_DEVICE_UUID="4f5cdf0a-baee-484d-a21a-a1a0239a6464"
        TARGET_DEVICE=`$LS -l /dev/disk/by-uuid | grep "$TARGET_DEVICE_UUID ->" | sed 's/.*\///'`
        if [ -n "${TARGET_DEVICE}" ]; then
            TARGET_MOUNTPOINT=`mount | grep $TARGET_DEVICE | sed 's/.*on //' | sed 's/ .*//'`
        fi

        backup_Mount
        if [ $? -ne "0" ]; then
            return 1
        fi
    else
        ${MKDIR} -p -m 700 ${BACKUP_TARGET_DIR}
        if [ $? -ne "0" ]; then
            backup_printError "Error creating target directory: ${BACKUP_TARGET_DIR}"
            return 1
        fi
    fi

    backup_printInfo "Title: ${TAG_TITLE}"
    backup_printInfo "Target Directory: ${BACKUP_TARGET_DIR}"
    return 0
}

backup_runPreSection()
{
    backup_printInfo "Backup started: `$DATE`"
    TIME_START=$(${DATE} +%s)
    return 0
}

backup_runPostSection()
{
    backup_printInfo "Backup ended: `$DATE`"
    local TIME_END=$(${DATE} +%s)
    local TIME_DIFF_SECONDS=$(($TIME_END - $TIME_START))
    local TIME_DIFF_MINS=$(($TIME_DIFF_SECONDS / 60))
    if [ $TIME_DIFF_MINS -eq "0" ]; then
        backup_printInfo "Backup took ${TIME_DIFF_SECONDS} seconds"
    else
        backup_printInfo "Backup took ${TIME_DIFF_MINS} minute(s)"
    fi
    return 0
}

backup_Uninit()
{
    # Do *not* delete directories!

    # Save installed software packages
    # More info: http://www.cyberciti.biz/tips/linux-get-list-installed-software-reinstallation-restore.html
    BACKUP_PKGLIST_FILE_DEST=${BACKUP_SPEC_FILE}_pkg.lst
    if [ -e "${DPKG}" ]; then
        backup_printInfo "Storing software package list ..."
        ${DPKG} --get-selections > ${BACKUP_PKGLIST_FILE_DEST}
        if [ $? -ne "0" ]; then
            backup_printError "Error storing software packages list to ${BACKUP_PKGLIST_FILE_DEST}"
        else
            ${GZIP} -v -9 ${BACKUP_PKGLIST_FILE_DEST}
            if [ $? -ne "0" ]; then
                backup_printError "Error gzipping package list ${BACKUP_PKGLIST_FILE_DEST}"
            fi
        fi
    else
        backup_printInfo "No ${DPKG} installed, skipping software packages list"
    fi

    # Save log file (if any)
    if [ -f "${BACKUP_LOG_FILE_SRC}" ]; then
        backup_printInfo "Storing backup log file ..."
        ${CP} ${BACKUP_LOG_FILE_SRC} ${BACKUP_LOG_FILE_DEST}
        if [ $? -ne "0" ]; then
            backup_printError "Error copying log file ${BACKUP_LOG_FILE_SRC} to ${BACKUP_LOG_FILE_DEST}"
        else
            ${GZIP} -v -9 ${BACKUP_LOG_FILE_DEST}
            if [ $? -ne "0" ]; then
                backup_printError "Error gzipping log file ${BACKUP_LOG_FILE_DEST}"
            fi
        fi
    else
        backup_printInfo "No log file ${BACKUP_LOG_FILE_SRC} created, skipping"
    fi

    # Close zenity file descriptor to let the
    # notification icon end.
    if [ -e "${ZENITY}" ]; then
        exec 3>&-
    fi

    #
    # At this point no more logging will be available!
    # See block above to know why ...
    #

    # Set access rights
    ${CHMOD} -v 0644 ${BACKUP_SPEC_FILE}* ${BACKUP_SPEC_CATALOG}*
    if [ $? -ne "0" ]; then
        backup_printError "Error setting access rights!"
        return 1
    fi

    backup_Unmount
    return 0
}

backup_printError()
{
    # TODO: Add --silent switch for not showing zenity stuff.
    if [ -e "${ZENITY}" ]; then
        DISPLAY=:0 ${ZENITY} --error --title "Backup Error - `${DATE}`" --text="Error: $1" --display=:0.0
    fi
    ${ECHO} "Error: $1"
    return 0
}

backup_printInfo()
{
    ${ECHO} "$1"

    # TODO: Add --silent switch for not showing zenity stuff.
    if [ -e "${ZENITY}" ]; then
        # Note: "tooltip" prefix needs to be there for zenity to
        #       interpret stuff.
        ${ECHO} "tooltip: $1" >&3
    fi
    return 0
}

backup_showLogTrace()
{
    if [ ! -e "${BACKUP_LOG_FILE_SRC}" ]; then
        return 1
    fi

    if [ -e "${ZENITY}" ]; then
        DISPLAY=:0 ${ZENITY} --text-info --display=:0.0 < ${BACKUP_LOG_FILE_SRC}
    fi

    return 0
}

