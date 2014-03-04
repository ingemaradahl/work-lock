# work-lock

Screensaver wrapper to keep track of your working hours.

Where I work, it's up to each employee to keep track of for how long you've been at work each week.  During certain stints I found myself spending a bit too much time at work, but didn't know how much.  By writing a small shell script which wraps `xlock`, I could automatically keep track of when I got to work and when I left. work-lock is the result of refining and adding to this script during long compile times, and an attempt at being more fluent in bash.

## Installation

Copy/link `locker.sh`, `today.sh`, and `week.sh` to somewhere in your `$PATH`.  Set your screensaver settings to invoke `locker.sh`.

I'm using `xautolock`, which is preferably configured through `~/.Xresources`:
```
Xautolock.time: 5
Xautolock.locker: ~/bin/locker.sh
```

### Dependencies

* coreutils, awk, sed
* Optionally (but recommended): [zenity](https://wiki.gnome.org/action/show/Projects/Zenity)

If you have `zenity` installed, you'll be prompted each time screensaver exits (except for the first time each day or for "trivial" screen saver durations) whether you were actually working or not.  This allows work-lock to keep track of how much you've been slacking of as well!

## Configuration

Either edit the scripts, or export the following environmental variables in your profile:
* `WORKLOCK_REQUIRED`: How long each working day is, in seconds.  Defaults to 27000, i.e. 7.5h.
* `WORKLOCK_LOCKER`: Command used to lock the screen.  Defaults to `xlock`.
* `WORKLOCK_DELAY`: How long your screensaver delay is.  Not needed when using xautolock and .Xresources.

The screensaver _must_ be blocking; it is assumed that once the screensaver command exits, the user is active.

## Usage

`today.sh` shows for how long you've been working, and how long you've been "inactive" for the current day. The amount of inactive time can be altered by passing `adjust` with a duration in minutes.  Additionally it can take an offset to show the times for previous days.

```
$ today.sh
4h:23m 0h:42m
$ today.sh adjust -10
4h:33m 0h:32m
```

`week.sh` summarizes the current weeks working times and displays a diff off the required working time for each day and the week in whole.  As with `today.sh`, it can take an offset showing previous weeks.

```
$ week.sh -6
20 Jan - 24 Jan
Monday:    6h:52m -0h:37m
Tuesday:   8h:31m +1h:01m
Wednesday: 8h:56m +1h:26m
Thursday:  6h:34m -0h:55m
Friday:    6h:24m -1h:05m
+/-:              -0h:11m
```
