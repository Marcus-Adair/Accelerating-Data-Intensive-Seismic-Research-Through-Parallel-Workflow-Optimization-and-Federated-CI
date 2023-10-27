#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Date: September 2022   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute 
#
#
#  
#	This program is meant to be ran while fakequake simulations are going.
#	It goes through fakequake output and give time stats of jobs.
#	This includes the length of jobs in minutes, submission time, an estimated time left, and more


phaseArunning=0
phaseBrunning=0


# Handle arguments
vflag=0
if [ $# -eq 2 ]; then
   while test $# -gt 0; do
        case "$1" in
                -v)
                  shift
		  # get the name of the unique folder for this run
                  preparedinput=$1
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
	# get the name of the unique folder for this run
        preparedinput=$1
elif [ $# -gt 2 ]; then
        echo "Error: Too many arguments passed in! ($# is too many)"
        exit 1;
elif [ $# -eq 0 ]; then
        echo "No simulations directory requested, pass in a dir name as an argument to get it's running time stats."
        exit 1
fi




# get the name of the unique file holding the input for this run
#preparedinput=$(grep dag_v2_A_prescript.sh dag_v2_3_dagfile.dag | awk '{print $5}')


# go into the folder to get stats for the run
cd ~/$preparedinput

# get the number of rupture bundles launched from the Dagfile
nsims=$(grep dag_v2_4_A_prescript.sh dag_v2_4_dagfile.dag | awk '{print $6}')


if [[ ! -d "fakequakes_output_run2" ]]; then # If a dir doesn't exist for the the first C phase job, B or A is still running
    
	if [[ ! -d "fakequakes_output_run0" ]]; then # if no 0 dir then its been moved to another foler because of completion
		echo "Error: This set of FakeQuake simulations is not currently running."
		exit 1
	fi   
    cd fakequakes_output_run0
	
    # decide if phase A or B is running
    if [ ! -f fakequakes_run0.log ]; then # if no .log file for B Phase  then Phase A is still running
        phaseArunning=1 
    else 
        phaseBrunning=1
   fi

    cd ..
fi



echo "The number of rupture bundles launched: $nsims"

numrups=`expr $nsims \* 16`
echo "With each bundle making 16 ruptures, there is $numrups being made."

#vflag=0
# Handle arguments
#if [ $# -eq 2 ]; then
#   while test $# -gt 0; do
#	case "$1" in
#		-v)
#		  vflag=1
#		  shift
#		  echo "-v flag true: verbose option enabled"
#		  break
#		  ;;
#		*)
#		  echo "$1 is not a recognized flag! Use the -v or no arguments."
#		  shift
#		  exit 1
#		  ;;
#	esac
#   done
#elif [ $# -gt 2 ]; then
#	echo "Too many arguments. Only the -v (verbose) flag is aloud."
#	exit 1
#fi


#
# Function which takes in two times grabbed from OSG logs, gets their difference and converts to readable format
#
get_time_diff(){

  # convert to manipulatable format (seconds)
  s1=$(date +%s -d "${1}")
  s2=$(date +%s -d "${2}")
  diff=$((s2-s1))
  negnum=0


  # get the dates to see if it changed so 24hrs in seconds can be added when needed
  datestrex=$3
  datestrterm=$4

  # check dates to see if the run went into another day
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
	
  #yearchange=$(($yearterm-$yearex))
  #monthchange=$(( $monthterm - $monthex ))
  #daychange=$(( $dayterm - $dayex )) 
 
  yearchange=$((yearterm-yearex))
  monthchange=$((monthterm-monthex))
  daychange=$((dayterm-dayex))  

  # if difference is negative, that means the termination time went into the next day,  correct the times
  if [[ $diff -lt "0" ]];then
        # turn the number positive
        savenum=$diff
        diff=$((diff-savenum))
        diff=$((diff-savenum))
        diff=$((86400-diff))
  fi

  if [[ $daychange -gt "0" ]]; then
      	
      if  [[ $negnum -eq "1" ]]; then
        daychange=$((daychange-1))	     
	add24hrs=$((86400*daychange))
	diff=$((diff+add24hrs))  
      else 

	add24hrs=$((86400 *daychange)) # for every day passed, add 24 hrs to time
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



#init
subtime=0
extime=0
datesub=0
dateex=0

# ----- Handles when Phase A or B is still running
if [[ "$phaseArunning" -eq "1" || "$phaseBrunning" -eq "1" ]]; then

	runningPhase="B"
	# if phase A is running         
	if [[ "$phaseArunning" -eq "1" ]]; then
		runningPhase="A"
	fi

	echo  "Phase $runningPhase is currently running."
		
	# get times
	cd ~/$preparedinput/fakequakes_output_run0
	if [[ "$phaseArunning" -eq "1" ]]; then 
		subtime=$(grep -m1 submitted fakequakes_makerupts0.log | awk '{print $4}')
		extime=$(grep -m1 executing fakequakes_makerupts0.log | awk '{print $4}')

		datesub=$(grep -m1 submitted fakequakes_makerupts0.log | awk '{print $3}')
		dateex=$(grep -m1 executing fakequakes_makerupts0.log | awk '{print $3}')
	else
		subtime=$(grep -m1 submitted fakequakes_run0.log | awk '{print $4}')
		extime=$(grep -m1 executing fakequakes_run0.log | awk '{print $4}')
	
		datesub=$(grep -m1 submitted fakequakes_run0.log | awk '{print $3}')
                dateex=$(grep -m1 executing fakequakes_run0.log | awk '{print $3}')
	fi
	cd ..

	if [ ! -z $extime ]; then # if executions time is not empty and exists
		
		#  -- When Phase A or B is executing
		curtime=$(date +"%T")
		curdate=$(date +"%Y-%m-%d")
		diffsubtime=$(get_time_diff $subtime $extime $datesub $dateex)
		difftime=$(get_time_diff $extime $curtime $dateex $curdate)

		echo "Phase $runningPhase took $diffsubtime minutes from submission to execution."
		echo "Phase $runningPhase has been running for $difftime minutes since execution started."
		
		if [[ "$phaseArunning" -eq "1" ]]; then  
		

			cd ~/prepinput/$preparedinput
			filename=ruptures.list
			firstline=$(head -n 1 $filename)
			rupmessage="No ruptures were provided."
			if [ "$firstline" == "$rupmessage"  ]; then
				 echo "Phase A (make ruptures step) is still running and making $numrups ruptures for the user."
			fi			
		
		# ------------------------------------------ Phase B --
		else		
			cd ~/../../../../../ospool/ap21/data/marcus_adair/old-public/prepinput
	
			# Check in public if an msseds matrix exists or not.	
			if [ -d "preparedinput" ]; then
				if [ ! -f "mseeds.tar.gz" ]; then
					echo "Phase B (make GFs/synths step) is still running and making GFs/synths.."
                              		echo "(Phase B also makes generates one run of waveforms)"
				else
					echo "Phase B is running and making one round of waveforms."
				fi 
			fi
				
		fi

		#exit 0
	else
		# -- When the phase is waiting to execute
		curtime=$(date +"%T")	
		curdate=$(date +"%Y-%m-%d")
		difftime=$(get_time_diff $subtime $curtime $datesub $curdate)
		echo "Phase $runningPhase was submitted $difftime minutes ago and is waiting to start execution."
		#exit 0
	fi
fi



# Loop through A jobs and report info/collect stats	

# init vars
longestrupsub=0
longestrupsubtime=0
shortestrupsub=0
shortestrupsubtime=0
averagerupsubtime=0

# initialize vars
longestrup=0
longestruptime=0

shortestrup=0
shortestruptime=0

accumruptime=0
failedrupatts=0
successrupatts=0
currruprunning=0
notrupsubbed=0

cd ~/$preparedinput/fakequakes_output_run0

# check if the first rupture job is still running by counting files
numfiles=$( ls -1q * | wc -l )
if [[ "$numfiles" -gt "3" ]];  then
#if [[ "$phaseArunning" -eq "1" ]]; then

    for (( i=0 ; i<$nsims ; i++ ))
    do
	#
	if [[ -f fakequakes_makerupts$i.error ]] && [[ -f fakequakes_makerupts$i.out ]]; then # if .error  & .out files exist then run is complete 
		
		#get the job's submitted time and termination time
                rupsubtime=$(grep -m1 submitted fakequakes_makerupts$i.log | awk '{print $4}')
                rupextime=$(grep -m1 executing fakequakes_makerupts$i.log | awk '{print $4}')
                ruptermtime=$(grep -m1 terminated fakequakes_makerupts$i.log | awk '{print $4}')

                rupdatesub=$(grep -m1 submitted fakequakes_makerupts$i.log | awk '{print $3}')
                rupdateex=$(grep -m1 executing fakequakes_makerupts$i.log | awk '{print $3}')
                rupdateterm=$(grep -m1 terminated fakequakes_makerupts$i.log | awk '{print $3}')

                rupdiffsubtime=$(get_time_diff $rupsubtime $rupextime $rupdatesub $rupdateex)
                rupdifftime=$(get_time_diff $rupextime $ruptermtime $rupdateex $rupdateterm)

                # Get the job's exit-code
                foo=$(grep exit-code fakequakes_makerupts$i.log | awk '{print $11}')
                jobcode="$(printf '%s' "$foo" | cut -c1)"

                # keep track of failed job count
                if [[ "$jobcode" -ne "0"  ]]; then
                        failedrupatts=$(( $failedrupatts + 1 ))
                fi

		# Save longest/shortest times
                                                                             	                          		#  longest rupture submission time
                if [[ `echo "$rupdiffsubtime $longestrupsubtime" | awk '{print ($1 > $2)}'` == 1 ]]; then
                        if [[ "$jobcode" -eq "0" ]]; then
                                        if [ ! -z $jobcode ]; then  # if not empty string from disconnecting
                                                longestrupsubtime=$rupdiffsubtime
                                                longestrupsub=$i
                                        fi
                        fi
                fi
                # save shortest successfull rupture sub time
                
		if [[ "$i" -ne "0"  ]]; then
		    if [[ `echo "$rupdiffsubtime $shortestrupsubtime" | awk '{print ($1 < $2)}'` == 1 ]]; then
                        if [[ "$jobcode" -eq "0" ]]; then
                            if [ ! -z $jobcode ]; then
                                shortestrupsubtime=$rupdiffsubtime
                                shortestrupsub=$i
                            fi
                        fi
                    fi
		else
			shortestrupsubtime=$rupdiffsubtime
		fi


		# Execution times
		if [[ `echo "$rupdifftime $longestruptime" | awk '{print ($1 > $2)}'` == 1 ]]; then           # compare decimal numbers using awk
                        if [[ "$jobcode" -eq "0" ]]; then
                                if [ ! -z $jobcode ]; then  # if not empty string from disconnecting
                                        longestruptime=$rupdifftime
                                        longestrup=$i
                                fi
                        fi
                fi
                # get shortest successfull time
                if [[ "$i" -ne "0"  ]]; then #( if not first loop iteration)

                        # if shorter time than curr
                        if [[ `echo "$rupdifftime $shortestruptime" | awk '{print ($1 < $2)}'` == 1 ]]; then
                                if [[ "$jobcode" -eq "0" ]]; then
                                        if [ ! -z $jobcode ]; then
                                        shortestruptime=$rupdifftime
                                        shortestrup=$i
                                        fi
                                fi
                        fi
                else
                        shortestruptime=$rupdifftime # init shortest time as job1's time
                fi

		
		# accumulate successful times for calculations
                if [[ "$jobcode" -eq "0" ]]; then
                        accumruptime="$( awk -v n="$accumruptime" -v d=$rupdifftime 'BEGIN{printf "%.2f\n", (n+d) }')"
                        successrupatts=$(( $successrupatts + 1 ))
                fi
                # accumulate submission times for averaging     
                averagerupsubtime="$( awk -v n="$averagerupsubtime" -v d=$rupdiffsubtime 'BEGIN{printf "%.2f\n", (n+d) }')"
	
		
		# Print individual job info if verbose flag is true
                if [[ "$vflag" -eq "1" ]]; then
                        if [[ $jobcode -eq "0" ]]; then
                                echo "Rupture-bundle:$i took $rupdiffsubtime minutes from submission to execution." 
                                echo  "Rupture-bundle:$i took $rupdifftime minutesminutes from execution to successfull completion to make ruptures."      
                        else
                                echo "Rupture-bundle:$i failed with exit-code $jobcode and took $rupdifftime minutes."
                        fi
                fi
	

	else # this run is still going
		
		currruprunning=$(( $currruprunning + 1 ))


                #get the job's submitted time and termination time
                subtime=$(grep -m1 submitted fakequakes_makerupts$i.log | awk '{print $4}')
                extime=$(grep -m1 executing fakequakes_makerupts$i.log | awk '{print $4}')

                datesub=$(grep -m1 submitted fakequakes_makerupts$i.log | awk '{print $3}')
                dateex=$(grep -m1 executing fakequakes_makerupts$i.log | awk '{print $3}')

                if [ -z $subtime ]; then        # if no submission time

                        if [[ "$vflag" -eq "1" ]]; then
                                echo "Rupture-bundle:$i is waiting to be submitted." 
                        fi

                        notrupsubbed=$(( $notrupsubbed + 1 ))

                elif [ -z $extime ]; then       # if no execution time

                        curtime=$(date +"%T")
                        curdate=$(date +"%Y-%m-%d")
                        runtime=$(get_time_diff $subtime $curtime $datesub $curdate)

                        if [[ "$vflag" -eq "1" ]]; then
                                echo "Rupture-bundle:$i was submitted $runtime minutes ago and is waiting to be executed"
                        fi

                        notrupsubbed=$(( $notrupsubbed + 1 ))

                else # it submitted and is now executing
                        rupdiffsubtime=$(get_time_diff $subtime $extime $datesub $dateex)


                        curtime=$(date +"%T")
                        curdate=$(date +"%Y-%m-%d")
                        runtime=$(get_time_diff $extime $curtime $dateex $curdate)

                        if [[ "$vflag" -eq "1" ]]; then
                        echo "Rupture-bundle:$i took $rupdiffsubtime minutes from submission to execution"
                        echo "Rupture-bundle:$i  has been running for $runtime minutes since execution."
                        fi

                        averagerupsubtime="$( awk -v n="$averagerupsubtime" -v d=$rupdiffsubtime 'BEGIN{printf "%.2f\n", (n+d) }')"
                fi

		if [[ "$vflag" -eq "1" ]]; then
			echo "Rupture-bundle:$i is still running"
		fi
	fi
    done

else
	# the first rupture job is still running (it might be making distance matrices)
	cd ~/$preparedinput
        totsubtime=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $4}')
        totsubdate=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $3}')
        curtime=$(date +"%T")
        curdate=$(date +"%Y-%m-%d")
        totruntime=$(get_time_diff $totsubtime $curtime $totsubdate $curdate)
        echo "The entire fakequakes/DAGman process has currently been running for $totruntime minutes."
        echo "The first rupture bundle is still being generated (and its distance matrices too if they weren't prepared beforehand and passed in)."
	#echo "Phase A is generating distance matrices right now to be recycled."
	exit 0  
fi



averageruptime=1
if [[ ! "$successrupatt" = "0" ]]; then
        averageruptime="$( awk -v n="$accumruptime" -v d="$successrupatts" 'BEGIN{printf "%.2f\n", (n/d) }')"
fi

subbedrupatts=$(( $nsims - $notrupsubbed ))
averagerupsubtime="$( awk -v n="$averagerupsubtime" -v d="$subbedrupatts" 'BEGIN{printf "%.2f\n", (n/d) }')"


echo "There are $successrupatts successfull, complete rupture jobs out of $nsims simulations. "
echo "There are $failedrupatts failed rupture jobs out of $nsims simulations."
echo "There are $currruprunning rupture jobs still running with $notrupsubbed runs still being submitted or waiting to be."

echo "The longest, complete job which made ruptures is fakequakes_run$longestrup which took $longestruptime minutes."
echo "The shortest, complete job which made ruptures is fakequakes_run$shortestrup which took $shortestruptime minutes."

if [[ ! "$successrupatts" = "0" ]]; then
        echo "When making ruptures,the average successful job time is $averageruptime minutes for $successrupatts runs."
fi
echo "When submitting rupture jobs the longest one was run$longestrupsub which took $longestrupsubtime minutes and the shortest was run$shortestrupsub at $shortestrupsubtime minutes."
echo "When submitting rupture jobs the average submission time $averagerupsubtime minutes."

if [[ "$phaseArunning" -eq "1" || "$phaseBrunning" -eq "1" ]]; then
	cd ~/$preparedinput
	totsubtime=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $4}')
	totsubdate=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $3}')
	curtime=$(date +"%T")
	curdate=$(date +"%Y-%m-%d")
	totruntime=$(get_time_diff $totsubtime $curtime $totsubdate $curdate)
	echo "The entire fakequakes/DAGman process has currently been running for $totruntime minutes."
	exit 0
