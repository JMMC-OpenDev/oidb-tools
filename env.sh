# sourced by tool's scripts:
# using next code
# SCRIPT_ROOT=$(dirname $(readlink -f $0))
# source $SCRIPT_ROOT/env.sh
# you can run your command with ENV=<type> to_run_it_in_right_env.sh

# source common functions
source $SCRIPT_ROOT/functions.sh
installTrap 

# Env dependant Part
case "$ENV" in 
  localhost ) export SERVER=http://localhost/exist/apps/oidb ;; 
  local8080 ) export SERVER=http://localhost:8080/exist/apps/oidb ;; 
  prod) export SERVER=http://oidb.jmmc.fr ;;
  preprod) export SERVER=http://oidb-preprod.jmmc.fr ;;
  *) export SERVER=http://oidb-beta.jmmc.fr ; export ENV=beta ;; 
esac

# Common Part
echo "Running in $ENV mode (switch using $ ENV=<prod|beta> yourcommand) on $(date)"

# Define mirror root for given server
MIRROR_ROOT=$(readlink -m "$SCRIPT_ROOT/../oidb-mirror/$( urlToFilename $SERVER)")


# Define OIExplorerJar
OITOOLS_JAR=$SCRIPT_ROOT/OIFitsExplorer.jar

export PATH=~bourgesl/jdk1.8.0_121/bin:$PATH
#echo "PATH modified : $PATH"


# Define common directories and root urls
GRANULE_FILES_ROOT_DIR=$MIRROR_ROOT/OIDB-GRANULES
GRANULE_FILES_ROOT_URL=${SERVER}/OIDB-GRANULES
COLLECTIONS_ROOT_DIR=$MIRROR_ROOT/OIDB-COLLECTIONS
COLLECTIONS_ROOT_URL=${SERVER}/OIDB-COLLECTIONS
DATALINK_FILES_ROOT_DIR=$MIRROR_ROOT/DATALINKS
DATALINK_FILES_ROOT_URL=${SERVER}/DATALINKS
OIFITS_ROOT_DIR=$MIRROR_ROOT/OIFITS
OIFITS_ROOT_URL=${SERVER}/OIFITS

mkdirIfMissing "$GRANULE_FILES_ROOT_DIR" "$COLLECTIONS_ROOT_DIR" "$DATALINK_FILES_ROOT_DIR/secure" "$DATALINK_FILES_ROOT_DIR/public" "$OIFITS_ROOT_DIR" 

