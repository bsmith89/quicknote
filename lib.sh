# Find important paths
export ACTION_DIR=$QUICKNOTE_DIR/actions

# Config
export NOTE_DIR=$HOME/Documents/NOTES
export ADDON_DIR=$HOME/quicknote.actions.d
export DEFAULT_ACTION=list
export DEFAULT_SORT='sort -k2,3r'
export NOTE_SUFFIX=md
# export CONFIG_FILE=$HOME/.note.cfg
# source $CONFIG_FILE

# Find important paths
export QUICKNOTE_NAME=$0
export QUICKNOTE=$(readlink -f $QUICKNOTE_NAME)
export QUICKNOTE_DIR=$(dirname $QUICKNOTE)
export ACTION_DIR=$QUICKNOTE_DIR/actions

# Echo the Usage Message
echo_usage() {
    echo "$USAGE_MSG"   >&2
}

# Echo the Help Message
echo_help() {
    echo "$HELP_MSG"    >&2
}

# Return the full path to an action if it exists, and is executible.
get_action() {
    if [ -x "$ACTION_DIR/$1" ]; then
        echo $ACTION_DIR/$1
    elif [ -x "$ADDON_DIR/$1" ]; then
        echo $ACTION_DIR/$1
    else
        echo "'$1' does not appear to be an available action."  >&2
        echo "Is it in '$ADDON_DIR' and executible?"            >&2
        echo_usage
        return 1
    fi
}

# List all of the available actions.
# TODO: Implement
list_actions() {
    local DIRS=$ACTION_DIR
    [ -d "$ADDON_DIR" ] && DIRS+=$ADDON_DIR
    for action in $(find $DIRS -mindepth 1); do
        echo $action
    done
}

# Given a basename, with or without extension, gets the full path to the
# note file.
get_note() {
    if [ -f "$NOTE_DIR/$1" ]; then
        echo $NOTE_DIR/$1
    elif [ -f "$NOTE_DIR/$1.$NOTE_SUFFIX" ]; then
        echo $NOTE_DIR/$1.$NOTE_SUFFIX
    else
        echo "No file '$NOTE_DIR/$1' found." >&2
        return 1
    fi
}

get_new_note() {
    if ! [ -d "$NOTE_DIR" ]; then
        echo "'$NOTE_DIR' is not an extant directory."
        return 1
    fi
    if [ -z $1 ]; then
        NOTE_FILE=$(mktemp -p $NOTE_DIR XXXX.$NOTE_SUFFIX)
        echo $NOTE_FILE
    elif [ -f "$NOTE_DIR/$1.$NOTE_SUFFIX" ]; then
        echo "'$NOTE_DIR/$1.$NOTE_SUFFIX' is already a note." >&2
        return 1
    else
        NOTE_FILE=$NOTE_DIR/$1.$NOTE_SUFFIX
        echo $NOTE_FILE
    fi
}

# Produces a full list of note files in the $NOTE_DIR
# If arguments are given, lists only notes with filenames that can
# be found (recursively with find, so directories should work) in that list.
list_notes() {
    set -f
    if [ -z $1 ]; then
        find $NOTE_DIR -name "*.$NOTE_SUFFIX"
    else
        find $* -name "*.$NOTE_SUFFIX"
    fi
    set +f
}

check_note() {
    if [ -z $1 ]; then
        return 1
    elif [ -f $1 ]; then
        return 0
    else
        return 1
    fi
}

note_title() {
    check_note $1
    awk 'NR==1' $1
}

note_date() {
    check_note $1
    stat -c '%y' $1 | cut -c 1-16
}

list_matching() {
    if [ -n "$*" ]; then
        pattern=$*
        list_notes | xargs grep --ignore-case -l "$pattern"
    else
        list_notes
    fi
}

list_matching_infos() {
    list_infos $(list_matching $*)
}

list_infos_unsorted() {
    if [ -z "$*" ]; then
        local NOTES=$(list_notes)
    else
        local NOTES=$*
    fi
    for note in $NOTES; do
        check_note $note
        echo "$(basename $note)	$(note_date $note)	$(note_title $note)"
    done
}

list_infos() {
    list_infos_unsorted $* | $DEFAULT_SORT
}

list_empty() {
    find $(list_notes $*) -empty

}

edit_note() {
    local NOTE_PATH=$(get_note $1)
    if $(check_note $NOTE_PATH); then
        $EDITOR $NOTE_PATH
    else
        return 1
    fi
}

export -f edit_note echo_usage echo_help get_action list_actions get_note \
          get_new_note list_notes check_note note_title note_date list_infos \
          list_matching list_infos_unsorted list_matching_infos list_empty \
          list_actions
