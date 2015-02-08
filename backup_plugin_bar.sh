#
# Plugin information
#

PLUGIN_API_VER=1

PLUGIN_VER="1.0"
PLUGIN_NAME="BAR Backup Plugin"
PLUGIN_VENDOR="Andreas Loeffler"
PLUGIN_URL="http://www.berlios.de/bar"

#
# Plugin-specific stuff
#
BAR=/opt/local/bin/bar

BAR_OPTS="
    --create
    --verbose=1
    --compress-algorithm=lzma5
    --log=errors,warnings,skipped
    --pattern-type=regex
    --archive-part-size=4G
    --skip-unreadable
    --no-default-config"

BAR_OPTS_FULL="
    --full"

BAR_OPTS_DIFF="
    --differential"

BAR_CHECK_OPTS="
    --test
    --verbose=1"

BAR_CRYPT_TYPE="--crypt-type=asymmetric"
BAR_CRYPT_ALGO="--crypt-algorithm=BLOWFISH"

BAR_CMD_EXCLUDE="--exclude"
BAR_CMD_EXCLUDE_COMPRESSION="--compress-exclude g:" # Use simple glob matching

BAR_EXCLUDE_COMPRESSION="
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.jpg
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.jpeg
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.gif
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.png

    ${BAR_CMD_EXCLUDE_COMPRESSION}*.mp*
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.ogg
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.avi
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.mpeg
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.mts
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.wmv

    ${BAR_CMD_EXCLUDE_COMPRESSION}*.zip
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.gz
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.bz2
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.rar
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.ace
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.cab
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.tgz
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.tbz2
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.deb
    ${BAR_CMD_EXCLUDE_COMPRESSION}*.rpm"

# Code
plugin_PreInit()
{
    if [ ! -f "${BAR}" ]; then
        backup_printError "BAR: Binary not found: ${BAR}"
        return 1
    fi
    backup_printInfo "BAR: Hi, this is version `${BAR} --version`"

    return 0
}

bar_initCommon()
{
    if [ -z "${BACKUP_DIRS}" ]; then
        backup_printError "BAR: No directories to backup specified!"
        return 1
    fi
    if [ -z "${BACKUP_TARGET_DIR}" ]; then
        backup_printError "BAR: No target directory specified!"
        return 1
    fi

    if [ ! -z "${BAR_USE_ENCRYPTION}" ]; then
        #
        # The public key is fine to be ...well ... public :-)
        #
        BAR_PUBLIC_KEY="${CUR_DIR}/keys/backup_bar.public"
        if [ ! -f ${BAR_PUBLIC_KEY} ]; then
            backup_printError "BAR: Public key ${BAR_PUBLIC_KEY} not found!"
            return 1
        fi

        #
        # Private key (for decryption) only is available if the system
        # actually has mounted our private stuff.
        #
        BAR_PRIVATE_KEY="/home/jiinx/Private/keys/bar/backup_bar.private"

        BAR_CRYPT_OPTS="
            ${BAR_CRYPT_TYPE}
            ${BAR_CRYPT_ALGO}
            --crypt-public-key=${BAR_PUBLIC_KEY}"
    fi

    BAR_TARGET_FILE_BACKUP=${BACKUP_SPEC_FILE}.bar
    BAR_TARGET_FILE_CAT=${BACKUP_SPEC_CATALOG}.bid
    BAR_TARGET_FILE_LOG=${BACKUP_SPEC_FILE}.log
    BAR_TARGET_FILE_MD5=${BACKUP_SPEC_FILE}.md5
    BAR_TARGET_FILE_PKG=${BACKUP_SPEC_FILE}_pkg.log

    BAR_OPTS_TMP_DIR="
        --tmp-directory=${BACKUP_SPEC_DIR}"

    BAR_OPTS_CATALOG_FILE="
        --incremental-list-file=${BAR_TARGET_FILE_CAT}"

    BAR_EXCLUDE="
        ${BAR_CMD_EXCLUDE} /home/jiinx/com
        ${BAR_CMD_EXCLUDE} /home/jiinx/cdrip-data
        ${BAR_CMD_EXCLUDE} /home/jiinx/dev/ext
        ${BAR_CMD_EXCLUDE} /home/jiinx/dev/old
        ${BAR_CMD_EXCLUDE} /home/jiinx/dev/read-only
        ${BAR_CMD_EXCLUDE} /home/jiinx/downloads
        ${BAR_CMD_EXCLUDE} /home/jiinx/Dropbox/.dropbox.cache
        ${BAR_CMD_EXCLUDE} /home/jiinx/dvdrip-data
        ${BAR_CMD_EXCLUDE} /home/jiinx/fun
        ${BAR_CMD_EXCLUDE} /home/jiinx/iso
        ${BAR_CMD_EXCLUDE} /home/jiinx/mags/Oekotest
        ${BAR_CMD_EXCLUDE} /home/jiinx/movies
        ${BAR_CMD_EXCLUDE} /home/jiinx/mp3/archive/0Unreviewed
        ${BAR_CMD_EXCLUDE} /home/jiinx/mp3/mixes
        ${BAR_CMD_EXCLUDE} /home/jiinx/mp3/dj
        ${BAR_CMD_EXCLUDE} /home/jiinx/opt
        ${BAR_CMD_EXCLUDE} /home/jiinx/pics/fun
        ${BAR_CMD_EXCLUDE} /home/jiinx/podcasts
        ${BAR_CMD_EXCLUDE} /home/jiinx/Private
        ${BAR_CMD_EXCLUDE} /home/jiinx/projects/vhs*
        ${BAR_CMD_EXCLUDE} /home/jiinx/roms
        ${BAR_CMD_EXCLUDE} /home/jiinx/tmp
        ${BAR_CMD_EXCLUDE} /home/jiinx/VirtualBox*VMs
        ${BAR_CMD_EXCLUDE} /home/jiinx/.adobe/Flash_Player
        ${BAR_CMD_EXCLUDE} /home/jiinx/.cache
        ${BAR_CMD_EXCLUDE} /home/jiinx/.compiz/session
        ${BAR_CMD_EXCLUDE} /home/jiinx/.cpan
        ${BAR_CMD_EXCLUDE} /home/jiinx/.dropbox-dist
        ${BAR_CMD_EXCLUDE} /home/jiinx/.dvdrip
        ${BAR_CMD_EXCLUDE} /home/jiinx/.fontconfig
        ${BAR_CMD_EXCLUDE} /home/jiinx/.gconf/apps/nautilus/desktop-metadata
        ${BAR_CMD_EXCLUDE} /home/jiinx/.java/deployment/cache
        ${BAR_CMD_EXCLUDE} /home/jiinx/.liferea_*/cache
        ${BAR_CMD_EXCLUDE} /home/jiinx/.local/share/Trash
        ${BAR_CMD_EXCLUDE} /home/jiinx/.macromedia/Flash_Player
        ${BAR_CMD_EXCLUDE} /home/jiinx/.mozilla/firefox/*/Cache
        ${BAR_CMD_EXCLUDE} /home/jiinx/.mozilla/firefox/Crash*
        ${BAR_CMD_EXCLUDE} /home/jiinx/.nautilus/metafiles
        ${BAR_CMD_EXCLUDE} /home/jiinx/.slickedit/*/vsdelta
        ${BAR_CMD_EXCLUDE} /home/jiinx/.thunderbird/*/Cache
        ${BAR_CMD_EXCLUDE} /home/jiinx/.thumbnails
        ${BAR_CMD_EXCLUDE} /home/jiinx/.wine
        ${BAR_CMD_EXCLUDE} /home/jiinx/.VirtualBox
        ${BAR_CMD_EXCLUDE} */\.svn*$"

        # Bug: Final backup file gets stored somewhere around this path:
        #${BAR_CMD_EXCLUDE} /home/jiinx/.nautilus/saved-session-*

    return 0
}

