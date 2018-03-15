#!/usr/bin/env bash

################################################################################
# stellar.sh - orchestrate Stellar modules using docker-compose
script_version="0.0.3"
################################################################################

################################################################################
# Usage

helpmsg() {
  cat - >&2 <<EOF
NAME
    stellar.sh - Machine Learning on Graphs

DESCRIPTION
    Orchestrate Stellar modules using docker-compose

VERSION
    ${script_version}

SYNOPSIS
    stellar.sh [-h|--help]

    stellar.sh [-v|--verbose]
               [--colour[=<when>]
               [-n|--no-pull]
               [--]
               {start|stop|restart}

COMMAND
  start
          Brings up the stellar stack, pulling all images always by default.
          Delegates to docker-compose pull followed by docker-compsose up
  stop
          Stops containers and removes containers, networks, volumes, and
          images.
  restart
          Equivalent to 'stop' followed by 'start'

OPTIONS
  -h, --help
          Prints this and exits

  -v, --verbose
          Enable debug messages

  --colour[=<when>]
          Specify script log and docker-compose colourising. The possible values
          of 'when' are 'never', 'always' or 'auto' (default). On 'auto'
          colouring is enabled if error stream is connected to a terminal, and
          disabled otherwise.

  -n, --no-pull
          Disables automatic re-pulling of docker images (if there are updates)

  --
          Specify end of options; useful if the first non option
          argument starts with a hyphen

EOF

}

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
# Command line arg processing

# defaults
colour=auto

# There  are several  ways to  parse cmdline  args. This  solution is  portable,
# allows   for   both   short/long    options,   handles   whitespace,   handles
# optional-option  arguments ;),  handles  repeatable opt,  and frankly  doesn't
# require much code bloat compared with any alternatives I've seen

# Examples valid option formats
#        | flag     | mandatory arg | optional arg
# -------+----------+---------------+-------------------
# short  | -f       | -o arg        | (not supported)
# long   | --flat   | --opt arg     | --opt
#        |          | --opt=arg     | --opt=arg (must use '=' with opt-arg)

# For long option processing we can't use process substitution (echo the arg)
# as OPTIND does not propagate across sub shells so we reassign output in OPTARG
next_arg() {
    if [[ $OPTARG == *=* ]]; then
        # for cases like '--opt=foo'
        OPTARG="${OPTARG#*=}"
    else
        # for cases like '--opt foo'
        OPTARG="${args[$OPTIND]}"
        OPTIND=$((OPTIND + 1))
    fi
}

# ':' means preceding option character expects one argument, except
# first ':' which make getopts run in silent mode. We handle errors with
# wildcard case catch. Long options are considered as the '-' character
optspec=":hvn-:"
args=("" "$@")  # dummy first element so $1 and $args[1] are aligned
while getopts "$optspec" optchar; do
    case "$optchar" in
        h) helpmsg ; exit 0 ;;
        v) verbose=1 ;;
        n) no_pull=1 ;;
        -) # long option processing
            case "$OPTARG" in
                help)
                    helpmsg ; exit 0 ;;
                verbose)
                    verbose=1 ;;
                no-pull)
                    no_pull=1 ;;
                color|colour)
                    colour=auto ;;
                color=*|colour=*) next_arg
                    colour="$OPTARG" ;;
                # opt|opt=*) nextarg    # example option with mandatory arg
                #   arg="$OPTARG"
                -) break ;;
                *) fatal "Unknown option '--${OPTARG}'" "see '${prog_name} --help' for usage" ;;
            esac
            ;;
        *) fatal "Unknown option: '-${OPTARG}'" "See '${prog_name} --help' for usage" ;;
    esac
done

shift $((OPTIND-1))

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

setup_coordinator() {
    setup_volume "$STELLAR_COORDINATOR_DATAPATH" "Stellar Coordinator" "working directory"
    oss=$(ls -d "$STELLAR_COORDINATOR_DATAPATH/session/"* 2> /dev/null |grep -E '/.{8}-.{4}-.{4}-.{4}-.{12}$')
    info "Found $(echo $oss|wc -w) expired sessions to remove."
    for s in $oss; do
        rm -rf $s;
    done
}

