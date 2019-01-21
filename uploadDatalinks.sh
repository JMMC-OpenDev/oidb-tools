#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

# Main program entry point
CURRENTDATE=$(date -uIs)
CURRENTDATE=${CURRENTDATE%%+*}
datalinksfile=$MIRROR_ROOT/datalinkstoupload-$CURRENTDATE.xml


echo "- Create whole datalink file into $datalinksfile..."
echo "<datalinks>" > $datalinksfile
find $DATALINK_FILES_ROOT_DIR -name "*.xml" | while read datalinkfile; do cat $datalinkfile >> $datalinksfile; done
echo "</datalinks>" >> $datalinksfile
echo "Done"


echo "- Create whole datalink file into $datalinksfile..."
curl -n -H 'Content-type:application/xml' --data @$datalinksfile $SERVER/restxq/oidb/datalink
echo "Done"