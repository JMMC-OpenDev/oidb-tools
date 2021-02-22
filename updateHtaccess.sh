#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

# Main program entry point
CURRENTDATE=$(date -uIs)
CURRENTDATE=${CURRENTDATE%%+*}

# get list of SECURED_COLLECTIONS to iterate onto
source $ENV_GRANULES_FILE

HTACCESSDIR=${DATALINK_FILES_ROOT_DIR}/secure
HTACCESSFILE=${HTACCESSDIR}/.htaccess.$CURRENTDATE

echo "- Create .htaccess file into $HTACCESSDIR ..."
cd $HTACCESSDIR

# create header file 
cat << EOFa > $HTACCESSFILE 
AuthName "OIDB reduced data in restricted access please provide login/pwd"
AuthUserFile /data/auth/htpasswd
AuthType Basic

<Limit GET>
  require user jmmcpoweruser
</Limit>

<Files "*.log">
  Allow from all
  Satisfy any
</Files>

<Files "*.oixp">
  Allow from all
  Satisfy any
</Files>

EOFa

# and loop for every secured collection
for col in $SECURED_COLLECTIONS
do
  ht=.htaccess.${col//\//_}
  echo -n "  - requesting htaccess for '$col' collection on $SERVER in '$ht'"
  if [ "$col" = "PIONIERgngngngng" ] 
  then 
    echo "skipp $col"
  elif curl -n -o $ht "$SERVER/modules/htaccess.xql?obs_collection=$col" &> /dev/null
  then
    echo -e " \t[OK]"
    cat $ht >> $HTACCESSFILE
  else
    echo " [ERROR] aborting for '$col'"
    exit 1
  fi
done

cp $HTACCESSFILE .htaccess
echo "  $PWD/.htaccess installed"

cd - &>/dev/null

echoDone
