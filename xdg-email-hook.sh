#!/bin/bash

#
# Copyright © 2023 Pablo Sanchez
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# The Software is provided "as is", without warranty of any kind,
# express or implied, including but not limited to the warranties of
# merchantability, fitness for a particular purpose and
# noninfringement. In no event shall the authors or copyright holders be
# liable for any claim, damages or other liability, whether in an action
# of contract, tort or otherwise, arising from, out of or in connection
# with the Software or the use or other dealings in the Software.
#

#
# A simple Thunderbird wrapper so our browswer will properly
# start a Thunderbird window.
#
# This file must be named `xdg-email-hook.sh`
#
# For window management, we first try `wmctrl` and if it's not
# installed (somewhat unlikely), we try `xdotool`
#
# XDG_EMAIL_HOOK_WEBMAIL_URL
# ==========================
# A user defined variable influences this script as follows.
#
# XDG_EMAIL_HOOK_WEBMAIL_URL | If Thunderbird is not running
# ---------------------------+-------------------------------
# Not defined                | Start Thunderbird
# Defined/set to ""          | browser => gmail
# Set to Webmail URL         | browser => user defined
#
# Webmail URL
# -----------
# The URL fragment must end with something like `...&url=`
# This script will pass the mailto URI.  It works for gmail.
#
# References
# ==========
# o This script - https://pmhahn.github.io/chromium-mailto-thunderbird/
# o Gmail URI - https://developers.google.com/web/updates/2012/02/Getting-Gmail-to-handle-all-mailto-links-with-registerProtocolHandler
# o mailto test site - https://www.scottseverance.us/mailto.html
#

########################################################
# Functions
########################################################

is_tbird_running()
{
   case $window_tool in
      wmctrl)  tbird_is_running=$(wmctrl -lx | awk '{ if ($3 ~ /Mail.Thunderbird/) print $1 }') ;;
      xdotool) tbird_is_running=$(xdotool search --name '.*- Mozilla Thunderbird$' 2>/dev/null) ;;
      *)       tbird_is_running='' ;;
   esac
}

#
# Window tool to use:  wmctrl, xdotool, nada
#
get_window_tool()
{
   which wmctrl > /dev/null 2>&1
   status=$?
   if [ $status -eq 0 ] ; then
      window_tool='wmctrl'
   else
      which xdotool > /dev/null 2>&1
      status=$?
      if [ $status -eq 0 ] ; then
         window_tool='xdotool'
      else
         window_tool='nada'
      fi
   fi
}

pop_window_xdotool()
{
   #
   # Pop the composition window to the top
   #
   curr_desktop=$(xdotool get_desktop)

   n=20
   i=1
   poll=0.1
   wid=""

   # To minimize polling, we wait this amount before we start
   sleep 0.5
   while [ $i -ne $n ] && [ -z "$wid" ] ; do
      wid=$(xdotool search --desktop "$curr_desktop" --name 'Write.*Thunderbird')
      if [ -z "$wid" ] ; then
         sleep $poll
      fi
      ((i++))
   done

   if [ -n "$wid" ] ; then
      xdotool windowactivate "$wid"
   fi
}

pop_window_wmctrl()
{
   curr_desktop=$(wmctrl -d | awk '{ if ($2 == "*") print $1 }')

   n=20
   i=1
   poll=0.1

   # To minimize polling, we wait this amount before we start
   sleep 0.5
   while [ $i -ne $n ] && [ -z "$win" ] ; do
      win=$(wmctrl -lx | awk -v DESKTOP="$curr_desktop" '{ if ($2 == DESKTOP && $3 ~ /Msgcompose/) print $1 }')
      if [ -z "$win" ] ; then
         sleep $poll
      fi
      ((i++))
   done

   if [ -n "$win" ] ; then
      wmctrl -i -a "$win"
   fi
}

pop_composition_window()
{
   # Try to pop the composition window to the top
   if   [ $window_tool = 'wmctrl' ] ; then
      pop_window_wmctrl
   elif [ $window_tool = 'xdotool' ] ; then
      pop_window_xdotool
   fi
}

########################################################
# Initialize
########################################################

# Debug
#LOG_FILE=/var/tmp/$(basename $0).log
#exec 1>>$LOG_FILE
#exec 2>&1
#set -x

default_webmail_url='https://mail.google.com/mail/?extsrc=mailto&url='
webmail_url=${XDG_EMAIL_HOOK_webmail_url-'not defined'}

get_window_tool

########################################################
# Main
########################################################

# When running, set tbird_is_running
is_tbird_running

if [ -n "$tbird_is_running" ] ; then
   thunderbird "$@" &

   pop_composition_window
else # Thunderbird is not running
   if [ "$webmail_url" = 'not defined' ] ; then
      thunderbird "$@" &

      pop_composition_window
   else
      # Use webmail
      if [ -n "$webmail_url" ] ; then
         brave-browser "$webmail_url""$*"
      else
         brave-browser "$default_webmail_url""$*"
      fi
   fi
fi

exit 0
