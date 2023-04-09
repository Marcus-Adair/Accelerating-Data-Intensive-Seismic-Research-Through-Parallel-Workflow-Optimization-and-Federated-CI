#!/bin/bash
#
# SCript to occur after all of the A jobs are done making ruptures

prepinput=$1


# Combine all the ruptures list into one and put it in the right place

cd ~/runningtemp

# if a temp  dir was made to store created rupture lists
if [ -d "$prepinput" ]; then
	cd $prepinput

	# for each rupture list made by A
	> ruptures.txt
	for ruplist in *.list; do

	# Get the lines from the list
	FILE=$(cat $ruplist)
	    for LINE in $FILE
	    do
		# add them to the new list
		echo "$LINE" >> ruptures.txt
	    done
	done
	
	mv ruptures.txt ruptures.list
				
	cp ruptures.list ~/$prepinput/fakequakes_output_run0/other_output # copy for user to user later

	mv ruptures.list ~/prepinput/$prepinput	# move to be used later in DAGMan

	# clean up the temp folder storing rupture lists
	cd ..
	rm -r $prepinput
fi
