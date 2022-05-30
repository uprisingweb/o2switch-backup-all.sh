# o2switch-backup-all.sh
Backup all directories (you can set exceptions) and databases from o2switch to a remote server

# Configure SSH connection to your remote server
**o2switch only works with port 22**

## On o2switch Cpanel 
go to Outils > Autorisation SSH and declare you remote server IP on port 22

## Open a terminal on o2switch Cpanel
Type `ssh-keygen`

set all to default with no password

Then type `ssh-copy-id -i .ssh/id_rsa.pub user_remoteserver@host_remoteserver.com`

this command autorize o2switch to communicate with you remote server

# Configure the script
## Create a directory where the script will tempory create the backup files (default o2switch-backup)
modify this line with you directory name : `BACKUP_PATH="o2switch-backup"`

All local files are deleted after being sent to remote server

## Database prefixe is your o2switch username followed by "_"
`BACKUP_O2S_DATABASE_PREFIXE="username_"`

Then if database is named 'username_databasename', the dumped file will be name 'databasename'

## Define list of directories you dont want to backup
EXCLUDE_DIR="0-htpasswd etc logs mail xxx $BACKUP_PATH"

Keep $BACKUP_PATH in the list to note backup the backup directory set in $BACKUP_PATH

## remote server IDs
SERVER_USER="user_remoteserver"
SERVER_HOST="host_remoteserver.com"
SERVER_DIR="/home/xxx/backupdirectory/"

## local Databases
The script will back up every database when a directory contains a  wordpress instance

For others type of website you need to create a database user named "backup" and give the SELECT / LOCK TABLES / SHOW VIEW right for each databases you need to back up (except wordpress databases)

Set user in `MYSQL_USER="xxxx"`
Set the password in `MYSQL_PWD="xxxx"`

## If you want to customize backup filenames
`BACKUP_PREFIXE_DB="Database"`, all databases dump will be prefixed 'Database-'

`BACKUP_PREFIXE_DIRECTORY="Files"`, all directories backup will be prefixed 'Files-'

`BACKUP_SUFFIXE_DATE=$(date '+%Y-%m-%d_%H-%M-%S')`, all backup files will be prefixed by the date

Ex : 
- 2022-01-01_00-00-00-File-MyBlog
- 2022-01-01_00-00-00-Database-MyBlog


# remote-delete-7days-backups.sh
This script can be used on you remote server to delete 7 days old backup files

## Usage
You need to change the backup directory in the script "remote-delete-7days-backups.sh"

You have to create a cron task to call this script every days

`0 0 * * * root /pathtoscript/remote-delete-7days-backups.sh >/dev/null 2>&1`




