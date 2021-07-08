#!/bin/bash

#
# Copyright © 2021 Pablo Sanchez
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
   case $WINDOW_TOOL in
      wmctrl)  TBIRD_IS_RUNNING=$(wmctrl -lx | awk '{ if ($3 ~ /Mail.Thunderbird/) print $1 }') ;;
      xdotool) TBIRD_IS_RUNNING=$(xdotool search --name '.*- Mozilla Thunderbird$' 2>/dev/null) ;;
      *)       TBIRD_IS_RUNNING='' ;;
   esac
}

#
# Window tool to use:  wmctrl, xdotool, nada
#
get_window_tool()
{
   which wmctrl > /dev/null 2>&1
   if [ $? -eq 0 ] ; then
      WINDOW_TOOL='wmctrl'
   else
      which xdotool > /dev/null 2>&1
      if [ $? -eq 0 ] ; then
         WINDOW_TOOL='xdotool'
      else
         WINDOW_TOOL='nada'
      fi
   fi
}

pop_window_xdotool()
{
   #
   # Pop the composition window to the top
   #
   CURR_DESKTOP=$(xdotool get_desktop)

   N=20
   I=1
   POLL=0.1
   WID=""

   # To minimize polling, we wait this amount before we start
   sleep 0.5 
   while [ $I -ne $N -a -z "$WID" ] ; do
      WID=$(xdotool search --desktop $CURR_DESKTOP --name 'Write.*Thunderbird')
      if [ -z "$WID" ] ; then
         sleep $POLL
      fi
      let "I+=1"
   done

   if [ -n "$WID" ] ; then
      xdotool windowactivate $WID
   fi
}

pop_window_wmctrl()
{
   CURR_DESKTOP=$(wmctrl -d | awk '{ if ($2 == "*") print $1 }')

   N=20
   I=1
   POLL=0.1

   # To minimize polling, we wait this amount before we start
   sleep 0.5
   while [ $I -ne $N -a -z "$WIN" ] ; do
      WIN=$(wmctrl -lx | awk -v DESKTOP=$CURR_DESKTOP '{ if ($2 == DESKTOP && $3 ~ /Msgcompose/) print $1 }')
      if [ -z "$WIN" ] ; then
         sleep $POLL
      fi
      let "I+=1"
   done

   if [ -n "$WIN" ] ; then
      wmctrl -i -a $WIN
   fi
}

pop_composition_window()
{
   # Try to pop the composition window to the top
   if   [ $WINDOW_TOOL = 'wmctrl' ] ; then
      pop_window_wmctrl
   elif [ $WINDOW_TOOL = 'xdotool' ] ; then
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

DEFAULT_WEBMAIL_URL='https://mail.google.com/mail/?extsrc=mailto&url='
WEBMAIL_URL=${XDG_EMAIL_HOOK_WEBMAIL_URL-'not defined'}

get_window_tool

########################################################
# Main
########################################################

# When running, set TBIRD_IS_RUNNING
is_tbird_running

if [ -n "$TBIRD_IS_RUNNING" ] ; then
   thunderbird "$@" &

   pop_composition_window
else # Thunderbird is not running
   if [ "$WEBMAIL_URL" = 'not defined' ] ; then
      thunderbird "$@" &

      pop_composition_window
   else
      # Use webmail
      if [ -n "$WEBMAIL_URL" ] ; then
         brave-browser "$WEBMAIL_URL""$@"
      else
         brave-browser "$DEFAULT_WEBMAIL_URL""$@"
      fi
   fi
fi

exit 0
