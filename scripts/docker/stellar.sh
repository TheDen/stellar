#!/usr/bin/env bash

################################################################################
# stellar.sh - orchestrate Stellar modules using docker-compose
script_version="0.0.2"
################################################################################

################################################################################
# Load Stellar configuration

# The absolute path to the directory containing this script.
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Export  all  variables  in  the  config   file,  to  make  them  available  to
# subprocesses, in particular docker-compose.
set -a
. "$SCRIPTPATH/stellar.config"
set +a

################################################################################
## Loggers ##
#
# we define standard loggers: info, warn, error, fatal and debug if `verbose`
# is defined. Loggers print to stderr with log level colourised according to
# severity.

enable_log_colours() {
    r=$(printf "\e[1;31m")      # red       (error, fatal)
    g=$(printf "\e[1;32m")      # green     (info)
    y=$(printf "\e[1;33m")      # yellow    (warning)
    b=$(printf "\e[1;34m")      # blue      (debug)
    m=$(printf "\e[1;35m")      # magenta   (process name)
    c=$(printf "\e[1;36m")      # cyan      (timestamp)
    x=$(printf "\e[0m")         # reset     (log message)
}

if [ -t 2 ]; then
    # only if standard error is connected to tty (not redirected)
    enable_log_colours
fi

# log formatter - do not use directly, use the predefined log levels below
prog_name="$(basename "$0")"
date_format="%F %T %Z"   # YYYY-MM-DD HH:MM:SS ZZZZ
logger() {
    local prefix="${m}${prog_name}: ${c}$(date "+${date_format}") $prefix"
    local i
    if [ "$#" -ne 0 ]; then
        for i; do           # read lines from args
            echo "${prefix}${i}${reset}" >&2
        done
    else
        while read i; do    # read lines from stdin
            echo "${prefix}${i}${reset}" >&2
        done
    fi
}

# log levels. Usage either:
#   <level> "line 1" "line 2" "line 3" ;
#   or to prefix each line of output from a child process
#   process | <level> ;
info()  { local prefix="${g} Info:${x} " ; logger "$@" ; }
warn()  { local prefix="${y} Warn:${x} " ; logger "$@" ; }
error() { local prefix="${r}Error:${x} " ; logger "$@" ; }
fatal() { local prefix="${r}Fatal:${x} " ; logger "$@" ; exit 1 ; }
debug() {
    [ -z "$verbose" ] || {
        local prefix="${b}Debug:${x} "
        logger "$@"
    }
}

################################################################################
# Functions

# Setup a volume local mountpoint. Parameters:
# MOUNTPT: the host directory where to mount
# MODNAME: user-friendly module name (e.g. "Stellar Ingest")
# DESCRIP: user-friendly description (e.g. "user data directory")
setup_volume()  {
    MOUNTPT=$1; MODNAME=$2; DESCRIP=$3
    if [ -d "$MOUNTPT" ]; then
        info "$MODNAME: $DESCRIP found: $MOUNTPT"
    else
        info "$MODNAME: creating $DESCRIP: $MOUNTPT"
        mkdir -p "$MOUNTPT"
        if [ $? -ne 0 ]; then
            fatal "Error creating mount point... exiting."
        fi
    fi
}

# Get a file from the web. Parameters:
# OUTPATH: the host path to save output, including the filename.
# MODNAME: user-friendly module name (e.g. "Stellar Ingest")
# DESCRIP: user-friendly description (e.g. "user data directory")
# FILEURL: a web URL to get the file
get_webfile()  {
    OUTPATH=$1; MODNAME=$2; DESCRIP=$3; FILEURL=$4;
    info "$MODNAME: copying $DESCRIP from web into $OUTPATH"
    wget -q -O "$OUTPATH" "$FILEURL"
    if [ $? -ne 0 ]; then
        fatal "Error retrieving file... exiting." "Failed URL: $FILEURL"
    fi
}

# All setup tasks needed by Stellar Ingest
setup_ingest() {
    setup_volume "$STELLAR_INGEST_DATAPATH" "Stellar Ingest" "user data directory"
}

setup_db() {
    setup_volume "$STELLAR_DB_INITSCRIPTS" "Stellar DB" "init scripts"
}


# All setup tasks needed by Stellar Search
setup_search() {

    . "${SCRIPTPATH}/search/config.sh"

    setup_volume "$STELLAR_SEARCH_DATAPATH" "Stellar Search" "user data directory"
    setup_volume "$STELLAR_SEARCH_APP_CONFIG" "Stellar Search" "Application config directory"
    setup_volume "$STELLAR_SEARCH_ELASTIC_CONFIG" "Stellar Search" "Elasticsearch config directory"

    stellar_search_config > "${STELLAR_SEARCH_APP_CONFIG}/application-docker.yml"
    stellar_search_db_config > "${STELLAR_DB_INITSCRIPTS}/30-stellar-search.sql"

    chmod 600 "${STELLAR_SEARCH_APP_CONFIG}/application-docker.yml"
    chmod 600 "${STELLAR_DB_INITSCRIPTS}/30-stellar-search.sql"

    get_webfile $STELLAR_SEARCH_ELASTIC_CONFIG/elasticsearch.yml "Stellar Search" "Elasticsearch configuration"  https://raw.githubusercontent.com/data61/stellar-search/develop/docker/elasticsearch/config/elasticsearch.yml
}

# Application setup: calls setup functions for all individual modules.
setup() {
    setup_db
    setup_ingest
    setup_search
}

startme() {
    info "Starting stellar..."
    docker-compose -f "$SCRIPTPATH/docker-compose.yml" -p stellar up -d
}

stopme() {
    info "Stopping stellar..."
    docker-compose -f "$SCRIPTPATH/docker-compose.yml" -p stellar down
}

helpmsg() {
    echo "Stellar - Machine Learning on Graphs" >&2
    echo "deployment script v.$script_version" >&2
    echo "usage: $(basename $0) start|stop|restart" >&2
    echo "" >&2
}

################################################################################
# Main

case "$1" in 
    start)   setup; startme ;;
    stop)    stopme ;;
    restart) stopme; startme ;;
    *) helpmsg
       exit 1
       ;;
esac
