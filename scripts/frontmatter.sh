# shellcheck shell=bash
# Frontmatter readers shared by validate.sh and install.sh.
#
# Both scripts need the same answer to "what is this skill's description?", and most
# skills here write it as a YAML folded scalar:
#
#     description: >
#       first line
#       second line
#
# A one-line `sed` returns the `>` marker for those — which is non-empty, so a validator
# built on it would pass a skill whose description is actually blank. Keeping one reader
# means the validator and the installer can never disagree about what a skill says.
#
# Targets bash 3.2, and uses only POSIX awk constructs so stock macOS awk can run it.

# skill_field <file> <field> — value of a frontmatter field, folded scalars flattened
# to one line. Prints nothing when the field is absent or its block is empty.
skill_field() {
	awk -v want="$2" '
		NR == 1 && $0 == "---" { infm = 1; next }
		!infm { exit }
		$0 == "---" { exit }

		# Block scalar: the value is the indented lines that follow.
		$0 ~ "^" want ":[ \t]*[|>]" { block = 1; next }

		# Plain scalar: the value is the rest of this line.
		$0 ~ "^" want ":" {
			line = $0
			sub("^" want ":[ \t]*", "", line)
			print line
			exit
		}

		# A block ends at the first line that is not indented.
		block && /^[ \t]+/ {
			line = $0
			sub(/^[ \t]+/, "", line)
			out = out (out == "" ? "" : " ") line
			next
		}
		block { exit }

		END { if (block && out != "") print out }
	' "$1"
}
