#!/bin/bash
#
# Filename : o2switch_backup_all
# Description : Backup all Directories & Databases from O2switch then rysnc data to a remote server
# Author : Uprsing Web / Samuel Dupuy
#
# MADATORY 
# - with O2SWITCH you can only use port 22 with SSH
# - you must whitelist your remote server IP in CPanel > Outils > Autorisation SSH 
# 
# ADD A CRON TASK IN CPanel > Anvacé > Tâches Cron
# "1 fois par jour" 
# /home/xxxx/o2switch-backup.sh
#
#
#


## -------Start Config --------

### local backup directory on o2switch
### > create a specific directory via o2swtich FTP
BACKUP_PATH="o2switch-backup"
# Your O2Switch Nick
BACKUP_O2S_USER="nickxxx"
# database prefix, will be removed from dump archive filename for a better backup files ordering
BACKUP_O2S_DATABASE_PREFIXE=$BACKUP_O2S_USER"_"

# Define list of directories you dont want to backup separate with space
EXCLUDE_DIR="etc logs ssl mail tmp "$BACKUP_PATH
# INCLUDE_DIR="directory1"

### remote server
SERVER_USER="myuser"
SERVER_HOST="hostbackup.com"
SERVER_DIR="/home/xxx/backups/o2switch/"$BACKUP_O2S_USER

### local Databases
### All wordpress Databases will be automatically backed up
### If you need to back up others databases, create a database user named "backup" and give the SELECT / LOCK TABLES / SHOW VIEW right for each databases you need to back up (except wordpress databases)
MYSQL_USER="backup_user"
MYSQL_PWD="backup_user_pwd"
### don't modify this commande
if [ -z $MYSQL_USER ]; then
  MYSQL_DATABASES=`mysql --user=$MYSQL_USER --password=$MYSQL_PWD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database` 
fi

### Can be used with default values
BACKUP_PREFIXE_DB="Database"
BACKUP_PREFIXE_DIRECTORY="Files"
BACKUP_SUFFIXE_DATE=$(date '+%Y-%m-%d_%H-%M-%S')

## ------- End Config --------

# funtion if exist in list
function exists_in_list() {
    LIST=$1
    DELIMITER=$2
    VALUE=$3
    echo $LIST | tr "$DELIMITER" '\n' | grep -F -q -x "$VALUE"
}

# Check if backup directory exists
if [ ! -d $BACKUP_PATH ]; then
  echo "The directory $BACKUP_PATH does not exist."
  exit 99
fi

# FETCH AND COMPRESS DIRECTORIES
for i in $(ls -d */)
 do 
  if ! exists_in_list "$EXCLUDE_DIR" " " ${i%%/}
  # if exists_in_list "$INCLUDE_DIR" " " ${i%%/} 
  then
    echo "Backup Directory : ${i%%/}"
    #no verbose
    ARCHIVE_FILE="${BACKUP_SUFFIXE_DATE}-${BACKUP_PREFIXE_DIRECTORY}-${i%%/}.tar.gz"
    tar -czf $BACKUP_PATH/$ARCHIVE_FILE ${i%%/}
   
    # Wordpress
    if test -f "${i%%/}/wp-config.php"; then

      DATABASE=`cat ${i%%/}/wp-config.php | grep DB_NAME | cut -d \' -f 4`
      WP_DB_USER=`cat ${i%%/}/wp-config.php | grep DB_USER | cut -d \' -f 4`
      WP_DB_PWD=`cat ${i%%/}/wp-config.php | grep DB_PASSWORD | cut -d \' -f 4`
      
      DUMP_FILE="${BACKUP_SUFFIXE_DATE}-${BACKUP_PREFIXE_DB}-${DATABASE/$BACKUP_O2S_DATABASE_PREFIXE}.sql"

      echo "Backup Wordpress Database: ${DATABASE}"
      mysqldump --force --opt --routines --user=$WP_DB_USER --password=$WP_DB_PWD --databases $DATABASE > $BACKUP_PATH/$DUMP_FILE
      gzip $BACKUP_PATH/$DUMP_FILE

    fi
    # Dolibarr
    if test -f "${i%%/}/htdocs/conf/conf.php"; then

      DATABASE=`cat ${i%%/}/htdocs/conf/conf.php | grep dolibarr_main_db_name | cut -d \' -f 2`
      WP_DB_USER=`cat ${i%%/}/htdocs/conf/conf.php | grep dolibarr_main_db_user | cut -d \' -f 2`
      WP_DB_PWD=`cat ${i%%/}/htdocs/conf/conf.php | grep dolibarr_main_db_pass | cut -d \' -f 2`
      
      DUMP_FILE="${BACKUP_SUFFIXE_DATE}-${BACKUP_PREFIXE_DB}-${DATABASE/$BACKUP_O2S_DATABASE_PREFIXE}.sql"

      echo "Backup Dolibarr Database: ${DATABASE}"
      mysqldump --force --opt --routines --user=$WP_DB_USER --password=$WP_DB_PWD --databases $DATABASE > $BACKUP_PATH/$DUMP_FILE
      gzip $BACKUP_PATH/$DUMP_FILE

    fi
    # Prestashop
    if test -f "${i%%/}/app/config/parameters.php"; then

      DATABASE=`cat ${i%%/}/app/config/parameters.php | grep database_name | cut -d \' -f 4`
      WP_DB_USER=`cat ${i%%/}/app/config/parameters.php | grep database_user | cut -d \' -f 4`
      WP_DB_PWD=`cat ${i%%/}/app/config/parameters.php | grep database_password | cut -d \' -f 4`
      
      DUMP_FILE="${BACKUP_SUFFIXE_DATE}-${BACKUP_PREFIXE_DB}-${DATABASE/$BACKUP_O2S_DATABASE_PREFIXE}.sql"

      echo "Backup Prestashop Database: ${DATABASE}"
      mysqldump --force --opt --routines --user=$WP_DB_USER --password=$WP_DB_PWD --databases $DATABASE > $BACKUP_PATH/$DUMP_FILE
      gzip $BACKUP_PATH/$DUMP_FILE

    fi
  fi  
done

# FETCH, DUMP AND GZIP DATABASES
if [ -z $MYSQL_DATABASES ]; then
  for DATABASE in $MYSQL_DATABASES; do
      if [[ "$DATABASE" != "information_schema" ]] && [[ "$DATABASE" != _* ]] ; then

          DUMP_FILE="${BACKUP_SUFFIXE_DATE}-${BACKUP_PREFIXE_DB}-${DATABASE/$BACKUP_O2S_DATABASE_PREFIXE}.sql"

          echo "Backup Database: ${DATABASE}"
          mysqldump --force --opt --routines --user=$MYSQL_USER --password=$MYSQL_PWD --databases $DATABASE > $BACKUP_PATH/$DUMP_FILE
          gzip $BACKUP_PATH/$DUMP_FILE

      fi
  done
fi


# RSYNC LOCAL BACKUP TO REMOTE SERVER
rsync -avzr --rsh='ssh -p 22'  $BACKUP_PATH/ $SERVER_USER@$SERVER_HOST:$SERVER_DIR
echo "Rsync all backup files to remote server done."

# CLEAN LOCAL BACKUP DIRECTORY
rm $BACKUP_PATH/*.* -R
echo "Delete local backup files done."
