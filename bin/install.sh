#!/bin/sh

. ./acdp.properties

log() 
{
    date_for_log=`date "+%d-%m-%Y %T"`
    echo $date_for_log - "$@" | tee -a ${SCRIPT_LOG}
}



log "STARTING THE INSTALLATION"

if [ ! -d ${WEB_APP_DIR} ]
then
	log "Webapps directory [ $WEB_APP_DIR ] does not exists , please make sure ACDP Portal is installed on this host."
	
	log "INSTALLATION ABORTED"
	
	exit -1
fi

if [ ! -w ${WEB_APP_DIR} ]
then
	log "Webapps directory [ $WEB_APP_DIR ] is not writable , please login as different user."
	
	log "INSTALLATION ABORTED"
	
	exit -1
fi

# # #
#
#   CHECK PERMISSION FOR MODIFIED FILES
#
# # #

for fileName in `cat changed_files.txt`
do
    if [ -f ${WEB_APP_DIR}/${fileName} ]
    then
    	if [ ! -w ${WEB_APP_DIR}/${fileName} ]
    	then
    		log "File [${WEB_APP_DIR}/${fileName}] does not has write permission , Installation cannot proceed"
    	
    		log "INSTALLATION ABORTED"
		
		exit -1
    	fi
    fi
done


# # #
#
#   TAKING THE BACK UP 
#
# # #

if [ -d ${WEB_APP_DIR}.original ]
then
	log "Backup directory already exists"
else
	cp -R ${WEB_APP_DIR} ${WEB_APP_DIR}.original
	log "Backup directory created"
fi

BASE_DIR=`dirname $0`

FILES_DIR=${BASE_DIR}/../pages

for fileName in `cat changed_files.txt`
do
    if [ -f ${WEB_APP_DIR}/${fileName} ]
    then
        rm -rf ${WEB_APP_DIR}/${fileName}
        
        log "Deleted old file [${WEB_APP_DIR}/${fileName}]."
    fi    
    
    cp ${FILES_DIR}/${fileName} ${WEB_APP_DIR}/${fileName}
    
    log "Copied new file [${FILES_DIR}/${fileName}]."
    
done

log "Restarting the tomcat server"

$TOMCAT_BIN_DIR/config.sh

log "Tomcat restarted"

log "INSTALLATION COMPLETE"