fi


# -------- Phase A and B should be complete if reached here. Output complete data for them.

# Get job A time stats 
cd ~/$preparedinput/fakequakes_output_run0

# get sub and term times Phase A
subtime=$(grep -m1 submitted fakequakes_makerupts0.log | awk '{print $4}')
extime=$(grep -m1 executing fakequakes_makerupts0.log | awk '{print $4}')
termtime=$(grep -m1 terminated fakequakes_makerupts0.log | awk '{print $4}')


datesub=$(grep -m1 submitted fakequakes_makerupts0.log | awk '{print $3}')
dateex=$(grep -m1 executing fakequakes_makerupts0.log | awk '{print $3}')
dateterm=$(grep -m1 terminated fakequakes_makerupts0.log | awk '{print $3}')

diffsubAtime=$(get_time_diff $subtime $extime $datesub $dateex)
diffAtime=$(get_time_diff $extime $termtime $dateex $dateterm)

# Get job's exit-code
foo=$(grep exit-code fakequakes_makerupts0.log | awk '{print $11}')
phaseAcode="$(printf '%s' "$foo" | cut -c1)"

# if Phase A isn't successful
if [[ "$phaseAcode" -eq "1" ]]; then
	echo "Phase A took $diffsubAtime minutes from submission to execution."
	echo "Phase A failed with exit-code $jobcode and took $diffAtime minutes."
	exit 1
