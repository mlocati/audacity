#!/bin/sh

set -o errexit
set -o nounset

if ! which grep >/dev/null || ! which sed >/dev/null || ! which cmp >/dev/null || ! which mktemp >/dev/null; then
    cat <<EOT >&2
This script requires these commands:
- grep
- sed
- cmp
- mktemp

EOT
    exit 1
fi

# Arguments:
#   $1: the error to be displayed (optional)
showSyntax() {
    if [ -n "${1:-}" ]; then
        printf '%s\n\n' "$1" >&2
    fi
    cat <<EOT
Syntax:
- Normalize a file:
$0 <input> [output]

- Check if a file is normalized:
$0 --check <file>

EOT
    if [ -n "${1:-}" ]; then
        exit 1
    fi
    exit 0
}

# Arguments:
#   $@: the script arguments
#
# Set:
#   OPERATION (fix or check)
#   INPUT_FILE
#   OUTPUT_FILE
processArgs() {
	OPERATION=''
    INPUT_FILE=''
    OUTPUT_FILE=''
	while :; do
		if test $# -lt 1; then
			break
		fi
        case "$1" in
            -h | --help)
                showSyntax
                ;;
            --check)
                if [ -n "$OPERATION" ]; then
                    showSyntax 'Operation already specified.'
                fi
                OPERATION=check
                ;;
            *)
                if [ -z "$INPUT_FILE" ]; then
                    INPUT_FILE="$1"
                elif [ -z "$OUTPUT_FILE" ]; then
                    OUTPUT_FILE="$1"
                else
                    showSyntax 'Too many arguments.'
                fi
        esac
		shift
	done
    if [ -z "$OPERATION" ]; then
        OPERATION=fix
    fi
    case "$OPERATION" in
        fix)
            if [ -z "$INPUT_FILE" ]; then
                showSyntax 'Input file not specified.'
            fi
            if [ -z "$OUTPUT_FILE" ]; then
                OUTPUT_FILE="$INPUT_FILE"
            fi
            ;;
        check)
            if [ -n "$OUTPUT_FILE" ]; then
                showSyntax 'Output file not applicable for the check operation.'
            fi
            ;;
    esac
}

processArgs "$@"

if [ ! -f "$INPUT_FILE" ]; then
    printf 'Unable to find the input file %s\n' "$INPUT_FILE" >&2
    exit 1
fi
if ! grep -Eq '^msgid\s' "$INPUT_FILE" || ! grep -Eq '^msgstr\s' "$INPUT_FILE"; then
    printf 'The input file %s is not a .pot/.po gettext file!\n' "$INPUT_FILE" >&2
    exit 1
fi
TEMP_FILE="$(mktemp)"
if [ -z "$TEMP_FILE" ] || [ ! -f "$TEMP_FILE" ]; then
    echo 'Failed to create a temporary file!' >&2
fi

# 1st sed: replace Windows line endings with Posix line endings
# 2st sed: replace old Mac line endings with Posix line endings
# 3rd sed: trim trailing spaces/tabs
# 4th sed: make it so we have only one line for every msgid/msgid_plural/msgstr
# 5th sed: split strings at '\n'
# 6th sed: remove lines containing only ""
cat "$INPUT_FILE" \
    | sed -z 's/\r\n/\n/g' \
    | sed -z 's/\r/\n/g' \
    | sed 's/[ \t]*$//' \
    | sed -z 's/"\n"//g' \
    | sed -z 's/\\n/\\n"\n"/g' \
    | sed '/^""$/d' \
    >"$TEMP_FILE"

if [ ! -s "$TEMP_FILE" ]; then
    echo 'Failed to normalize the input file!' >&2
else
    case "$OPERATION" in
        check)
            if cmp -s "$INPUT_FILE" "$TEMP_FILE"; then
                echo 'The file is already normalized.'
                rc=0
            else
                echo 'The file is not normalized.'
                rc=1
            fi
            ;;
        fix)
            cat "$TEMP_FILE" >"$OUTPUT_FILE" # Don't use mv/cp, so that we preserve the output file owner/permissions
            rc=0
            ;;
    esac
fi
rm "$TEMP_FILE"
exit $rc
