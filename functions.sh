#
# common functions
#

# just exec the programm after install of trap
# using:
#   trap abortExec ERR
abortExec(){
  echo "Error occured, aborting program"
  exit
}

#
#
# call this function in main program to exit on error
# you also must call it inside functions where error must not occur
installTrap(){
  trap abortExec ERR
}

# echoDone
echoDone(){
  # we could get terminal width to clean (override) the previous info line 
  # echo -ne "blah\r"
  echo "Done                                                                                 "
}
 
# remove schema part so given url can map to a file path
function urlToFilename(){
  URL="$1"
  echo "${URL##*://}"
}

# Fix internal URLS with SERVER prefix if :// is missing
function fixUrl(){
  URL="$1"
  SERVER="$2"

  if ! echo $URL | grep "://" &> /dev/null 
  then
    URL="${SERVER}${URL}"
  fi

  echo $URL
}


function normCollName(){
# Mimic StringUtils.java
# /** regular expression used to match characters different than * alpha/numeric/_/-/. (1..n) */
#     private final static Pattern PATTERN_NON_FILE_NAME = Pattern.compile("[^a-zA-Z0-9\\-_\\.]");
    echo -n "$*" | tr -c "[^a-zA-Z0-9\\-_\\.]" "_"
}

function mkdirIfMissing(){
  for DIR_PATH in $* 
  do
      if [ ! -d "$DIR_PATH" ] ; then mkdir -pv $DIR_PATH ; fi
  done
}



function uriencode() {
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


