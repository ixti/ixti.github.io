#!/bin/sh


set -e


APP=$(echo $* | sed -e "s/^  *|  *$//g")
SID=$(echo "$APP" | md5sum | cut -f1 -d" ")
RUN="tmux -L dmux"
CFG="$HOME/.dmux.conf"


if [ -z "$APP" ]; then
  echo "USAGE: dmux <command>" >&2
  exit 1
fi


test -e "$CFG" || cat > "$CFG" <<CONFIG
# Unbind default prefix, so that there will be no hotkeys available and bind
# hotkeys we are interested in:

unbind C-b

bind-key -n C-\   detach
bind-key -n C-F10 kill-session


# Disable (hide) status line completely

set-option -g status off


# Force tmux to resize a window based on the smallest client actually
# viewing it, not on the smallest one attached to the entire session.

set-window-option -g aggressive-resize on


# 256 Colours

set-option -g default-terminal "screen-256color"


# Set history limit

set-option -g history-limit 0


# Window titling for X

set-option -g set-titles on
set-option -g set-titles-string '#W'
CONFIG


session_exists () {
  $RUN has -t "$SID" 2>/dev/null
}


create_session () {
  $RUN new -d -A -s "$SID" "$APP" \; source "$CFG" \; attach
}


attach_session () {
  $RUN attach -t "$SID"
}


session_exists && attach_session || create_session
