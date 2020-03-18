#!/bin/bash
echo "Please write your username which you use to connect through ssh"
read -p "Enter your username : " SSH_USERNAME
echo "Please, write the name of the database you need to do dump for"
read -p "Enter your database name : " DATABASE
#--
ssh $SSH_USERNAME@104.155.121.85 'bash -s'<<-'ENDSSH' $DATABASE   #< backup_script.sh mail-test
DATABASE=$1
#TABLE=$2
HOST="127.0.0.1"
PORT="27017"
TIMESTAMP=`date +%F-%H%M`
USERNAME=`whoami`
MONGODUMP_PATH="/usr/bin/mongodump"
BACKUP_NAME="$DATABASE-$TIMESTAMP"
BACKUPS_DIR="/home/$USERNAME/backups/$DATABASE"
mkdir -p $BACKUPS_DIR
cd $BACKUPS_DIR
$MONGODUMP_PATH -d $DATABASE --archive=$BACKUP_NAME --gzip
gsutil cp $BACKUP_NAME  gs://peytz-mail-dumps/$DATABASE/
ENDSSH
#---
sftp $SSH_USERNAME@104.155.121.85 <<-'ENDSFTP'
cd /home/victorniculin/backups/
get -r *
ENDSFTP

# In the future will be implemented:
# $MONGODUMP_PATH  --db $DATABASE --collection $TABLE
# rm -rf $BACKUP_NAME
# gsutil cp $BACKUP_NAME  gs://peytzmail-dumps/$DATABASE/
