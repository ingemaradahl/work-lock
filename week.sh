#!/usr/bin/env sh

# Copyright 2014 Ingemar Ådahl,
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

source $(dirname $0)/today.sh

SECONDS_REQUIRED=${TIMELOG_REQUIRED-27000}

TOTAL_SECONDS=0
TOTAL_REQUIRED=0

function usage {
cat <<EOF
Usage: $(basename $0) [OFFSET]
Prints active, inactive, and summarized amount of time for the current week.

With OFFSET given, prints the times for the week offset from the current week.
EOF
	exit 0
}

function active_time {
	local day=$1
	local start=$(awk '{print $1}' $day)
	local inactive=$(awk '{print $2}' $day)
	local end=$(awk '{print $3}' $day)

	if [[ ! $end =~ ^[0-9]+$  ]]; then
		local end=$(date +"%s")
	fi

	echo $(($end - $start - $inactive))
}

function format_diff {
	local diff=$1
	local neg=$([ $diff -ge 0 ]; echo $?)
	local sign="+"
	local color="\033[1;32m"
	local no_color="\033[0m"

	if [ $neg -eq 1 ]; then
		diff=$((0-$1))
		sign="-"
		color="\033[1;31m"
	fi

	local minutes=$(($diff/60))
	local hours=$(($minutes/60))
	local minutes=$(($minutes%60))

	echo -e $(printf "%s%s%dh:%.2dm%s" $color "$sign" $hours $minutes $no_color)
}

function print_day {
	local day_file="${LOGDIR}/$(date +%Y%m%d --date=@$1)"
	local weekday=$(date +"%A" --date=@$1)

	[ ! -e $day_file ] && return 1

	local active=$(active_time $day_file)
	local diff=$(($active-$SECONDS_REQUIRED))
	TOTAL_SECONDS=$(($TOTAL_SECONDS+$active))
	printf "%-10s %s %s\n" \
		"$weekday:" \
		$(format_time $active) \
		$(format_diff $diff)
}

function find_monday {
	local offset=$1
    echo $(($(date +"%s") - (($(date +"%u") - 1 - $offset*7)*$SECONDS_PER_DAY)))
}

check_help $@

if [ ! -z $1 ]; then
	offset=$1
else
	offset=0
fi

monday=$(find_monday $offset)
friday=$(($monday + ($SECONDS_PER_DAY*4)))

echo $(date +"%d %b" --date=@$monday) - $(date +"%d %b" --date=@$friday)

for d in 0 1 2 3 4; do
	print_day $(($monday + ($SECONDS_PER_DAY * $d)))
	[ $? -eq 0 ] && TOTAL_REQUIRED=$(($TOTAL_REQUIRED+$SECONDS_REQUIRED))
done

echo -e "+/-:              $(format_diff $(($TOTAL_SECONDS-$TOTAL_REQUIRED)))"
