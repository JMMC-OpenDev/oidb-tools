# sourced by tool's scripts:
# using next code
# SCRIPT_ROOT=$(dirname $(readlink -f $0))
# source $SCRIPT_ROOT/env.sh

# source common functions
source $SCRIPT_ROOT/functions.sh

# Env dependant Part
if [ "$ENV" = "prod" ]
then
  ENV=prod
  export SERVER=http://oidb.jmmc.fr
else
  ENV=beta
  export SERVER=http://oidb-beta.jmmc.fr
fi

# Common Part
echo "Running in $ENV mode (switch using $ ENV=<prod|beta> yourcommand)"

# Define mirror root for given server
MIRROR_ROOT=$SCRIPT_ROOT/../oidb-mirror/$( urlToFilename $SERVER )

# Define OIExplorerJar
OITOOLS_JAR=$SCRIPT_ROOT/OIFitsExplorer.jar


