#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Date: September 2022   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute 
#
# This file runs all the steps to run FakeQuake simulations. It will recycle distance and G matrices if they're provided, or
# it will generate the matrices if they're not provided. It does all this in a Singularity container which has the MudPy software
# and a python environment to run the FakeQuakes in. This script also times the FakeQuakes run from beginning to end and reports it.
#----------------------------------------------------------------------------------------------------------------------------

# Activate the Python environment to run FakeQuakes in
cd /
. quake3.6/bin/activate
cd ~

# The name of the dir which contains the FakeQuake folder structure. 
# Also the name of the dir in ~/prepinput where the input files are stored
projname=$1


# Set to determine the number of ruptures to generate  (Number of ruptures = Nrealizations * length of Target_MW (which is set at 4 for our purposes))
# So the total ruptures (& waveforms for them) will be 4x the what Nrealizations is set to here,
# IMPORTANT NOTE:  let Nrealizations % ncpus=0 --> So Nrealizations must be a multiple of 4 and 4 is the minimum (ncpus is either 4 or 1 when running)
nrealizations=$2


# Parameter file names
gflist=$3
fault=$4
mod=$5
xyz=$6
mshout=$7

# Important parameters chosen by the user 
utmzone=$8
timeepi=$9
targetmw=${10}
maxslip=${11}
hypocenter=${12}


# The name of the file to write status updates to
status_txt=${projname}_status


# Make a beginning time stamp
begintime=$(date +"%T")
begindate=$(date +"%Y-%m-%d")


# Make a beginning time stamp for rupture jobs
beginRupTime=$(date +%s)


some_output=$(echo "STARTING:")
echo "$some_output" >> $status_txt.txt
some_output=$(echo "This Fakequakes run started at the time $begintime during the day $begindate.")
echo "$some_output" >> $status_txt.txt
some_output=$(echo -e "--------------------------------\n")
echo "$some_output" >> $status_txt.txt

# Init the FakeQuakes folder structure
python /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py init -home=/home/marcus/projects -project_name=$projname -nrealizations=$nrealizations -max_slip=$maxslip -utm_zone=$utmzone -time_epi=$timeepi -hypocenter=$hypocenter -target_mw=$targetmw


# Copy all the input files to their place in the init'ed folder 
cd ~/prepinput/$projname

cp *.mod /home/marcus/projects/$projname/structure
cp *.fault /home/marcus/projects/$projname/data/model_info
cp *.mshout /home/marcus/projects/$projname/data/model_info
cp *.xyz /home/marcus/projects/$projname/data/model_info
cp *.gflist /home/marcus/projects/$projname/data/station_info

# If any matrices are provided to recycle, move them to their place in the MudPy folder structure
mseedsprovided=0
npysprovided=0
mcount=`ls -1 *.mseed 2>/dev/null | wc -l`
if [ $mcount != 0 ]; then 
	cp *.mseed /home/marcus/projects/$projname/GFs/matrices
	mseedsprovided=1
fi 

dcount=`ls -1 *.mseed 2>/dev/null | wc -l`
if [ $dcount != 0 ]; then
        cp *.npy /home/marcus/projects/$projname/data/distances
	npysprovided=1
fi
cd ~


# Make Ruptures and recycle distance matrices or not if they're provided
if [ $npysprovided -eq 1 ]; then
	python /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_ruptures -load_distances=1 -home=/home/marcus/projects -project_name=$projname -gf_list=$gflist  -fault_name=$fault -model_name=$mod -slab_name=$xyz -mesh_name=$mshout -nrealizations=$nrealizations -max_slip=$maxslip -utm_zone=$utmzone -time_epi=$timeepi -hypocenter=$hypocenter -target_mw=$targetmw
else
        python /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_ruptures -load_distances=0 -home=/home/marcus/projects -project_name=$projname -gf_list=$gflist  -fault_name=$fault -model_name=$mod -slab_name=$xyz -mesh_name=$mshout -ncpus=1 -nrealizations=$nrealizations -max_slip=$maxslip -utm_zone=$utmzone -time_epi=$timeepi -hypocenter=$hypocenter -target_mw=$targetmw


fi

# Make a end time stamp for rupture jobs
endRupTime=$(date +%s)


# Make a beginning time stamp for wave jobs
beginWaveTime=$(date +%s)


# Make G files if the G matrices weren't provided
if [ $mseedsprovided -eq 0 ]; then
	python /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_g_files -home=/home/marcus/projects -project_name=$projname -gf_list=$gflist  -fault_name=$fault -model_name=$mod -slab_name=$xyz -mesh_name=$mshout -nrealizations=$nrealizations -max_slip=$maxslip -utm_zone=$utmzone -time_epi=$timeepi -hypocenter=$hypocenter -target_mw=$targetmw
fi


# Make waveforms and recyle G matrices or not based on if they're provided
if [ $mseedsprovided -eq 1 ]; then
	python /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_waveforms -g_from_file=1 -home=/home/marcus/projects -project_name=$projname -gf_list=$gflist  -fault_name=$fault -model_name=$mod -slab_name=$xyz -mesh_name=$mshout -nrealizations=$nrealizations -max_slip=$maxslip -utm_zone=$utmzone -time_epi=$timeepi -hypocenter=$hypocenter -target_mw=$targetmw
