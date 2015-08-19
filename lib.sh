#!/usr/bin/env bash
# Library functions for quicknote

# Config {{{1
# Environmental variables take precedence, but not if they're overriden in
# quicknote.cfg or $QN_USR_CFG
[ -z "$QN_USR_CFG" ]        && export QN_USR_CFG=$HOME/.quicknote.cfg
[ -z "$QN_NOTE_DIR" ]       && export QN_NOTE_DIR=$HOME/Documents/NOTES
[ -z "$QN_ADDON_DIR" ]      && export QN_ADDON_DIR=$HOME/.quicknote.actions.d
[ -z "$QN_DEFAULT_ACTION" ] && export QN_DEFAULT_ACTION=list
[ -z "$QN_SORT" ]           && export QN_SORT='sort -k2,3r'
[ -z "$QN_EXT" ]            && export QN_EXT=md
[ -z "$QN_PATTERN" ]        && export QN_PATTERN="XXXXXXXX.$QN_EXT"
# Default clipboard tool is defined for OSX
[ -z "$CLIPBOARD" ]         && export CLIPBOARD=${CLIPBOARD-pbcopy}


# Find important paths
export QN_ACTION_DIR=$QN_DIR/actions

# Actions {{{1

# Echo the full path to an action if it exists, and is executible.
# Echo error msg and return non-zero exit-code if action does not exist.
get_action() {
    if [ -x "$QN_ADDON_DIR/$1" ]; then
        echo $QN_ADDON_DIR/$1
    elif [ -x "$QN_ACTION_DIR/$1" ]; then
        echo $QN_ACTION_DIR/$1
    else
        echo "'$1' does not appear to be an available action." >&2
        echo "Is it in '$QN_ADDON_DIR' and executible?"        >&2
        echo $USAGE_MSG                                        >&2
        return 1
    fi
}

# Echo all of the available actions (full paths)
list_actions() {
    local DIRS=$QN_ACTION_DIR
    [ -d "$QN_ADDON_DIR" ] && DIRS+=$QN_ADDON_DIR
    for action in $(find $DIRS -mindepth 1); do
        [ -x $action ] && echo $action
    done
}


# Paths to Notes {{{1

# Given a complete reference (not prefix) to a note which may or may not exist,
# return the canonical path.
get_note() {
    echo $QN_NOTE_DIR/${1%.${QN_EXT}}.${QN_EXT}
}

# Given one or more note references, echos all matching notes (full path).
find_all_notes() {
    set -f
    for prefix in "$@"; do
        find $QN_NOTE_DIR -name ${prefix%.${QN_EXT}}*.${QN_EXT}
    done
    set +f
}

# Given a note reference, echo the full path to the note file.
find_note() {
    ref=$1
    candidates=$(find_all_notes $ref)
    # $1, $2, etc. now equal each word in $candidates
    set "$candidates"
    if [ -z "$1" ]; then
        echo "No files matching reference: '$ref'"     >&2
        return 1
    elif [ -z $2 ]; then
        echo $1
    else
        echo "Multiple files matching reference: '$ref'" >&2
        echo $*                                        >&2
        return 1
    fi
}

# Make a new note file if it doesn't already exist, and echo the path
get_new_note() {
    if ! [ -z $2 ]; then
        echo "Too many arguments." >&2
        return 1
    fi

    if [ -z $1 ]; then
        note=$(mktemp -p $QN_NOTE_DIR $QN_PATTERN)
        echo $note
    else
        note=$(get_note $1)
        touch $note
        echo $note
    fi
}

# Produces a full list of note files in the $QN_NOTE_DIR
# If arguments are given, lists only notes with filenames that can
# be found (recursively with find, so directories should work) in that list.
list_notes() {
    set -f
    if [ -z $1 ]; then
        find $QN_NOTE_DIR -name "*.$QN_EXT"
    else
        find "$@" -name "*.$QN_EXT"
    fi
    set +f
}

# Testing Notes {{{1

# Confirm that note conforms to naming scheme.
note_valid_name() {
    relpath=${1##$QN_NOTE_DIR/}
    extension=${relpath##*.}
    if ! [ $(basename $relpath) == $relpath ]; then  # Note in a subdirectory
        echo "$relpath is not in $QN_NOTE_DIR"              >&2
    elif ! [ "$extension" == "$QN_EXT" ]; then
        echo "'$extension' does not have extension $QN_EXT" >&2
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
    echo ${bn/.$QN_EXT/}
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

# Echo notes and info; sorted with $QN_SORT
list_infos() {
    list_infos_unsorted $* | $QN_SORT
}

# List info for all notes.
# If given an argument, only list info for matching notes.
# sorted with $QN_SORT
list_matching_infos() {
    matching=$(list_matching $*)
    if ! [ -n "$matching" ]; then
        return 1
    else
        list_infos $(list_matching $*)
    fi
}



# Export {{{1

export -f get_action list_actions \
          get_note find_all_notes find_note \
          get_new_note list_notes \
          note_valid_name note_exists check_note \
          note_root note_title note_date \
          list_matching list_empty \
          list_infos_unsorted list_infos list_matching_infos
