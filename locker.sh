#!/usr/bin/env bash

# Copyright 2014 Ingemar Ådahl
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

. $(dirname $0)/today.sh

LOCK=${WORKLOCK_LOCKER:-xlock}
DEFAULT_DELAY=300  # Default to 5 minute delay
THRESHOLD=600  # Only log when inactive for more than 10 minutes

if [ -z "$WORKLOCK_DELAY" ]; then
	delay=$(command -v xrdb > /dev/null && \
		xrdb -query | awk 'tolower($0) ~ /xautolock.time/ {print $2 * 60}')
	delay=${delay:-$DEFAULT_DELAY}
else
	delay=$WORKLOCK_DELAY
fi

start_time=$(date +"%s")
$LOCK
end_time=$(date +"%s")

today="${LOGDIR}/$(date +'%Y%m%d')"

if [ ! -e $today ]; then
	echo "$end_time 0" > $today

	# Append EOD for previous work day
	sed -i "s/\(.*\)/\1 ${start_time}/" \
		${LOGDIR}/$(date --date="@${start_time}" +"%Y%m%d")
	exit 0
fi

diff=$((($end_time-$start_time)+$delay))
[ $diff -lt $THRESHOLD ] && exit 0

minutes=$(($diff/60))
seconds=$(($diff%60))

# If zenity isn't installed the default will be active/work time
command -v zenity > /dev/null && \
	zenity --question --text="Log <b>${minutes}m${seconds}s</b> of inactivity?"
if [ $? = 0 ]; then
	inactivity=$(($(awk '{ print $2 }' $today) + $diff))
	sed -i "s/\([0-9]\+\) [0-9]\+/\1 ${inactivity}/" $today
fi
