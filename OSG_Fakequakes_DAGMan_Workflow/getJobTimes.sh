#!/bin/bash
#  
#	This program is meant to be ran on a complete set of fakequake simulations
#	It goes through fakequake output and give time stats of jobs.
#	This includes the longest job time, the shortest, the average, submission time, and more.
#



vflag=0

# Handle arguments
if [ $# -eq 2 ]; then
   while test $# -gt 0; do
	case "$1" in
		-v)
		  shift
		  dirname=$1
		  vflag=1
		  echo "-v flag true: verbose option enabled"
		  break
		  ;;
		*)
		  echo "$1 is not a recognized flag!"
		  exit 1
		  ;;
	esac
   done
elif [ $# -eq 1 ]; then
	dirname=$1
elif [ $# -gt 2 ]; then
	echo "Error: Too many arguments passed in! ($# is too many)"
	exit 1;
elif [ $# -eq 0 ]; then
	echo "No simulations directory requested, pass in a dir name as an argument to get it's time stats."
	exit 1
fi

# Check if dir is valid
if [[ ! -d "$dirname" ]]; then 
	echo "Error: $dirname is not a valid directory"
	exit 1
fi

cd $dirname

# get the name of the directory containing all of the output
preparedinput=$( ls | grep -m1 "^fakequakes_output" )
cd ..

#
# Function which takes in two times grabbed from OSG logs, gets their difference and converts to readable format
#
get_time_diff(){

  # convert time to manipulatable format (seconds)
  s1=$(date +%s -d "${1}")
  s2=$(date +%s -d "${2}")
  diff=$(( $s2 - $s1 ))
  negnum=0

  # get the dates to see if it changed so 24hrs in seconds can be added when needed
  datestrex=$3
  datestrterm=$4

  yearex=$(echo "$datestrex" | awk -F'-' '{print $1}')
  monthex=$(echo "$datestrex" | awk -F'-' '{print $2}')
  monthex=$(echo "${monthex#"${monthex%%[!0]*}"}")  	# remove leading 0s for math
  dayex=$(echo "$datestrex" | awk -F'-' '{print $3}')
  dayex=$(echo "${dayex#"${dayex%%[!0]*}"}")      # remove leading 0s for math

  yearterm=$(echo "$datestrterm" | awk -F'-' '{print $1}')
  monthterm=$(echo "$datestrterm" | awk -F'-' '{print $2}')
  monthterm=$(echo "${monthterm#"${monthterm%%[!0]*}"}")      # remove leading 0s for math
  dayterm=$(echo "$datestrterm" | awk -F'-' '{print $3}')
  dayterm=$(echo "${dayterm#"${dayterm%%[!0]*}"}")  
	
  yearchange=$((yearterm-yearex))
  monthchange=$((monthterm-monthex))
  daychange=$((dayterm-dayex))

  # if difference is negative, that means the termination time went into the next day,  correct the times
  if [[ $diff -lt "0" ]];then
	# this corrects the time when the term time went into the next day but is earlier on a 24 hr clock than the ex time

        # turn the number positive
        negnum=1
		savenum=$diff
        diff=$((diff-savenum))	# goes to 0
        diff=$((diff-savenum))   # goes to positive 
        diff=$((86400-diff))	#86400 is 24 hrs
  fi

  if [[ $daychange -gt "0" ]]; then    	
	if  [[ $negnum -eq "1" ]]; then
		daychange=$((daychange-1))	     
		add24hrs=$((86400*daychange))
		iff=$((diff+add24hrs))  
	else 
		add24hrs=$((86400*$daychange)) # for every day passed, add 24 hrs to time
		diff=$((diff+add24hrs))
	fi
  
  #elif [[ $monthchange -gt "0" ]]; then
 	# TODO: handle case where month changes


  #elif [[ $yearchange -gt "0" ]]; then
	# TODO: handle case where year changes

  fi
 

  # comment out to keep in seconds
  diff="$( awk -v n="$diff" 'BEGIN{printf "%.2f\n", (n/60) }')" # sec to min

  #return $diff
  echo $diff
}


##### --- Start --------------------------  

# Go into requested run directory
cd $dirname/$preparedinput

# move the last dag files to the directory for reading
cd dagoutput
filetocheck=dag_v2_4_dagfile.dag.dagman.log
if [ ! -f "$filetocheck" ]; then
 cd ~
 sh movelastdagfiles_v2_4.sh $dirname
fi

cd ~/$dirname/$preparedinput/dagoutput
# Get the number of rupture bundles
numLine=$(tail -7 dag_v2_4_dagfile.dag | head -1)
stringarray=($numLine)
totrupruns=${stringarray[5]}

cd ..

# get the number of waveform runs which is one less than the number of files in the dir
totruns=$(ls | wc -l)
totruns=$(($totruns-1))

# All A jobs are in this dire (rupture stuff)
cd fakequakes_output_run0

echo "There are $totrupruns rupture-bundle runs in this dir"
totruptures=$(($totrupruns*16))
echo "So there are $totruptures ruptures generated (16 ruptures per bundle)"

echo "There are $totruns waveform runs in this dir (each works on 2 ruptures)"

echo -e  "\n---------------------"




# Print out the times for the DAGMan and the three SubDags. 

# Get start and stop time of the DAGMan
cd ~/$dirname/$preparedinput/dagoutput
subtime=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $4}')
subdate=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $3}')
termtime=$(grep -m1 terminated dag_v2_4_dagfile.dag.dagman.log | awk '{print $4}')
termdate=$(grep -m1 terminated dag_v2_4_dagfile.dag.dagman.log | awk '{print $3}')
difftime=$(get_time_diff $subtime $termtime $subdate $termdate)
echo "DAGMan submitted at $subtime minutes on $subdate and terminated at $termtime minutes on $termdate - runtime was $difftime minutes"

subtime=$(grep -m1 submitted dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $4}')
subdate=$(grep -m1 submitted dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $3}')
termtime=$(grep -m1 terminated dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $4}')
termdate=$(grep -m1 terminated dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $3}')
difftime=$(get_time_diff $subtime $termtime $subdate $termdate)
echo "A-Phase submitted at $subtime minutes on $subdate and terminated at $termtime minutes on $termdate - runtime was $difftime minutes"

subtime=$(grep -m1 submitted dag_v2_bphase_dagfile.dag.dagman.log | awk '{print $4}')
subdate=$(grep -m1 submitted dag_v2_bphase_dagfile.dag.dagman.log | awk '{print $3}')
termtime=$(grep -m1 terminated dag_v2_bphase_dagfile.dag.dagman.log | awk '{print $4}')
termdate=$(grep -m1 terminated dag_v2_bphase_dagfile.dag.dagman.log | awk '{print $3}')
difftime=$(get_time_diff $subtime $termtime $subdate $termdate)
echo "B-Phase submitted at $subtime minutes on $subdate and terminated at $termtime minutes on $termdate - runtime was $difftime minutes"


subtime=$(grep -m1 submitted dag_v2_subex_dagfile.dag.dagman.log | awk '{print $4}')
subdate=$(grep -m1 submitted dag_v2_subex_dagfile.dag.dagman.log | awk '{print $3}')
termtime=$(grep -m1 terminated dag_v2_subex_dagfile.dag.dagman.log | awk '{print $4}')
termdate=$(grep -m1 terminated dag_v2_subex_dagfile.dag.dagman.log | awk '{print $3}')
difftime=$(get_time_diff $subtime $termtime $subdate $termdate)
echo "C-Phase submitted at $subtime minutes on $subdate and terminated at $termtime minutes on $termdate - runtime was $difftime minutes"




# PHASE A --------------------------------- 
echo -e  "Phase A\n---------------------"

cd ~/$dirname/$preparedinput/fakequakes_output_run0

for (( i=0 ; i<$totrupruns ; i+=1 ))
do

	# Get job times from rupture log files

	rupsubtime=$(grep -m1 submitted fakequakes_makerupts$i.log | awk '{print $4}') # submitted time
	rupextime=$(grep -m1 executing fakequakes_makerupts$i.log | awk '{print $4}') # execution time
	ruptermtime=$(grep -m1 terminated fakequakes_makerupts$i.log | awk '{print $4}') #terminated time

	rupdatesub=$(grep -m1 submitted fakequakes_makerupts$i.log | awk '{print $3}') # submitted date
	rupdateex=$(grep -m1 executing fakequakes_makerupts$i.log | awk '{print $3}') # execution date
	rupdateterm=$(grep -m1 terminated fakequakes_makerupts$i.log | awk '{print $3}') # terminated date

	rupsubdifftime=$(get_time_diff $rupsubtime $rupextime $rupdatesub $rupdateex)
	rupdifftime=$(get_time_diff $rupextime $ruptermtime $rupdateex $rupdateterm)


	# Get the job's exit-code
	foo=$(grep exit-code fakequakes_makerupts$i.log | awk '{print $11}')
	jobcode="$(printf '%s' "$foo" | cut -c1)"



	# print info
	echo "RupJob-$i was submitted at $rupsubtime on the date $rupdatesub"
	echo "RupJob-$i was executed at $rupextime on the date $rupdateex"
	echo "RupJob-$i was terminated at $ruptermtime on the date $rupdateterm"
	echo "RupJob-$i had an exit code of: $jobcode"
	
done


	



echo -e "Phase B + C\n---------------------\n"




# PHASE B & C ------------------------------ #
# Loop over all the C phase jobs and collect data

cd ~/$dirname/$preparedinput


dirnums=$(($totruns * 2))

# Goes over each run after run0 to get time stats
for (( i=2 ; i<$dirnums ; i+=2 ))
do
	cd fakequakes_output_run$i

	#get the job submitted's time
	subtime=$(grep -m1 submitted fakequakes_run$i.log | awk '{print $4}') # submitted time
	extime=$(grep -m1 executing fakequakes_run$i.log | awk '{print $4}') # execution time
	termtime=$(grep -m1 terminated fakequakes_run$i.log | awk '{print $4}') # terminated time 

	datesub=$(grep -m1 submitted fakequakes_run$i.log | awk '{print $3}')
	dateex=$(grep -m1 executing fakequakes_run$i.log | awk '{print $3}')
	dateterm=$(grep -m1 terminated fakequakes_run$i.log | awk '{print $3}')

	# Get the job's exit-code
	foo=$(grep exit-code fakequakes_run$i.log | awk '{print $11}')
	jobcode="$(printf '%s' "$foo" | cut -c1)"	
	
	
	# TODO: print info
	# print info
	echo "WaveJob-$i was submitted at $subtime on the date $datesub"
	echo "WaveJob-$i was executed at $extime on the date $dateex"
	echo "WaveJob-$i was terminated at $termtime on the date $dateterm"
	echo "WaveJob-$i had an exit code of: $jobcode"

	cd ..

done  # end of for loop





echo -e "---- DONE --------" 