plugin_InitDaily()
{
    bar_initCommon
    if [ $? -eq "0" ]; then
        # If no catalog file is found we need to do a full backup
        # to create a new one ...
        if [ ! -f "${BAR_TARGET_FILE_CAT}" ]; then
            BAR_OPTS_PERIOD=${BAR_OPTS_FULL}
        else # ... else perform a regular daily backup
            BAR_OPTS_PERIOD=${BAR_OPTS_DIFF}
        fi
    fi
    return $?
}

plugin_InitWeekly()
{
    plugin_InitDaily
    return $?
}

plugin_InitMonthly()
{
    bar_initCommon
    if [ $? -eq "0" ]; then
        BAR_OPTS_PERIOD=${BAR_OPTS_FULL}
    fi
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
    backup_printInfo "BAR: Backup Target = ${BAR_TARGET_FILE_BACKUP}"
    backup_printInfo "BAR: Catalog = ${BAR_TARGET_FILE_CAT}"

    ${BAR} ${BAR_OPTS_PERIOD} ${BAR_OPTS} ${BAR_CRYPT_OPTS} ${BAR_OPTS_CATALOG_FILE} ${BAR_OPTS_TMP_DIR} ${BAR_EXCLUDE} ${BAR_EXCLUDE_COMPRESSION} ${BAR_TARGET_FILE_BACKUP} ${BACKUP_DIRS}
    return $?
}

#
# Does a check of a just performed back.
# Will return 0 on success, 1 on error.
#
plugin_DoCheck()
{
    # It can happen that when an inremental/differential backup is
    # done that no changed files were detected and therefore no new backup
    # file was created. So check whether we have smth. to check first.
    if [ ! -f "${BAR_TARGET_FILE_BACKUP}*" ]; then
        backup_printInfo "BAR: No backup archive created, so no check required"
        return 0
    fi

    #
    # Skip testing the newly created backup archive when we don't have
    # the private key to decrypt it ...
    #
    if [ -f "${BAR_PRIVATE_KEY}" ]; then
        BAR_DECRYPT_OPTS="
            ${BAR_CRYPT_TYPE}
            ${BAR_CRYPT_ALGO}
            --crypt-private-key=${BAR_PRIVATE_KEY}"
    fi

    backup_printInfo "BAR: Checking archive ..."
    ${BAR} ${BAR_CHECK_OPTS} ${BAR_DECRYPT_OPTS} ${BAR_TARGET_FILE_BACKUP}*
    if [ $? -eq "0" ]; then
        # Create MD5
        BAR_FILE_MD5_CONTENT="
            ${BAR_TARGET_FILE_BACKUP}*
            ${BAR_TARGET_FILE_CAT}"
        backup_printInfo "BAR: Generating checksum file ..."
        # Use AWK to strip the absolute path for getting the pure file name
        # without any path.
        ${MD5SUM} ${BAR_FILE_MD5_CONTENT} | ${AWK} -F / '{ print $1 $NF }' > ${BAR_TARGET_FILE_MD5}
        if [ $? -ne "0" ]; then
            backup_printError "BAR: Error while creating checksum file!"
        fi
    fi
    return $?
}

#
# Callback for successful backup.
#
plugin_OnBackupSuccess()
{
    backup_printInfo "BAR: Backup successful!"
    return 0
}

#
# Callback for a failed backup.
#
plugin_OnBackupError()
{
    backup_printError "BAR: An error occured while performing backup!"
    return 0
}

#
# Cleanup routine for this plugin.
#
plugin_Shutdown()
{
    return 0
}

