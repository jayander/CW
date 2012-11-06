#!/bin/sh

. ./acdp.properties

log() 
{
    date_for_log=`date "+%d-%m-%Y %T"`
    echo $date_for_log - "$@" | tee -a ${SCRIPT_LOG}
}

log "RESTORING DEFAULT PORTAL"

if [ ! -d ${WEB_APP_DIR} ]
then
	log "Webapps directory [ $WEB_APP_DIR ] does not exists , please make sure ACDP Portal is installed on this host."
	
	log "RESTORE ABORTED"
	
	exit -1
fi

if [ ! -d ${WEB_APP_DIR}.original ]
then
	log "There is no original directory [${WEB_APP_DIR}.original] on this host"
	
	log "NOTHING TO RESTORE"
	
	exit -1
fi

if [ ! -w ${WEB_APP_DIR} ]
then
	log "Webapps directory [ $WEB_APP_DIR ] does not have write permission , Please login as root user"
	
	log "RESTORE ABORTED"
	
	exit -1
fi


mv ${WEB_APP_DIR} ${WEB_APP_DIR}.`date "+%d-%m-%Y-%T"`

log "Renamed exisiting ${WEB_APP_DIR}"

mv ${WEB_APP_DIR}.original ${WEB_APP_DIR}

log "Renamed ${WEB_APP_DIR}.original to ${WEB_APP_DIR}"

log "Restarting the tomcat server"

$TOMCAT_BIN_DIR/config.sh

log "Tomcat restarted"

log "RESTORATION COMPLETE"