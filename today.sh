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

LOGDIR=${HOME}/.timelog
SECONDS_PER_DAY=86400

function usage {
cat <<EOF
Usage: $(basename $0) [OFFSET] [adjust MINUTES]
Prints active and inactive amount of time for the current day.

With OFFSET given, prints the times for the day offset from the current day.
Adding adjust with MINUTES will modify the inactive amount with MINUTES.
Both OFFSET and MINUTES can be negative, allowing you to see in to the future.
EOF
	exit 0
}

function echoerr {
	echo $@ 1>&2
}

function fail {
	echoerr $1
	exit 1
}

function is_sourced {
	[[ "${FUNCNAME[1]}" = "source" ]] && return 0 || return 1
}

function adjust {
	local day=$1
	local adjustment=$2
	local inactivity=$(($(awk '{ print $2 }' $day) + ($adjustment * 60)))
	sed -i "s/\([0-9]\+\) [0-9]\+/\1 ${inactivity}/" $day
}

function format_time {
	local minutes=$(($1/60))
	local hours=$(($minutes/60))
	local minutes=$(($minutes%60))

	printf "%dh:%.2dm" $hours $minutes
}

function print_day {
	local day=$1
	local start=$(awk '{print $1}' $day)
	local inactive=$(awk '{print $2}' $day)
	local end=$(awk '{print $3}' $day)

	if [[ ! $end =~ ^[0-9]+$  ]]; then
		end=$(date +"%s")
	fi

	local active=$(($end-($start+$inactive)))

	echo "$(format_time $active) $(format_time $inactive)"
}

function check_help {
	for a in "$@"; do
		[[ "$a" == "-h" || "$a" == "--help" ]] && usage $0
	done
}

function main {
	check_help $@

	if [[ $1 =~ ^-?[0-9]+$ ]]; then
		timestamp=$(($(date +'%s') + ($SECONDS_PER_DAY * $1)))
		date +"%a %b %d" --date=@$timestamp
		day="${LOGDIR}/$(date +'%Y%m%d' --date=@$timestamp)"
		shift
	else
		day="${LOGDIR}/$(date +'%Y%m%d')"
	fi

	[ -e $day ] || fail "No starting time found!"

	if [ "$1" == "adjust" ]; then
		[ ! -z $2 ] || fail "Missing argument to adjust"
		adjust $day $2
	fi

	print_day $day
}

mkdir -p $LOGDIR
is_sourced || main $@
