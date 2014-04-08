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
SECONDS_REQUIRED=${WORKLOCK_REQUIRED-27000}

function usage {
cat <<EOF
Usage: $(basename $0) [OFFSET] [eod | adjust [START] MINUTES]
Prints active and inactive amount of time for the current day.

With OFFSET, the times for the day offset from the current day is printed.

Optionally, one of the following commands is accepted:
   adjust   modify the inactive amount with MINUTES. Additionally, the starting
            time of the given day can be changed by offsetting with START
            minutes.  OFFSET, START, and MINUTES can all be negative.
   eod      print the time at which a full working day is completed.

Example:
  $ today.sh
  6h:17m 0h:20m
  $ today.sh adjust -10
  6h:27m 0h:10m
  $ today.sh adjust 10 0
  6h:17m 0h:10m
EOF
	exit 0
}

function echoerr {
	echo "$@" 1>&2
}

function fail {
	echoerr $(basename $0): $1
	exit 1
}

function is_sourced {
	[ "${FUNCNAME[1]}" = "source" ] && return 0 || return 1
}

function expect_digit {
	[[ $1 =~ ^-?[0-9]+$ ]] || fail "$2"
}

function adjust {
	local day=$1
	local start_shift=$(($2 * 60))
	local time_shift=$(($3 * 60))

	local inactivity=$(($(awk '{ print $2 }' $day) + time_shift))

	if [[ $start_shift -eq 0 && $inactivity -ge 0 ]]; then
		sed -i "s/\([0-9]\+\) [0-9]\+/\1 ${inactivity}/" $day
	else
		local start=$(($(awk '{print $1}' $day) + start_shift))
		if [ $inactivity -lt 0 ]; then
			start=$((start + inactivity))
			echo "$start 0" > $day
		else
			echo "$start $inactivity" > $day
		fi
	fi
}

function format_time {
	local minutes=$(($1/60))
	local hours=$((minutes/60))
	local minutes=$((minutes%60))

	printf "%dh:%.2dm" $hours $minutes
}

function print_day {
	local day=$1
	local start=$(awk '{print $1}' $day)
	local inactive=$(awk '{print $2}' $day)
	local end=$(awk '{print $3}' $day)

	if [[ ! $end =~ ^[0-9]+$ ]]; then
		end=$(date +"%s")
	fi

	local active=$((end-(start+inactive)))

	echo "$(format_time $active) $(format_time $inactive)"
}

function check_help {
	for a in "$@"; do
		[[ "$a" = "-h" || "$a" = "--help" ]] && usage $0
	done
}

function main {
	check_help "$@"

	if [[ $1 =~ ^-?[0-9]+$ ]]; then
		timestamp=$(($(date +'%s') + (SECONDS_PER_DAY * $1)))
		date +"%a %b %d" --date=@$timestamp
		local day="${LOGDIR}/$(date +'%Y%m%d' --date=@$timestamp)"
		shift
	else
		local day="${LOGDIR}/$(date +'%Y%m%d')"
	fi

	[ -e $day ] || fail "No starting time found!"

	if [ -n "$1" ]; then
		case "$1" in
			eod)
				local start=$(awk '{print $1}' $day)
				local inactive=$(awk '{print $2}' $day)
				date +'%R' --date=@$((start+inactive+SECONDS_REQUIRED))
				return 0
				;;
			adjust)
				[ -z $2 ] && fail "Missing argument to adjust"
				expect_digit $2 "Bad argument to adjust: $2"

				if [ -z $3 ]; then
					adjust $day 0 $2
				else
					expect_digit $3 "Bad argument to adjust: $3"
					adjust $day $2 $3
				fi
				;;
			*)
				usage $0
		esac
	fi

	print_day $day
}

mkdir -p "$LOGDIR"
is_sourced || main "$@"
