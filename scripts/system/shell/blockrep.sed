# filename: blockrep.sed
#   author: Paolo Bonzini
# Requires:
#    (1) blocks to find and replace, e.g., findrep.txt
#    (2) an input file to be changed, input.file
#
# blockrep.sed creates a second sed script, custom.sed,
# to find the lines above the row of 4 hyphens, globally
# replacing them with the lower block of text. GNU sed
# is recommended but not required for this script.
#
# Loop on the first part, accumulating the `from' text
# into the hold space.
:a
/^----$/! {
   # Escape slashes, backslashes, the final newline and
   # regular expression metacharacters.
   s,[/\[.*],\\&,g
   s/$/\\/
   H
   #
   # Append N cmds needed to maintain the sliding window.
   x
   1 s,^.,s/,
   1! s/^/N\
/
   x
   n
   ba
}
#
# Change the final backslash to a slash to separate the
# two sides of the s command.
x
s,\\$,/,
x
#
# Until EOF, gather the substitution into hold space.
:b
n
s,[/\],\\&,g
$! s/$/\\/
H
$! bb
#
# Start the RHS of the s command without a leading
# newline, add the P/D pair for the sliding window, and
# print the script.
g
s,/\n,/,
s,$,/\
P\
D,p
#---end of script---
