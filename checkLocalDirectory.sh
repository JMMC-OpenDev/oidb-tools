#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

# Main program entry point
CURRENTDATE=$(date -uIs)
CURRENTDATE=${CURRENTDATE%%+*}
datalinksfile=$MIRROR_ROOT/datalinkstoupload-$CURRENTDATE.xml


echo "- Checking data collected into $MIRROR_ROOT ..."

#imkdirIfMissing "$GRANULE_FILES_ROOT_DIR" "$COLLECTIONS_ROOT_DIR" "$DATALINK_FILES_ROOT_DIR/secure" "$DATALINK_FILES_ROOT_DIR/public" "$OIFITS_ROOT_DIR" 

#echo -n "  - # oifits files : "
#find $OIFITS_ROOT_DIR -name "*fits" |wc -l
echo -n "  - # granules files : "
find $GRANULE_FILES_ROOT_DIR -name "*.xml" |wc -l
echo -n "  - # meta files     : "
find $DATALINK_FILES_ROOT_DIR -name "*.xml" |wc -l
echo -n "  - # oixp files     : "
find $DATALINK_FILES_ROOT_DIR -name "*.oixp" |wc -l
echo -n "  - # png files      : "
find $DATALINK_FILES_ROOT_DIR -name "*.png" |wc -l
echo -n "  - # png.log files  : "
find $DATALINK_FILES_ROOT_DIR -name "*.png.log" |wc -l
echo -n "  - # png.err files  : "
find $DATALINK_FILES_ROOT_DIR -name "*.png.err" |wc -l
echoDone


echoDone
