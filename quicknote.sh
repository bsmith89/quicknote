#!/usr/bin/env bash
set -o errexit

USAGE_MSG="Usage: $(basename $0) [OPTIONS] [ACTION, [ARGS...]]"
HELP_MSG="Work with simple note files."

# Find important 
export QUICKNOTE_NAME=$0
export QUICKNOTE=$(readlink -f $QUICKNOTE_NAME)
export QUICKNOTE_DIR=$(dirname $QUICKNOTE)

# Source library
source $QUICKNOTE_DIR/lib.sh

# Source configuration files
source $QUICKNOTE_DIR/config.sh

export QUICKNOTE_USR_CFG=$HOME/.quicknote.cfg
[ -f $QUICKNOTE_USR_CFG ] && source $QUICKNOTE_USR_CFG

# Parse args
action=${1-$DEFAULT_ACTION}
shift || True

ACTION_EXE=$(get_action $action)
$ACTION_EXE $*