elif [ -z $phaseAcode ]; then

	echo "Phase A failed, disconnected, and took $diffAtime minutes."
	exit 1
fi

# get sub and term times Phase B
subtime=$(grep -m1 submitted fakequakes_run0.log | awk '{print $4}')
extime=$(grep -m1 executing fakequakes_run0.log | awk '{print $4}')
termtime=$(grep -m1 terminated fakequakes_run0.log | awk '{print $4}')

datesub=$(grep -m1 submitted fakequakes_run0.log | awk '{print $3}')
dateex=$(grep -m1 executing fakequakes_run0.log | awk '{print $3}')
dateterm=$(grep -m1 terminated fakequakes_run0.log | awk '{print $3}')

diffsubBtime=$(get_time_diff $subtime $extime $datesub $dateex)
diffBtime=$(get_time_diff $extime $termtime $dateex $dateterm)

# Get job's exit-code
foo=$(grep exit-code fakequakes_run0.log | awk '{print $11}')
phaseBcode="$(printf '%s' "$foo" | cut -c1)"

# if Phase B isn't successful
if [[ "$phaseBcode" -eq "1" ]]; then
	echo "Phase B took $diffsubBtime minutes from submission to execution."
	echo "Phase B failed with exit-code $jobcode and took $diffBtime minutes."
	exit 1
