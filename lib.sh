# Find important paths
export ACTION_DIR=$QUICKNOTE_DIR/actions

# Config
export NOTE_DIR=$HOME/Documents/NOTES
export ADDON_DIR=$HOME/quicknote.actions.d
export DEFAULT_ACTION=list
export DEFAULT_SORT='sort -k2,3r'
export NOTE_EXT=md
# export CONFIG_FILE=$HOME/.note.cfg
# source $CONFIG_FILE

# Find important paths
export ACTION_DIR=$QUICKNOTE_DIR/actions


# Actions {{{1

# Echo the full path to an action if it exists, and is executible.
# Echo error msg and return non-zero exit-code if action does not exist.
get_action() {
    if [ -x "$ACTION_DIR/$1" ]; then
        echo $ACTION_DIR/$1
    elif [ -x "$ADDON_DIR/$1" ]; then
        echo $ACTION_DIR/$1
    else
        echo "'$1' does not appear to be an available action."  >&2
        echo "Is it in '$ADDON_DIR' and executible?"            >&2
        echo $USAGE_MSG                                         >&2
        return 1
    fi
}

# Echo all of the available actions (full paths)
list_actions() {
    local DIRS=$ACTION_DIR
    [ -d "$ADDON_DIR" ] && DIRS+=$ADDON_DIR
    for action in $(find $DIRS -mindepth 1); do
        [ -x $action ] && echo $action
    done
}


# Paths to Notes {{{1

# Given a complete reference (not prefix) to a note which may or may not exist,
# return the canonical path.
get_note() {
    echo $NOTE_DIR/${1%.${NOTE_EXT}}.${NOTE_EXT}
}

# Given one or more note references, echos all matching notes (full path).
find_all_notes() {
    set -f
    for prefix in $*; do
        find $NOTE_DIR -name ${prefix%.${NOTE_EXT}}*${NOTE_EXT}
    done
    set +f
}

# Given a note reference, echo the full path to the note file.
find_note() {
    ref=$1
    candidates=$(find_all_notes $ref)
    set $candidates  # $1, $2, etc. now equal each word in $candidates
    if [ -z "$1" ]; then
        echo "No files matching reference: '$ref'"           >&2
        return 1
    elif [ -z $2 ]; then
        echo $1
    else
        echo "Multiple files matching reference: $ref" >&2
        echo $*                                                 >&2
        return 1
    fi
}

# Make a new note file if it doesn't already exist, and echo the path
get_new_note() {
    if ! [ -z $2 ]; then
        echo "Too many arguments."  >&2
        return 1
    fi

    if [ -z $1 ]; then
        note=$(mktemp -p $NOTE_DIR XXXXXXXX.$NOTE_EXT)
        echo $note
    else
        note=$(get_note $1)
        touch $note
        echo $note >&2
    fi
}

# Produces a full list of note files in the $NOTE_DIR
# If arguments are given, lists only notes with filenames that can
# be found (recursively with find, so directories should work) in that list.
list_notes() {
    set -f
    if [ -z $1 ]; then
        find $NOTE_DIR -name "*.$NOTE_EXT"
    else
        find "$@" -name "*.$NOTE_EXT"
    fi
    set +f
}

# Testing Notes {{{1

# Confirm that note conforms to naming scheme.
note_valid_name() {
    relpath=${1##$NOTE_DIR/}
    extension=${relpath##*.}
    if ! [ $(basename $relpath) == $relpath ]; then  # Note in a subdirectory
        echo "Note is not in $NOTE_DIR" >&2
    elif ! [ "$extension" == "$NOTE_EXT" ]; then
        echo "Note extension $extension is not $NOTE_EXT" >&2
    fi
}

# Confirm that note exists
note_exists() {
    [ -f "$1" ]
    return $?
}

# Check that note is usable
check_note() {
    if note_valid_name $1 && note_exists $1 ; then
        return 0
    else
        return 1
    fi
}

# Parsing Notes {{{1

note_root() {
    bn=$(basename $1)
    echo ${bn/.$NOTE_EXT/}
}


# Echo the title of the note
note_title() {
    check_note $1
    awk 'NR==1' $1
}

# Echo the last modified time of the note (sortable)
note_date() {
    check_note $1
    stat -c '%y' $1 | cut -c 1-16
}


# Filtering Notes {{{1

# Echo all notes whose content (including title) match $pattern
list_matching() {
    if [ -n "$*" ]; then
        list_notes | xargs grep --ignore-case -l "$*"
    else
        list_notes
    fi
}

# Echo empty (zero-byte) notes.
list_empty() {
    find $(list_notes $*) -empty

}


# Summarizing Lists of Notes

# Echo notes and info.
# If given arguments (full paths), list only info for those notes.
list_infos_unsorted() {
    if [ -z "$*" ]; then
        local notes=$(list_notes)
    else
        local notes=$*
    fi
    for note in $notes; do
        check_note $note
        echo "$(note_root $note)	$(note_date $note)	$(note_title $note)"
    done
}

# Echo notes and info; sorted with $DEFAULT_SORT
list_infos() {
    list_infos_unsorted $* | $DEFAULT_SORT
}

# List info for all notes.
# If given an argument, only list info for matching notes.
# sorted with $DEFAULT_SORT
list_matching_infos() {
    matching=$(list_matching $*)
    if ! [ -n "$matching" ]; then
        return 1
    else
        list_infos $(list_matching $*)
    fi
}


# Action Assistants {{{1

edit_note() {
    if $(check_note $1); then
        $EDITOR $1
    else
        return 1
    fi
}

# Export {{{1

export -f get_action list_actions \
          get_note find_all_notes find_note \
          get_new_note list_notes \
          note_valid_name note_exists check_note \
          note_root note_title note_date \
          list_matching list_empty \
          list_infos_unsorted list_infos list_matching_infos \
          edit_note
