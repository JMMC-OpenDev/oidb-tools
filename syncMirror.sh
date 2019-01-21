#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

function syncCollection(){
  if [ -z "$1" ] ; then return ; fi # ignore op without args 

  COLLECTION="$1"

  NORM_COLL_NAME=$(normCollName $COLLECTION)
  COLL_PATH=$COLLECTIONS_ROOT_DIR/$NORM_COLL_NAME
  COLL_META=${COLL_PATH}.xml
  COLL_METAURL=${COLLECTIONS_URL}/$(uriencode $COLLECTION)

  printf " - %-50s" $NORM_COLL_NAME.xml 
  if [ ! -f "$COLL_META" ] ; then 
      if ! wget -q $COLL_METAURL -O ${COLL_META}
      then 
          echo "ERROR: can't retrieve $COLLECTION meta from $COLL_METAURL"
      else
          echo -n "retrieved : "
      fi
  else
          echo -n "present : "
  fi
  xml sel -t -v "//title" $COLL_META
}

#
#
#
function genOIXP(){
  # TODO select proper template : oidb-template-low_res.oixp or oidb-template-med_high_res.oixp
  # may depend on META_EM_RES_POWER....
  OIXP_TMPL=$SCRIPT_ROOT/oidb-template-low_res.oixp
  
  cp $OIXP_TMPL $GRANULE_OIXP
  # update fields 
  # TODO fixx all field updates
  xml ed -L -u "//file/name" -v "$(basename $OIFITS_FILE)" -u "//file/file" -v "$OIFITS_FILE" -u "//target/target" -v "$META_TARGET_NAME" -u "//filter/targetUID" -v "$META_TARGET_NAME" $GRANULE_OIXP
}

#
#
#
function genPNG(){
  java -Djava.awt.headless=true -jar  $OITOOLS_JAR -png $GRANULE_PNG -mode single -dims 1200,800 -open $GRANULE_OIXP &> ${GRANULE_PNG}.log
}

#
# Build xml fragment for png file
#
function genDATALINK(){
  #OIFITS_FILE
  #GRANULE_OIXP
  #GRANULE_PNG
  # TODO test if file is present ?
  ACCESS_URL=${DATALINK_FILES_ROOT_URL}/${META_DATA_RIGHTS}/$(basename $GRANULE_PNG)
  CONTENT_LENGTH=$(stat -c '%s' $GRANULE_PNG)
  if [ -e "$GRANULE_PNG" ]
  then
      echo "<datalink id='${META_ID}'> <access_url>$ACCESS_URL</access_url> <description>Quick plot</description> <content_type>application/png</content_type> <content_length>$CONTENT_LENGTH</content_length></datalink>" > $DATALINK_FILE
  fi

}


#
# Create datalink files per granules from a given ofits or skip if already present
#
function genDatalinksFromGranule(){
  if [ -z "$1" ] ; then return ; fi # ignore op without args 

  GRANULE_ENV="$1"
  source $GRANULE_ENV # load metadata as META_xxx variables

 
  # define env var for subcommands
  OIFITS_FILE=$(syncFileFromUrl "${META_ACCESS_URL}")
  GRANULE_OIXP="${DATALINK_FILES_ROOT_DIR}/${META_DATA_RIGHTS}/granule_$META_ID.oixp"
  GRANULE_PNG="${GRANULE_OIXP/.oixp/.png}"
  DATALINK_FILE="${DATALINK_FILES_ROOT_DIR}/${META_DATA_RIGHTS}/datalinks_$META_ID.xml"
  if [ ! -e "$GRANULE_OIXP" ] ; then genOIXP ; fi
  if [ ! -e "$GRANULE_PNG" ] ; then genPNG ; fi
  if [ ! -e "$DATALINK_FILE" ] ; then genDATALINK ; fi
  genDATALINK 
}


function genGranuleFiles(){
  cd $GRANULE_FILES_ROOT_DIR
  xsltproc $SCRIPT_ROOT/splitGranules.xsl $MIRROR_ROOT/granules.xml
# local job couldbe mimiced using next command
#    java -cp $OITOOLS_JAR fr.jmmc.oitools.OIFitsViewer "${OIFITS_FILE}" > "${OIFITS_META}"
# 2019-01-11 and we know that matching is now always the same : some value were hardcoded
# during submissions by metadata (iota) 
  cd - &> /dev/null
}

function getGranuleFile(){
  if [ -z "$1" ] ; then return ; fi # ignore op without args 
  GRANULE_ID="$1"
  echo $GRANULE_FILES_ROOT_DIR/granule_${GRANULE_ID}.xml
}

function syncFileFromUrl(){
  if [ -z "$1" ] ; then return ; fi # ignore op without args 
  URL="$1"

  # Fix internal URLS:
  if ! echo $URL | grep "://" &> /dev/null 
  then
    URL=$SERVER$URL
  fi

  # define valid names and paths
  NORM_URL=$(urlToFilename $URL)
  MIRROR_FILENAME="$OIFITS_ROOT_DIR/$NORM_URL"

  #prepare parent dirs
  mkdirIfMissing "$(dirname $MIRROR_FILENAME)" 

  # Download if not present
  if [ ! -f "$MIRROR_FILENAME" ] ; then 
      if ! wget -q $URL -O $MIRROR_FILENAME
      then 
          echo "ERROR: can't retrieve $URL into $MIRROR_FILENAME"
          return 1
      fi
  fi
  echo $MIRROR_FILENAME
}

# Main program entry point

# check that we have got an associated MIRROR directory
if [ ! -d "$MIRROR_ROOT" ] 
then 
   echo "ERROR: Can not find MIRROR_ROOT at '$MIRROR_ROOT'. Please create the directory before or change your env.sh"
   exit 
fi

cd $MIRROR_ROOT
echo "- Working into $MIRROR_ROOT"

# retrieve collections
COLLECTIONS_URL=${SERVER}/restxq/oidb/collection
if ! wget -q $COLLECTIONS_URL -O collections.xml ; then echo "ERROR: Can not retrieve collections ($COLLECTIONS_URL)... exiting!" ; exit ; fi

# prepare collection directories 
echo "- Syncing collections ..."
xml sel -t -m "//collection" -v "@id" -n collections.xml | while read collection; do syncCollection $collection ; done
echo "Done"



echo "- Retrieve granules ..."
# retrieve files ( xml -> csv )
GRANULES_ENDPOINT=${SERVER}/restxq/oidb/mirror/granules
# TODO add -f option to force resync
if [ ! -e granules.xml ] 
then 
  if ! wget $GRANULES_ENDPOINT -O granules.xml ; then echo "ERROR: Can not retrieve granules ($GRANULES_ENDPOINT)... exiting!" ; exit ; fi
  echo "Done"
else
  echo "Skipped"
fi

# synchronize remote urls onto local mirror
echo "- Build granule files ..."
genGranuleFiles
echo "Done"

# generate datalink files from granule files
echo "- Generate datalink files (this also download the file if not yet present) ..."
find $GRANULE_FILES_ROOT_DIR -name "*.env" | while read granulefile; do genDatalinksFromGranule $granulefile ; done
echo "Done"
