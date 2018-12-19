#!/bin/bash

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

function syncCollection(){
  COLLECTION="$1"

  NORM_COLL_NAME=$(normCollName $COLLECTION)
  COLL_PATH=$MIRROR_ROOT/$NORM_COLL_NAME
  mkdirIfMissing "$COLL_PATH"
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
# Create meta data file or skip if already present
# if metadata filename is not given, using ${1}.xml
#
function genMeta(){
    OIFITS_FILE="$1"
    OIFITS_META="${2:-$1.xml}"
    if [ ! -e "${OIFITS_META}" ] 
    then 
        java -cp $OITOOLS_JAR fr.jmmc.oitools.OIFitsViewer "${OIFITS_FILE}" > "${OIFITS_META}"
    fi
}

#
# Create datalink files or skip if already present
# if metadata filename is not given, using ${1}.xml
#
function genDatalinks(){
    OIFITS_FILE="$1"
    DATALINK_DIR=$OIFITS_FILE.datalinks
    mkdirIfMissing $DATALINK_DIR
}



function syncFileFromUrl(){
  URL="$1"
  COLLECTION="$2"

  # Fix internal URLS:
  if ! echo $URL | grep "://" &> /dev/null 
  then
    URL=$SERVER$URL
  fi

  # define valid names and paths
  NORM_URL=$(urlToFilename $URL)
  NORM_COLLNAME=$(normCollName $COLLECTION)
  COLL_PATH=$MIRROR_ROOT/$NORM_COLLNAME
  MIRROR_FILENAME="$COLL_PATH/$NORM_URL"

  #prepare parent dir
  mkdirIfMissing "$(dirname $MIRROR_FILENAME)"

  # Download if not present
  if [ ! -f "$MIRROR_FILENAME" ] ; then 
      if ! wget -q $URL -O $MIRROR_FILENAME
      then 
          echo "ERROR: can't retrieve $URL into $MIRROR_FILENAME"
          return 1
      fi
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

# retrieve collections
COLLECTIONS_URL=${SERVER}/restxq/oidb/collection
if ! wget -q $COLLECTIONS_URL -O collections.xml ; then echo "ERROR: Can not retrieve collections ($COLLECTIONS_URL)... exiting!" ; exit ; fi

# retrieve files ( votable -> csv )
ACCESS_URLS=${SERVER}/restxq/oidb/mirror/access_urls
if ! wget -q $ACCESS_URLS -O access_urls.vot ; then echo "ERROR: Can not retrieve access_urls ($ACCESS_URLS)... exiting!" ; exit ; fi
xml sel -N VOT="http://www.ivoa.net/xml/VOTable/v1.2" -t -m "//VOT:TR" -v "VOT:TD[1]" -o " " -v "VOT:TD[2]" -n access_urls.vot > access_urls.txt


# prepare collection directory 
echo "Syncing collections into $MIRROR_ROOT ..."
xml sel -t -m "//collection" -v "@id" -n collections.xml | while read collection; do syncCollection $collection ; done
echo "Done"

# synchronize remote urls onto local mirror
echo "Syncing '$SERVER' files into $MIRROR_ROOT ..."
cat access_urls.txt | while read url collection; do syncFileFromUrl $url $collection ; done
echo "Done"

# generate metadata files 
echo "Generate metadata files ..."
find . -name "*.*fits" | while read file; do genMeta $file ; done
echo "Done"

# generate datalink files
echo "Generate datalink files ..."
find . -name "*.*fits" | while read file; do genDatalinks $file ; done
echo "Done"