elif [ -z $phaseBcode ]; then
	echo "Phase B failed, disconnected, and took $diffBtime minutes."
	exit 1
fi


# report success/stats of Phase A and B
echo "Phase A took $diffsubAtime minutes from submission to execution."
#cd ~/preparedinput

cd ~/$preparedinput/fakequakes_output_run0/other_output
# if a ruptures.ist was made, it was copied to the other_output folder. By this you can tell if ruptures were made
if [ ! -f ruptures.list ]; then
     echo "Phase A (which makes ruptures) was skipped because the user passed in prepared ruptures."
else
    echo "Phase A (which made ruptures) took $diffAtime minutes to complete successfully."
fi


echo "Phase B took $diffsubBtime minutes from submission to execution."

# if G matrices (.mseed files) were made then a .txt file will be in other_output (and the mseeds are stored in public)
if [ -f GmatricesMade.txt ]; then
	echo "Phase B (which makes GFs/synths and one round of waveforms) took $diffBtime minutes to complete successfully."
else 
	echo "Phase B did not make any GFs/synths but did make one round of waveforms and took $diffBtime minutes to complete successfully."
fi

#cd ~


 
# ------- Loop over Phase C jobs starts here.

# vars for tracking the time between submission and execution
longestsub=0
longestsubtime=$diffsubBtime
shortestsub=0
shortestsubtime=$diffsubBtime
averagesubtime=$diffsubBtime

