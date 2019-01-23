#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

# Main program entry point
CURRENTDATE=$(date -uIs)
CURRENTDATE=${CURRENTDATE%%+*}

#TODO extract list of collections to iterate onto from granules.xml
SECURED_COLLECTIONS="PIONIER iota"

HTACCESSDIR=${DATALINK_FILES_ROOT_DIR}/secure
HTACCESSFILE=${HTACCESSDIR}/.htaccess.$CURRENTDATE

echo "- Create .htaccess file into $HTACCESSDIR..."
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
  echo -n "  - requesting htaccess for '$col' collection"
  if curl -n -o .htaccess.$col $SERVER/modules/htaccess.xql?obs_collection=$col &> /dev/null
  then
    echo -e " \t[OK]"
    cat .htaccess.$col >> $HTACCESSFILE
  else
    echo " [ERROR] aborting"
    exit 1
  fi
done

cp $HTACCESSFILE .htaccess

cd - &>/dev/null

echoDone
