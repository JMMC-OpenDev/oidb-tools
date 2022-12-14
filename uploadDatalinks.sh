#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

# Main program entry point
CURRENTDATE=$(date -uIs)
CURRENTDATE=${CURRENTDATE%%+*}
datalinksfile=$MIRROR_ROOT/datalinkstoupload-$CURRENTDATE.xml

echo "- Create whole datalink file from '$DATALINK_FILES_ROOT_DIR' into '$datalinksfile'..."
echo "<datalinks>" > $datalinksfile
find $DATALINK_FILES_ROOT_DIR -name "*.xml" | while read datalinkfile; do if [ $datalinkfile -nt $XML_GRANULES_FILE ] ; then cat $datalinkfile >> $datalinksfile; fi ; done
echo "</datalinks>" >> $datalinksfile
echoDone


echo "- Upload datalink file onto '$SERVER' ..."
echo curl -n -H 'Content-type:application/xml' --data @$datalinksfile $SERVER/restxq/oidb/datalink


echo "WARNING: please do not move the DATALINKS directory which is (the inode) certainly in use on the data container(s)"
echoDone
