#!/bin/bash
#
# Script to occur after  each  individual A job with makes 16 ruptures
#

# Get the unique name of entire DAG run and the individual rupture job number
prepinput=$1
runnum=$2
FDW_PATH=$3

# make a dir for the ruptures to be moved to if needed
cd $FDW_PATH/prepinput/$prepinput
if [ ! -d "ruptures" ]; then
	mkdir ruptures
fi

# go back to dir where this DAGMan  was launched
#cd ~/$prepinput
cd $FDW_PATH

tar -xzf preparedoutput$runnum.tar.gz
rm preparedoutput$runnum.tar.gz
cd preparedoutput$runnum

# rename list so it doesn't overwrite others
if [ -f "ruptures.list" ]; then
    mv ruptures.list ruptures_$runnum.list
    mv ruptures_$runnum.list $FDW_PATH/runningtemp/$prepinput

    # Move the ruptures to be used later for making  waveforms
	
    tar -xzf ruptures.tar.gz
    cd ruptures    

    mv *.rupt $FDW_PATH/prepinput/$prepinput/ruptures
    mv *.log $FDW_PATH/prepinput/$prepinput/ruptures
    cd ..
fi

# If distance matrices are made in run 0, prepare them
if [ "$runnum" -eq "0" ]; then
   
   dcount=$(ls *.npy 2>/dev/null | wc -l)
   if [ ! "$dcount" = "0" ]; then
	mv *.npy  $FDW_PATH/prepinput/$prepinput # move existing files to a dir to compress them
	cd  $FDW_PATH/prepinput/$prepinput
	mkdir distancematrices
	rm distancematrices.tar.gz	# remove dummy and  make new tarball with the distance matrices
	mv *.npy distancematrices
	tar -czf distancematrices.tar.gz distancematrices
	rmdir distancematrices
	cp distancematrices.tar.gz $FDW_PATH/fakequakes_output_run0/other_output # copy for user to user later
   fi

   # if no ruptures were made
   nooutfile=noout.txt
   if [ -f "$nooutfile" ]; then
      cp $nooutfile $FDW_PATH/fakequakes_output_run0/other_output
   fi
fi

# Go back to the folder  for this DAGMan run and clean up output
#cd ~/$prepinput
cd $FDW_PATH
rm -r preparedoutput$runnum



