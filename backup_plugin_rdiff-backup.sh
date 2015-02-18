#
# Plugin information
#

PLUGIN_API_VER=1

PLUGIN_VER="1.0"
PLUGIN_NAME="rdiff-backup Plugin"
PLUGIN_VENDOR="Andreas Loeffler"
PLUGIN_URL=""

#
# Plugin-specific stuff
#
RDIFF_BACKUP=/usr/bin/rdiff-backup

RDIFF_BACKUP_OPTS="
    --print-statistics
    -v5
    --force"

RDIFF_BACKUP_CHECK_OPTS="
    --verify"

RDIFF_CMD_INCLUDE="--include"
RDIFF_CMD_EXCLUDE_COMPRESSION="--no-compression-regexp"
RDIFF_CMD_EXCLUDE="--exclude"

RDIFF_EXCLUDE_COMPRESSION="
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.jpg
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.jpeg
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.gif
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.png

    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.mp*
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.ogg
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.avi
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.mpeg
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.mts
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.wmv

    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.zip
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.gz
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.bz2
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.rar
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.ace
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.cab
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.tgz
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.tbz2
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.deb
    ${RDIFF_CMD_EXCLUDE_COMPRESSION} *.rpm"

# Code
plugin_PreInit()
{
    if [ ! -f "${RDIFF_BACKUP}" ]; then
        backup_printError "rdiff-backup: Binary not found: ${RDIFF_BACKUP}"
        return 1
    fi
    backup_printInfo "rdiff-backup: Hi, this is `${RDIFF_BACKUP} --version`"

    return 0
}

rdiff_initCommon()
{
    if [ -n ${BACKUP_IS_LOCAL} ]; then
        RDIFF_TMP_DIR=`${MKTEMP} -d -p ${PROFILE_DEST_PATH} rdiff-tmp-XXX`
        if [ $? -ne "0" ]; then
            backup_printInfo "rdiff-backup: Could not create temporary directory!"
            return 1
        fi       
        
        backup_printInfo "rdiff-backup: Using temporary directory: ${RDIFF_TMP_DIR}"
        RDIFF_OPTS_TMP_DIR="--tempdir=${RDIFF_TMP_DIR}"
 
        RDIFF_DEST_PATH=${PROFILE_DEST_PATH}
    else        
        RDIFF_DEST_PATH=${PROFILE_DEST_HOST}::${PROFILE_DEST_PATH}
    fi
  
    # Set defaults.
    RDIFF_EXCLUDE="
        --exclude-special-files
        --exclude-filelist ${CUR_DIR}/exclude-list.txt"

    return 0
}

plugin_InitDaily()
{
    rdiff_initCommon
    return $?
}

plugin_InitWeekly()
{
    plugin_InitDaily
    return $?
}

plugin_InitMonthly()
{
    rdiff_initCommon
    return $?
}

plugin_InitDebug()
{
    # @todo
    return 0
}

#
# Does the actual backup and returns its overall
# status.
#
plugin_DoBackup()
{
    backup_printInfo "rdiff-backup: Performing backup to: ${BACKUP_SPEC_DIR}"

    # This include *will* match everything in /home/johndoe, regardless
    # whether something like /home/johndoe/foo was specified in the exclude
    # string -- include always has precedence over exclude!
    RDIFF_INCLUDE=
    for CUR_ENTRY in ${PROFILE_INCLUDE}
    do
        RDIFF_INCLUDE="${RDIFF_INCLUDE} ${RDIFF_CMD_INCLUDE} ${CUR_ENTRY}"
    done

    RDIFF_EXCLUDE=
    for CUR_ENTRY in ${PROFILE_EXCLUDE}
    do
        RDIFF_EXCLUDE="${RDIFF_EXCLUDE} ${RDIFF_CMD_EXCLUDE} ${CUR_ENTRY}"
    done

    # Finally do the actual backup.
    ${RDIFF_BACKUP} ${RDIFF_BACKUP_OPTS} ${RDIFF_OPTS_TMP_DIR} ${RDIFF_EXCLUDE} ${RDIFF_INCLUDE} \
        ${PROFILE_SRC_PATH} ${RDIFF_DEST_PATH} 

    return $?
}

#
# Does a check of a just performed back.
# Will return 0 on success, 1 on error.
#
plugin_DoCheck()
{
    backup_printInfo "rdiff-backup: Checking backup is disabled"
    return 0

    #${RDIFF_BACKUP} ${RDIFF_BACKUP_CHECK_OPTS} ${RDIFF_DEST_PATH}
    #if [ $? -eq "0" ]; then
    #    backup_printInfo "rdiff-backup: Check successful!"
    #fi
    #return $?
}

#
# Callback for successful backup.
#
plugin_OnBackupSuccess()
{
    backup_printInfo "rdiff-backup: Backup successful!"
    return 0
}

#
# Callback for a failed backup.
#
plugin_OnBackupError()
{
    backup_printError "rdiff-backup: An error occurred while performing backup!"
    return 0
}

#
# Cleanup routine for this plugin.
#
plugin_Shutdown()
{
    if [ -n "${RDIFF_TMP_DIR}" ]; then
        ${RM} -rf -v ${RDIFF_TMP_DIR}
    fi

    return 0
}
