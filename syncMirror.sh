#!/bin/bash



uriencode() {
    s="${1//'%'/%25}"
    s="${s//' '/%20}"
    s="${s//'"'/%22}"
    s="${s//'#'/%23}"
    s="${s//'$'/%24}"
    s="${s//'&'/%26}"
    s="${s//'+'/%2B}"
    s="${s//','/%2C}"
    s="${s//'/'/%2F}"
    s="${s//':'/%3A}"
    s="${s//';'/%3B}"
    s="${s//'='/%3D}"
    s="${s//'?'/%3F}"
    s="${s//'@'/%40}"
    s="${s//'['/%5B}"
    s="${s//']'/%5D}"
    printf %s "$s"
}

function urlToFilename(){
    URL="$1"
    # remove schem part
    echo "${URL##*://}"
}

function normCollName(){
# Mimic StringUtils.java
# /** regular expression used to match characters different than * alpha/numeric/_/-/. (1..n) */
#     private final static Pattern PATTERN_NON_FILE_NAME = Pattern.compile("[^a-zA-Z0-9\\-_\\.]");
    echo -n "$*" | tr -c "[^a-zA-Z0-9\\-_\\.]" "_"
}

function mkdirIfNotPresent(){
  for DIR_PATH in $* 
  do
      if [ ! -d "$DIR_PATH" ] ; then mkdir -pv $DIR_PATH ; fi
  done
}

function syncCollection(){
  COLLECTION="$1"

  NORM_COLL_NAME=$(normCollName $COLLECTION)
  COLL_PATH=$MIRROR_ROOT/$NORM_COLL_NAME
  mkdirIfNotPresent "$COLL_PATH"
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

function syncUrl(){
  URL="$1"
  COLLECTION="$2"

  # Fix internal URLS:
  if ! echo $URL | grep "://" &> /dev/null 
  then
    URL=$SERVER$URL
  fi

  NORM_URL=$(urlToFilename $URL)
  NORM_COLLNAME=$(normCollName $COLLECTION)
  COLL_PATH=$MIRROR_ROOT/$NORM_COLLNAME
  MIRROR_PATH="$COLL_PATH/$NORM_URL"
  #prepare parent dir
  mkdirIfNotPresent "$(dirname $MIRROR_PATH)"

  # Download if not present
  if [ ! -f "$MIRROR_PATH" ] ; then 
      if ! wget -q $URL -O $MIRROR_PATH
      then 
          echo "ERROR: can't retrieve $URL into $MIRROR_PATH"
      fi
  fi

}

SCRIPT_ROOT=$(dirname $(readlink -f $0))
source $SCRIPT_ROOT/env.sh

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
cat access_urls.txt | while read url collection; do syncUrl $url $collection ; done
echo "Done"


