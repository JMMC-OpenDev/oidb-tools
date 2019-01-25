#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

function syncCollection(){
  installTrap
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
# Choose med-high or low mode template depending on NB_CHANNELS meta
#
function genOIXP(){
  installTrap
  if [ "$META_NB_CHANNELS" -gt 8 ] ; 
  then 
      OIXP_TMPL=$SCRIPT_ROOT/oidb-template-med_high_res.oixp
  else
      OIXP_TMPL=$SCRIPT_ROOT/oidb-template-low_res.oixp
  fi
  cp $OIXP_TMPL $GRANULE_OIXP
  xml ed -L -u "//file/name" -v "$(basename $OIFITS_FILE)" -u "//file/file" -v "$OIFITS_FILE" -u "//filter/targetUID" -v "$META_TARGET_NAME" -u "//filter/insModeUID" -v "$META_INSTRUMENT_NAME" -u "//filter/nightID" -v "$METAX_NIGHTID" $GRANULE_OIXP
  echo -ne "Generate OIXP : $GRANULE_OIXP \r"
}

#
#
#
function genPNG(){

  if ! java -Djava.awt.headless=true -Dfix.bad.uid=true -jar  $OITOOLS_JAR -png $GRANULE_PNG -mode single -dims 1200,800 -open $GRANULE_OIXP &> ${GRANULE_PNG}.log
  then 
      mv ${GRANULE_PNG}.log ${GRANULE_PNG}.err
      echo  "Can't generate PNG : $GRANULE_PNG"
  fi
}

#
# Build xml fragment for png file
#
function genDATALINK(){
  installTrap
  #OIFITS_FILE
  #GRANULE_OIXP
  #GRANULE_PNG
  ACCESS_URL=${DATALINK_FILES_ROOT_URL}/${META_DATA_RIGHTS}/$(basename $GRANULE_PNG)
  if [ -e "$GRANULE_PNG" ]
  then
      CONTENT_LENGTH=$(stat -c '%s' $GRANULE_PNG)
      echo "<datalink id='${META_ID}'> <access_url>$ACCESS_URL</access_url> <description>Quick plot</description> <content_type>application/png</content_type> <content_length>$CONTENT_LENGTH</content_length></datalink>" > $DATALINK_FILE
      else
      rm $DATALINK_FILE
  fi
}


#
# Create datalink files per granules from a given ofits or skip if already present
#
function genDatalinksFromGranule(){
  installTrap
  if [ -z "$1" ] ; then return ; fi # ignore op without args 

  GRANULE_ENV="$1"
  source $GRANULE_ENV # load metadata as META_xxx variables

#  if [ "$META_OBS_COLLECTION" = "PIONIER" ]
#  then
#    echo -ne "genDatalinksFromGranule IGNORE $META_OBS_COLLECTION for collection $META_OBS_COLLECTION\r"
#    return
#  else
    echo -ne "genDatalinksFromGranule $META_OBS_COLLECTION"
#  fi

  URL="$(fixUrl ${META_ACCESS_URL} ${SERVER})"
  # define valid names and paths
  NORM_URL=$(urlToFilename $URL)
  OIFITS_FILE="$OIFITS_ROOT_DIR/$NORM_URL"
 
  GRANULE_OIXP="${DATALINK_FILES_ROOT_DIR}/${META_DATA_RIGHTS}/granule_$META_ID.oixp"
  GRANULE_PNG="${GRANULE_OIXP/.oixp/.png}"
  DATALINK_FILE="${DATALINK_FILES_ROOT_DIR}/${META_DATA_RIGHTS}/datalinks_$META_ID.xml"

  # Download if not present
  if [ ! -s "$OIFITS_FILE" ] ; then 
      # cleanup children files
      rm $GRANULE_OIXP $GRANULE_PNG $GRANULE_PNG.log $DATALINK_FILE &> /dev/null
      syncFileFromUrl  "$URL" "$OIFITS_FILE" || return $?
  fi
  if [ ! -s "$GRANULE_OIXP" ] ; then genOIXP ; fi
  if [ ! -s "$GRANULE_PNG" ] ; then genPNG ; fi
  if [ ! -e "$DATALINK_FILE" ] ; then genDATALINK ; fi
}


function genGranuleFiles(){
  installTrap
  cd $GRANULE_FILES_ROOT_DIR
  xsltproc $SCRIPT_ROOT/splitGranules.xsl $MIRROR_ROOT/granules.xml
# local job couldbe mimiced using next command
#    java -cp $OITOOLS_JAR fr.jmmc.oitools.OIFitsViewer "${OIFITS_FILE}" > "${OIFITS_META}"
# 2019-01-11 and we know that matching is now always the same : some value were hardcoded
# during submissions by metadata (iota) 
  cd - &> /dev/null
}

function getGranuleFile(){
  installTrap
  if [ -z "$1" ] ; then return ; fi # ignore op without args 
  GRANULE_ID="$1"
  echo $GRANULE_FILES_ROOT_DIR/granule_${GRANULE_ID}.xml
}

function syncFileFromUrl(){
  installTrap
  if [ -z "$1" ] ; then return ; fi # ignore op without args 
  URL="$1"
  MIRROR_FILENAME="$2"

  #prepare parent dirs
  mkdirIfMissing "$(dirname $MIRROR_FILENAME)"  

  if ! wget -q $URL -O $MIRROR_FILENAME
  then 
      echo "ERROR: can't retrieve $URL into $MIRROR_FILENAME"
      return 1
  else 
      echo "INFO: '$MIRROR_FILENAME' retrieved"
  fi
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
echoDone



echo "- Retrieve granules ..."
# retrieve files ( xml -> csv )
GRANULES_ENDPOINT=${SERVER}/restxq/oidb/mirror/granules
# TODO add -f option to force resync
if [ ! -e granules.xml ] 
then 
  if ! wget $GRANULES_ENDPOINT -O granules.xml ; then echo "ERROR: Can not retrieve granules ($GRANULES_ENDPOINT)... exiting!" ; exit ; fi
  echoDone
else
  echo "Skipped"
fi

# synchronize remote urls onto local mirror
echo "- Build granule files ..."

if [ "$GRANULE_FILES_ROOT_DIR" -ot "granules.xml" ]
then
  genGranuleFiles
  echoDone
else 
  echo "Skipped"
fi

# generate datalink files from granule files
echo "- Generate datalink files (this also download the file if not yet present) ..."
find $GRANULE_FILES_ROOT_DIR -name "*.env" | while read granulefile; do genDatalinksFromGranule $granulefile ; done
echoDone
