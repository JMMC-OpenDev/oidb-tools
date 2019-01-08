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
# metadata filename suffix OIFITS file with .xml
#
function genMeta(){
    OIFITS_FILE="$1"
    OIFITS_META="${OIFITS_FILE}.xml"
    OIFITS_GRANULES="${OIFITS_FILE}.granules"
    OIFITS_URL=$(cat ${OIFITS_FILE}.url | tr -d "\n")

    # generate main metadata file
    if [ ! -e "${OIFITS_META}" ] 
    then 
        java -cp $OITOOLS_JAR fr.jmmc.oitools.OIFitsViewer "${OIFITS_FILE}" > "${OIFITS_META}"
    fi

#   <target>
#   <target_name>v1295_Aql</target_name>
#   <s_ra>300.75834000000003</s_ra>
#   <s_dec>5.737778</s_dec>
#   <t_exptime>0.0</t_exptime>
#   <t_min>52808.357037037145</t_min>
#   <t_max>52808.42348379642</t_max>
#   <em_res_power>6.6666665</em_res_power>
#   <em_min>1.65E-6</em_min>
#   <em_max>1.65E-6</em_max>
#   <facility_name>IOTA_AB</facility_name>
#   <instrument_name>IONIC3_v1</instrument_name>
#   <nb_vis>0</nb_vis>
#   <nb_vis2>33</nb_vis2>
#   <nb_t3>11</nb_t3>
#   <nb_channels>1</nb_channels>
#   </target>


    # transform into xml granules
    if [ ! -e "${OIFITS_GRANULES}" ] 
    then 
    if ! xml sel -I -t -e granules \
            -m //target -e granule -c "./*" \
            -e access_url        -o "${OIFITS_URL}" -b \
            -e access_estsize    -v 'floor(//size div 1000)' -b \
            -e access_format     -o "application/fits" -b \
            $OIFITS_META > $OIFITS_GRANULES
# TO FIX or retrieve on oidb
#            -e obs_collection    -o "$COLLECTION" -b \
#            -e obs_id            -v "//keyword[name='HIERARCH.ESO.OBS.PROG.ID']/value" -b \
#            -e obs_publisher_did -o "$OBS_PUBLISHER_DID" -b \
#            -e obs_creator_name  -o "$OBS_CREATOR_NAME" -b \
#            -e calib_level       -o "$CALIBLEVEL" -b \
#            -e data_rights       -o "$DATA_RIGHTS" -b \
#            -m "//keyword[starts-with(name,'ASSON')]" -e datalink -e access_url -v "concat('$BASEURL', '/',value)" -b -c "document(concat('meta/',value,'.xml'))/meta/*" -b \
        then
        echo "ERROR: pb during parsing of $OIFITS_META "
        exit 1
        fi
    fi
     
}

#
#
#
function genOIXP(){
  OIFITS_FILE="${1}"
  GRANULE_XML="${2}"
  GRANULE_OIXP="${3}"
  
  # TODO select proper template : oidb-template-low_res.oixp or oidb-template-med_high_res.oixp
  OIXP_TMPL=$SCRIPT_ROOT/oidb-template-low_res.oixp
  
  cp $OIXP_TMPL $GRANULE_OIXP
  TARGET_NAME=$(xml sel -t -v "//target_name" $GRANULE_XML)
  # update fields 
  # TODO fixx all field updates
  xml ed -L -u "//file/name" -v "$(basename $OIFITS_FILE)" -u "//file/file" -v "$OIFITS_FILE" -u "//target/target" -v "$TARGET_NAME" -u "//filter/targetUID" -v "$TARGET_NAME" $GRANULE_OIXP
}

#
#
#
function genPNG(){
  GRANULE_OIXP="${1}"
  GRANULE_PNG="${GRANULE_OIXP/.oixp/.png}"
  echo java -jar $OITOOLS_JAR -png $GRANULE_PNG -mode single -dims 1200,800 -open $GRANULE_OIXP
}

#
# Create datalink files per granules or skip if dir already present
#
function genDatalinks(){
    OIFITS_FILE="$1"
    OIFITS_META="${OIFITS_FILE}.xml"
    OIFITS_GRANULES="${OIFITS_FILE}.granules"
    DATALINK_DIR=$OIFITS_FILE.datalinks
    mkdirIfMissing $DATALINK_DIR

    GRANULES_CNT=$(xml sel -t -v "count(//granule)" $OIFITS_GRANULES)
    
    for g in $( seq 1 $GRANULES_CNT )
    do
        GRANULE_PREFIX=$DATALINK_DIR/granule${g}
        GRANULE_XML=$GRANULE_PREFIX.xml
        GRANULE_OIXP="${GRANULE_XML/.xml/.oixp}"
        GRANULE_PNG=$GRANULE_PREFIX.png
        if [ ! -e "$GRANULE_PNG" ] 
        then
            xml sel -t -c "//granule[$g]" $OIFITS_GRANULES > $GRANULE_XML
            genOIXP $OIFITS_FILE $GRANULE_XML $GRANULE_OIXP
            genPNG  $GRANULE_OIXP
        fi
    done

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
  MIRROR_FILENAME_URL=$MIRROR_FILENAME.url

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
  if [ ! -f "$MIRROR_FILENAME_URL" ] ; then 
      echo $URL > $MIRROR_FILENAME_URL
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
#cat access_urls.txt | while read url collection; do syncFileFromUrl $url $collection ; done
echo "Done"

# generate metadata files 
echo "Generate metadata files ..."
find . -name "*.*fits" | while read file; do genMeta $file ; done
echo "Done"

# generate datalink files
echo "Generate datalink files ..."
find . -name "*.*fits" | while read file; do genDatalinks $file ; done
echo "Done"
