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

function echoerr {
	echo "$@" 1>&2
}

function fail {
	echoerr "$@"
	exit 1
}

function checkstyle {
	local files="$@"
	local args="-f gcc --exclude="
	args+="SC2086" # Overly protective of quoting
	args+=",SC2046" # Dito
	args+=",SC1000" # Broken check for unescaped '$' in heredocs

	$SHELLCHECK $args $files | awk '
		BEGIN { failed = 0 }
		# Hard coded ignore patterns
		!/today\.sh:[0-9]+:34:.*\[SC2015\]/ { print $0; failed=1 }
		END { exit failed }'
}

function checklength {
	awk '
		BEGIN {
			failed = 0;
			format = "%s:%d: Line length exceeds 80 characters (%d chars)\n"
		}
		{
			gsub(/\t/, "    ") # Expand tabs to 4 spaces
			l = length($0)
			if (l > 80) {
				printf(format, FILENAME, FNR, l)
				failed = 1
			}
		}
		END { exit failed }' "$@"
}

SHELLCHECK=$(command -v shellcheck)

if [[ $? -ne 0 || -z "$SHELLCHECK" ]]; then
	fail -e "Please install shellcheck (http://www.shellcheck.net/about.html)\n\
to run style checks"
fi

EXIT_STATUS=0
checkstyle $(dirname $0)/../*.sh $0
EXIT_STATUS+=$((EXIT_STATUS+$?))
checklength $(dirname $0)/../*.sh $0
EXIT_STATUS+=$((EXIT_STATUS+$?))

if [ $EXIT_STATUS -eq 0 ]; then
	echo "PASS"
else
	echo "FAIL"
fi

exit $EXIT_STATUS