# initialize vars
longestrun=0
longesttime=0

shortestrun=0
shortesttime=0

accumtime=0
failedatts=0
successatts=0
currrunning=0
notsubbed=0
cd ~/$preparedinput

 
# Job A Done. Go over all jobs attempting to get their times 
# Goes over each run after run0 to get time stats
#wavesind=$(( $numrups * 2))	#  the waveform jobs are labeled only by even numbers
#for (( i=2 ; i<$wavesind ; i+=2 ))

for (( i=2 ; i<$numrups ; i+=2 ))
do
	cd fakequakes_output_run$i

	if [[ -f fakequakes_run$i.error ]] && [[ -f fakequakes_run$i.out ]]; then # if .error  & .out files exist then run is complete 

		
		# get time stats 

		#get the job's submitted time and termination time
		subtime=$(grep -m1 submitted fakequakes_run$i.log | awk '{print $4}')
		extime=$(grep -m1 executing fakequakes_run$i.log | awk '{print $4}')
		termtime=$(grep -m1 terminated fakequakes_run$i.log | awk '{print $4}')
		
		datesub=$(grep -m1 submitted fakequakes_run$i.log | awk '{print $3}')
		dateex=$(grep -m1 executing fakequakes_run$i.log | awk '{print $3}')
		dateterm=$(grep -m1 terminated fakequakes_run$i.log | awk '{print $3}')

		diffsubtime=$(get_time_diff $subtime $extime $datesub $dateex)
        	difftime=$(get_time_diff $extime $termtime $dateex $dateterm)
                
        	# Get the job's exit-code
		foo=$(grep exit-code fakequakes_run$i.log | awk '{print $11}')
		jobcode="$(printf '%s' "$foo" | cut -c1)"	

		# keep track of failed job count
		if [[ "$jobcode" -ne "0"  ]]; then
			failedatts=$(( $failedatts + 1 ))
		fi


		#  longest submission time
	        if [[ `echo "$diffsubtime $longestsubtime" | awk '{print ($1 > $2)}'` == 1 ]]; then
        	        if [[ "$jobcode" -eq "0" ]]; then
					if [ ! -z $jobcode ]; then  # if not empty string from disconnecting
						longestsubtime=$diffsubtime
						longestsub=$i
					fi
                	fi
        	fi	
		# save shortest successfull sub tiem
        	if [[ "$i" -ne "0" ]]; then
		    if [[ `echo "$diffsubtime $shortestsubtime" | awk '{print ($1 < $2)}'` == 1 ]]; then
            	        if [[ "$jobcode" -eq "0" ]]; then
                	    if [ ! -z $jobcode ]; then
                    	    	shortestsubtime=$diffsubtime
                    	    	shortestsub=$i
                	    fi
        	    	fi
        	    fi
		else # save the first iteration as the shortest sub time
			shortestsubtime=$diffsubtime
		fi

		# if this difftime is greater than curr, save longest successfull time
		if [[ `echo "$difftime $longesttime" | awk '{print ($1 > $2)}'` == 1 ]]; then		# compare decimal numbers using awk
			if [[ "$jobcode" -eq "0" ]]; then
				if [ ! -z $jobcode ]; then  # if not empty string from disconnecting
					longesttime=$difftime
					longestrun=$i	
				fi
			fi
		fi
		# get shortest successfull time
		if [[ "$i" -ne "0" ]]; then #( if not first loop iteration)
			
			# if shorter time than curr
			if [[ `echo "$difftime $shortesttime" | awk '{print ($1 < $2)}'` == 1 ]]; then  
				if [[ "$jobcode" -eq "0" ]]; then
					if [ ! -z $jobcode ]; then
					shortesttime=$difftime
					shortestrun=$i
					fi
				fi
			fi
		else
			shortesttime=$difftime # init shortest time as job1's time
		fi


		# accumulate successful times for calculations
		if [[ "$jobcode" -eq "0" ]]; then
			accumtime="$( awk -v n="$accumtime" -v d=$difftime 'BEGIN{printf "%.2f\n", (n+d) }')"	
			successatts=$(( $successatts + 1 ))
		fi
		# accumulate submission times for averaging	
		averagesubtime="$( awk -v n="$averagesubtime" -v d=$diffsubtime 'BEGIN{printf "%.2f\n", (n+d) }')"


		# Print individual job info if verbose flag is true
		if [[ "$vflag" -eq "1" ]]; then
			if [[ $jobcode -eq "0" ]]; then
				echo "fakequakes_run$i took $diffsubtime minutes from submission to execution."	
				echo  "fakequakes_run$i took $difftime minutesminutes from execution to successfull completion to make waveforms."	
			else				
				echo "fakequakes_run$i failed with exit-code $jobcode and took $difftime minutes."
			fi
			
		fi
		cd ..


	else # .out and .error file don't exist, this run one is still running
		
		#echo "fakequakes_run$i is currently running"
		currrunning=$(( $currrunning + 1 ))


		#get the job's submitted time and termination time
		subtime=$(grep -m1 submitted fakequakes_run$i.log | awk '{print $4}')
		extime=$(grep -m1 executing fakequakes_run$i.log | awk '{print $4}')
	
		datesub=$(grep -m1 submitted fakequakes_run$i.log | awk '{print $3}')
                dateex=$(grep -m1 executing fakequakes_run$i.log | awk '{print $3}')	
		
		
		
		if [ -z $subtime ]; then	# if no submission time

			if [[ "$vflag" -eq "1" ]]; then
				echo "fakequakes_run$i is waiting to be submitted." 
			fi

			notsubbed=$(( $notsubbed + 1 ))
		
		elif [ -z $extime ]; then	# if no execution time

			curtime=$(date +"%T")
			curdate=$(date +"%Y-%m-%d")
			runtime=$(get_time_diff $subtime $curtime $datesub $curdate)

			if [[ "$vflag" -eq "1" ]]; then
				echo "fakequakes_run$i was submitted $runtime minutes ago and is waiting to be executed"
			fi

			notsubbed=$(( $notsubbed + 1 ))

		else
			diffsubtime=$(get_time_diff $subtime $extime $datesub $dateex)
			

			curtime=$(date +"%T")
			curdate=$(date +"%Y-%m-%d")
			runtime=$(get_time_diff $extime $curtime $dateex $curdate)

			if [[ "$vflag" -eq "1" ]]; then
			echo "fakequakes_run$i took $diffsubtime minutes from submission to execution"
			echo "fakequakes_run$i  has been running for $runtime minutes since execution."
			fi

			averagesubtime="$( awk -v n="$averagesubtime" -v d=$diffsubtime 'BEGIN{printf "%.2f\n", (n+d) }')"
		fi
                
		cd ..		# go back to home dir for next iteration of the loop
	fi