# All setup tasks needed by Stellar Ingest
setup_ingest() {
    setup_volume "$STELLAR_INGEST_DATAPATH" "Stellar Ingest" "working directory"
    setup_volume "$STELLAR_INGEST_USERPATH" "Stellar Ingest" "user data directory"
}

setup_nai() {
    setup_volume "$STELLAR_EVPLUGINS_DATAPATH"  "Stellar NAI" "working directory"
    setup_volume "$STELLAR_EVPLUGINS_CONFIG"  "Stellar NAI" "config directory"

    info "Copying NAI pipeline configuration files."
    cp ${SCRIPTPATH}/nai/*.json "$STELLAR_EVPLUGINS_CONFIG" ||
        fatal "Cannot copy NAI pipeline configuration files."
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
    setup_volume "$STELLAR_SEARCH_KIBANA_CONFIG" "Stellar Search" "Kibana config directory"

    stellar_search_config > "${STELLAR_SEARCH_APP_CONFIG}/application-docker.yml"
    stellar_search_db_config > "${STELLAR_DB_INITSCRIPTS}/30-stellar-search.sql"
    stellar_search_kibana_config > "${STELLAR_SEARCH_KIBANA_CONFIG}/kibana.yml"
    stellar_search_elasticsearch_config > "${STELLAR_SEARCH_ELASTIC_CONFIG}/elasticsearch.yml"

    # chmod 600 "${STELLAR_SEARCH_APP_CONFIG}/application-docker.yml"
    # chmod 600 "${STELLAR_DB_INITSCRIPTS}/30-stellar-search.sql"
}

# All setup tasks needed by Stellar Config UI
setup_config() {
    setup_volume "$STELLAR_CONFIG_DATAPATH"  "Stellar Config" "downloads directory"
}

# All setup tasks needed by Stellar Entity Resolution
setup_er() {
    setup_volume "$STELLAR_ER_DATAPATH"  "Stellar ER" "working directory"
    # Mounting the  logging directory is  a hack: otherwise /var/log  inside the
    # container is used, which is not accessible to a non-root user.
    setup_volume "$STELLAR_ER_LOGPATH"  "Stellar ER" "logging directory"
}

# As first step: test that the base mountpoint is accessible.
setup_main_mountpoint() {
    info "Checking if user $STELLAR_UID:$STELLAR_GID has access to the base stellar mountpoint."
    setup_volume "$STELLAR_VOLUMES_PREFIX" "Stellar" "base application mountpoint"
}

# Application setup: calls setup functions for all individual modules.
setup() {
    setup_main_mountpoint
    setup_coordinator
    setup_db
    setup_ingest
    setup_nai
    setup_search
    setup_er
    setup_config
}

startme() {

    if [ -n "$no_pull" ]; then
      info "Not checking for updates to cached images"
    else
      info "Checking for updates to images"
      docker-compose "${docker_colour_opt[@]}" -f "$SCRIPTPATH/docker-compose.yml" -p stellar pull
    fi

    info "Starting stellar..."
    docker-compose "${docker_colour_opt[@]}" -f "$SCRIPTPATH/docker-compose.yml" -p stellar up -d
}

stopme() {
    info "Stopping stellar..."
    docker-compose "${docker_colour_opt[@]}" -f "$SCRIPTPATH/docker-compose.yml" -p stellar down
}

################################################################################
# Main

# set colour for both our script and docker-compose
case "$colour" in
    always)
        enable_log_colours
        ;;
    never)
        docker_colour_opt=(--no-ansi)
        ;;
    auto)
        if [ -t 2 ]; then
            # only if standard error is connected to tty (not redirected)
            enable_log_colours
        else
            docker_colour_opt=(--no-ansi)
        fi
        ;;
    *) fatal "Unknown colour option '${colour}'" "see '${prog_name} --help' for usage" ;;
esac

if [[ "$#" -ne 1 ]]; then
    fatal "Expected only 1 argument" "See '${prog_name} --help' for usage"
fi

case "$1" in
    start)   setup; startme ;;
    stop)    stopme ;;
    restart) stopme; startme ;;
    *) fatal "Unknown command '${1}'" "see '${prog_name} --help' for usage"
esac
