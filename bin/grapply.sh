#!/bin/sh

# Note: about the sed 'a' command
# * the 'a\' + LF + <line> is POSIX compl.
# * the 'a' + space + <line> is not POSIX compl.

grapply() {
	local dryrun=true
	while [ $# -gt 0 ]; do
		case "$1" in
			('--')			shift; break			;;
			('--help'|'-h')
				echo "Usage: grapply [options] [--]"
				echo "Options:"
				echo "    -n|--dry-run       make a simulation, show the diff"
				echo "    -i|--in-place      apply the changes in targeted files"
				return 0
			;;
			('--dry-run'|'-n')	dryrun=true 			;;
			('--in-place'|'-i')	dryrun=false			;;
			(*)			grapply >&2 --help; return 1	;;
		esac
		shift
	done
	IFS=':'
	while read -r file num content; do

		# we must quote all \ -> \\ because the sed 'a' command use it as special behavior
		content="$(printf '%s' "$content" | sed --posix -e 's,\\,\\\\,g')"

		if ${dryrun:-true}; then
			local o="$(mktemp)"
			cp -- "$file" "$o"
			local n="$(mktemp)"
			sed --posix -e "${num}"' {
				a\
'"$content"'
				d
			}' "$file" > "$n"
			printf -- '--- %s (original)\n' "$file"
			printf -- '+++ %s (simulation)\n' "$file" 
			diff -u -- "$o" "$n" | sed --posix '1,2 d'
			rm -f -- "$o" "$n"
		else
			sed --posix -i -e "${num}"' {
				a\
'"$content"'
				d
			}' "$file"
		fi
	done
}

grapply "$@"