done

# --------------  Final Output  --------------- #
averagetime=1
if [[ ! "$successatts" = "0" ]]; then
	averagetime="$( awk -v n="$accumtime" -v d="$successatts" 'BEGIN{printf "%.2f\n", (n/d) }')"
fi

subbedatts=$(( $numrups - $notsubbed ))
averagesubtime="$( awk -v n="$averagesubtime" -v d="$subbedatts" 'BEGIN{printf "%.2f\n", (n/d) }')"


successatts=$(( $successatts + 1 )) # add on an attempt for Phase B waveforms
echo "There are $successatts successfull, complete waveform jobs out of $numrups simulations. "
echo "There are $failedatts failed waveform jobs out of $numrups simulations."
echo "There are $currrunning waveform jobs still running with $notsubbed runs still being submitted or waiting to be."


# estimate time left 					(TODO: maybe come up with a better estimation technique)
#subtime=$(grep submitted dag_v2_dagfile.dag.dagman.log | awk '{print $4}')
#curtime=$(date +"%R")
#difftime=$(get_time_diff $subtime $curtime)
#xfac="$( awk -v n="$difftime"  -v d=$successatts 'BEGIN{printf "%.2f\n", (n/d) }')"  # divide the difference by the number of successful runs
#timesti="$( awk -v n="$xfac"  -v d=$currrunning 'BEGIN{printf "%.2f\n", (n*d) }')"
#echo  "With $currrunning simulations left, it will take roughly $timesti minutes to complete."

if [[ ! "$successatts" = "0" ]]; then
	echo "The longest, complete job which made waveforms is fakequakes_run$longestrun which took $longesttime minutes."
	echo "The shortest, complete job which made waveforms is fakequakes_run$shortestrun which took $shortesttime minutes."
fi

if [[ ! "$successatts" = "0" ]]; then
	echo "When making waveforms,the average successful job time is $averagetime minutes for $successatts runs."
fi

if [[ ! "$subbedatts" = "0" ]]; then
	echo "When submitting waveform jobs the longest, complete one is run$longestsub which took $longestsubtime minutes and the shortest is run$shortestsub at $shortestsubtime minutes."
	echo "When submitting waveform jobs the average submission time for complete runs is $averagesubtime minutes."
fi

cd ~/$preparedinput
totsubtime=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $4}')
totsubdate=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $3}')
curtime=$(date +"%T")
curdate=$(date +"%Y-%m-%d")
totruntime=$(get_time_diff $totsubtime $curtime $totsubdate $curdate)
echo "The entire fakequakes/DAGman process has currently been running for $totruntime minutes."