else
	python /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_waveforms -g_from_file=0 -home=/home/marcus/projects -project_name=$projname -gf_list=$gflist  -fault_name=$fault -model_name=$mod -slab_name=$xyz -mesh_name=$mshout -nrealizations=$nrealizations -max_slip=$maxslip -utm_zone=$utmzone -time_epi=$timeepi -hypocenter=$hypocenter -target_mw=$targetmw
fi


# Make a ending timestamp
endtime=$(date +"%T")
enddate=$(date +"%Y-%m-%d")

# Calculate the average job time for rupture and wave jobs
endWaveTime=$(date +%s)
elapsedRupTime=$((endRupTime - beginRupTime))
elapsedWaveTime=$((endWaveTime - beginWaveTime))
rupMinutes=$(echo "scale=2; $elapsedRupTime/60" | bc)
waveMinutes=$(echo "scale=2; $elapsedWaveTime/60" | bc)
numRupJobs=$(($nrealizations * 4))
numRupJobs=$(($numRupJobs / 16))
numWaveJobs=$(($numRupJobs / 2 ))
avgRupJobTime=$(echo "scale=2; $numRupJobs/$rupMinutes" | bc)
avgWaveJobTime=$(echo "scale=2; $numWaveJobs/$waveMinutes" | bc)
#echo "Average Rupture Job Time in minutes: $avgRupJobTime"
#echo "Average Wave Job Time in minutes: $avgWaveJobTime"
some_output=$(echo -e "--Avg job times---\nAverage Rupture Job Time in minutes: $avgRupJobTime")
echo "$some_output" >> $status_txt.txt
some_output=$(echo -e "Average Wave Job Time in minutes: $avgWaveJobTime \n----------")
echo "$some_output" >> $status_txt.txt


#--------------------------------------------#
# CALCULATE THE TOTAL TIME TO RUN FAKEQUAKES #
#--------------------------------------------#

# convert time to manipulatable format (seconds)
s1=$(date +%s -d "$begintime")
s2=$(date +%s -d "$endtime")
diff=$(( $s2 - $s1 ))   # get the difference in time
negnum=0


# extract the numbers from the date to do time math to see if things went over multiple days
yearex=$(echo "$begindate" | awk -F'-' '{print $1}')
monthex=$(echo "$begindate" | awk -F'-' '{print $2}')
monthex=$(echo "${monthex#"${monthex%%[!0]*}"}")        # remove leading 0s for math
dayex=$(echo "$begindate" | awk -F'-' '{print $3}')
dayex=$(echo "${dayex#"${dayex%%[!0]*}"}")


yearterm=$(echo "$enddate" | awk -F'-' '{print $1}')
monthterm=$(echo "$enddate" | awk -F'-' '{print $2}')
monthterm=$(echo "${monthterm#"${monthterm%%[!0]*}"}")      # remove leading 0s for math
dayterm=$(echo "$enddate" | awk -F'-' '{print $3}')
dayterm=$(echo "${dayterm#"${dayterm%%[!0]*}"}")


yearchange=$(( $yearterm - $yearex ))
monthchange=$(( $monthterm - $monthex ))
daychange=$(( $dayterm - $dayex ))


# if difference is negative, that means the termination time went into the next day,  correct the times
  if [[ $diff -lt "0" ]];then
	# this corrects the time when the term time went into the next day but is earlier on a 24 hr clock than the ex time

        # turn the number positive
        negnum=1
	    savenum=$diff
        diff=$(( $diff - $savenum  ))	# goes to 0
        diff=$(( $diff - $savenum  ))   # goes to positive 
        diff=$(( 86400 - $diff ))	#86400 is 24 hrs
  fi

  # take account for if things went into other days
  if [[ $daychange -gt "0" ]]; then
      	
      if  [[ $negnum -eq "1" ]]; then
        daychange=$(( $daychange - 1 ))	     
	add24hrs=$(( 86400 * $daychange ))
	diff=$(( $diff + $add24hrs ))  
      else 

	add24hrs=$(( 86400 * $daychange )) # for every day passed, add 24 hrs to time
	diff=$(( $diff + $add24hrs ))
		
      fi
  
  #elif [[ $monthchange -gt "0" ]]; then
 	# TODO: handle case where month changes


  #elif [[ $yearchange -gt "0" ]]; then
	# TODO: handle case where year changes

  fi

diff="$( awk -v n="$diff" 'BEGIN{printf "%.2f\n", (n/60) }')" # sec to min

#---------------------------------------








# FINAL OUTPUT:

totalrups="$( awk -v n="$nrealizations" 'BEGIN{printf "%.0f\n", (n*4) }')"


some_output=$(echo "ENDING:")
echo "$some_output" >> $status_txt.txt
some_output=$(echo "This Fakequakes run ended at the time $endtime during the day $enddate.")
echo "$some_output" >> $status_txt.txt
some_output=$(echo "The FakeQuakes run took a total of $diff minutes to run and complete.")
echo "$some_output" >> $status_txt.txt
some_output=$(echo "There were $totalrups FakeQuake ruptures generated along with waveforms for each them.")
echo "$some_output" >> $status_txt.txt
some_output=$(echo -e "--------------------------------\n")
echo "$some_output" >> $status_txt.txt

