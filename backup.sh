#!/bin/bash

# Include header
CUR_DIR=$(cd `dirname $0` && pwd)
. ${CUR_DIR}/backup_header.sh
# @todo Iterate over plugins automatically!
#. $CUR_DIR/backup_plugin_bar.sh
. ${CUR_DIR}/backup_plugin_rdiff-backup.sh

# Command line arguments
CMDLINE_ARG0=$1

if [ $PLUGIN_API_VER -ne "1" ]; then
    backup_printError "Invalid API version of plugin!"
    exit
fi

backup_Init
if [ $? -ne "0" ]; then
    backup_printError "Error while initializing backup!"
else
    plugin_PreInit
    if [ $? -ne "0" ]; then
        backup_printError "Error while initializing plugin!"
    else
        case "${CMDLINE_ARG0}" in
            mount)
                backup_printInfo "Mounting ..."
                exit ; Hack: Skip uninit
                ;;
            monthly) # This script must be run every 28 days
                backup_printInfo "Monthly schedule selected"
                plugin_InitMonthly
                ;;
            weekly) # This script must be run every 7 days
                backup_printInfo "Weekly schedule selected"
                plugin_InitWeekly
                ;;
            debug) # Debug mode
                backup_printInfo "Debug schedule selected"
                plugin_InitDebug
                ;;
            daily|*) # This script must be run every day
                backup_printInfo "Daily schedule selected"
                plugin_InitDaily
                ;;
        esac

        if [ $? -eq "0" ]; then
            backup_runPreSection
            if [ $? -eq "0" ]; then
                plugin_DoBackup
                if [ $? -eq "0" ]; then
                    backup_printInfo "Checking backup ..."
                    plugin_DoCheck
                    if [ $? -eq "0" ]; then
                        backup_runPostSection
                        if [ $? -eq "0" ]; then
                            plugin_OnBackupSuccess
                            if [ $? -eq "0" ]; then
                                backup_printInfo "Backup successful!"
                            else
                                plugin_OnBackupError
                                backup_printError "Error while finishing backup!"
                            fi
                        fi
                    else
                        plugin_OnBackupError
                        backup_printError "Error while verifying backup!"
                    fi # Backup check
                else
                    plugin_OnBackupError
                    backup_printError "Error while performing backup!"
                    backup_showLogTrace
                fi
            fi # Pre section
        else
            backup_printError "Error initializing specific plugin task!"
        fi # Plugin init successful?

        plugin_Shutdown
        if [ $? -ne "0" ]; then
            backup_printError "Error shutting down plugin!"
        fi
    fi # Plugin pre init
    backup_Uninit # Skip return value
fi # Backup init

