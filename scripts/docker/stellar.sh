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
# Functions

# Setup a volume local mountpoint. Parameters:
# MOUNTPT: the host directory where to mount
# MODNAME: user-friendly module name (e.g. "Stellar Ingest")
# DESCRIP: user-friendly description (e.g. "user data directory")
setup_volume()  {
    MOUNTPT=$1; MODNAME=$2; DESCRIP=$3
    if [ -d "$MOUNTPT" ]; then
        echo "$MODNAME: $DESCRIP found: $MOUNTPT"
    else
        echo "$MODNAME: creating $DESCRIP: $MOUNTPT"
        mkdir -p "$MOUNTPT"
        if [ $? -ne 0 ]; then
            echo "Error creating mount point... exiting."
            exit 1
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
    echo "$MODNAME: copying $DESCRIP from web into $OUTPATH"
    wget -q -O "$OUTPATH" "$FILEURL"
    if [ $? -ne 0 ]; then
        echo "Error retrieving file... exiting."
        echo "Failed URL: $FILEURL"
        exit 1
    fi
}

# All setup tasks needed by Stellar Ingest
setup_ingest() {
    setup_volume "$STELLAR_INGEST_DATAPATH" "Stellar Ingest" "user data directory"
}

# All setup tasks needed by Stellar Search
setup_search() {
    setup_volume "$STELLAR_SEARCH_DATAPATH" "Stellar Search" "user data directory"
    setup_volume "$STELLAR_SEARCH_APP_CONFIG" "Stellar Search" "Application config directory"
    setup_volume "$STELLAR_SEARCH_ELASTIC_CONFIG" "Stellar Search" "Elasticsearch config directory"
    get_webfile $STELLAR_SEARCH_APP_CONFIG/application-docker.yml "Stellar Search" "Application configuration"  https://raw.githubusercontent.com/data61/stellar-search/develop/docker/search/application-docker.yml
    get_webfile $STELLAR_SEARCH_ELASTIC_CONFIG/elasticsearch.yml "Stellar Search" "Elasticsearch configuration"  https://raw.githubusercontent.com/data61/stellar-search/develop/docker/elasticsearch/config/elasticsearch.yml
}

# Application setup: calls setup functions for all individual modules.
setup() {
    setup_ingest
    setup_search
}

startme() {
    echo "Starting stellar..."
    docker-compose -f "$SCRIPTPATH/docker-compose.yml" -p stellar up -d
}

stopme() {
    echo "Stopping stellar..."
    docker-compose -f "$SCRIPTPATH/docker-compose.yml" -p stellar down
}

helpmsg() {
    echo "Stellar - Machine Learning on Graphs" >&2
    echo "deployment script v.$script_version" >&2
    echo "usage: $0 start|stop|restart" >&2
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
