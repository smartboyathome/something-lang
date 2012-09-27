# This is a comment.

# A makefile must be called makefile or Makefile.  The command is 'make' .
# If you don't tell make what to make, it makes the first thing in this file.
# These 'targets' start in column 1 and are followed by a colon.  Following
# the colon are the dependencies (files).  If any file in the dependency list
# is updated, then 'make' executes the commands found on the following lines.
# These commands must start with a tab.

# The 'touch' command is useful for faking an update, e.g., "touch ll" 

mini-pascal:  mini-pascal.l main.cpp                      # if mini-pascal.l or main.cpp change, flex and g++ are executed
	          flex mini-pascal.l                          # creates lex.yy.c function
	          g++ lex.yy.c main.cpp -lfl -o mini-pascal   # compiles everything into one nice, neat executable
