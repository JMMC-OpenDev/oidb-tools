#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

# Main program entry point
CURRENTDATE=$(date -uIs)
CURRENTDATE=${CURRENTDATE%%+*}
datalinksfile=$MIRROR_ROOT/datalinkstoupload-$CURRENTDATE.xml


echo "- Checking data collected into $MIRROR_ROOT ..."

#imkdirIfMissing "$GRANULE_FILES_ROOT_DIR" "$COLLECTIONS_ROOT_DIR" "$DATALINK_FILES_ROOT_DIR/secure" "$DATALINK_FILES_ROOT_DIR/public" "$OIFITS_ROOT_DIR" 

echo -n "  - # granules files : "
find $GRANULE_FILES_ROOT_DIR -name "*.xml" |wc -l
echo -n "  - # png files      : "
find $DATALINK_FILES_ROOT_DIR -name "*.png" |wc -l
echo -n "  - # oixp files     : "
find $DATALINK_FILES_ROOT_DIR -name "*.oixp" |wc -l
echoDone
echo "- Checking log files without associated file ..."
find $MIRROR_ROOT -name "*.log" | while read i ; do j=${i%%.log} ; if  [ ! -e "$j" ] ; then echo $i ; fi ; done | wc -l
echo "run next command to get details:"
echo "find $MIRROR_ROOT -name "*.log" | while read i ; do j=${i%%.log} ; if  [ ! -e "$j" ] ; then echo $i ; fi ; done "
echo


echoDone
