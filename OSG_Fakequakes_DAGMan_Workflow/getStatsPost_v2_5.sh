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

# Get the number of rupture bundles 
#totrupruns=$(ls | wc -l)
#totrupruns=$(($totrupruns-5))
#totrupruns=$(($totrupruns/3))




echo "There are $totrupruns rupture-bundle runs in this dir"
totruptures=$(($totrupruns*16))
echo "So there are $totruptures ruptures generated (16 ruptures per bundle)"

echo "There are $totruns waveform runs in this dir (each works on 2 ruptures)"

echo -e  "Phase A\n---------------------"

# PHASE A --------------------------------- 

# Loop through the Phase A rupturee jobs to get time statistics
# Init vars first

longestrupsub=0
longestrupsubtime=0

shortestrupsub=0
shortestrupsubtime=0
averagerupsubtime=0

longestrup=0
longestruptime=0

shortestrup=0
shortestruptime=0
averageruptime=0

failedrupatts=0


for (( i=0 ; i<$totrupruns ; i+=1 ))
do

	# Get job times from rupture log files

	#get the job submitted's time
	rupsubtime=$(grep -m1 submitted fakequakes_makerupts$i.log | awk '{print $4}')

	# execution time
	rupextime=$(grep -m1 executing fakequakes_makerupts$i.log | awk '{print $4}')

	# gets the time that the jobs terminated
	ruptermtime=$(grep -m1 terminated fakequakes_makerupts$i.log | awk '{print $4}')


	rupdatesub=$(grep -m1 submitted fakequakes_makerupts$i.log | awk '{print $3}')
	rupdateex=$(grep -m1 executing fakequakes_makerupts$i.log | awk '{print $3}')
	rupdateterm=$(grep -m1 terminated fakequakes_makerupts$i.log | awk '{print $3}')
	#echo $rupsubtime
	#echo $rupextime
	#echo $rupdatesub
	#echo $rupdateex

	
	#rupsubdifftime=$(get_time_diff $rupsubtime $rupextime $rupdatesub $rupdateex)
	rupsubdifftime=$(python ~/getTimeDiff.py $rupsubtime $rupextime $rupdatesub $rupdateex)
	#rupdifftime=$(get_time_diff $rupextime $ruptermtime $rupdateex $rupdateterm)
	rupdifftime=$(python ~/getTimeDiff.py $rupextime $ruptermtime $rupdateex $rupdateterm)



	# Get the job's exit-code
	foo=$(grep exit-code fakequakes_makerupts$i.log | awk '{print $11}')
	jobcode="$(printf '%s' "$foo" | cut -c1)"



	# keep track of failed job count
	if [[ "$jobcode" -ne "0"  ]]; then
		failedrupatts=$(( $failedrupatts + 1 ))
	fi

	if [ -z $jobcode ]; then
		failedrupatts=$(( $failedrupatts + 1 ))
	fi


	# Track submission times
	# save longest successfull submission time
        if [[ `echo "$rupsubdifftime $longestrupsubtime" | awk '{print ($1 > $2)}'` == 1 ]]; then
                if [[ "$jobcode" -eq "0" ]]; then
                        if [ ! -z $jobcode ]; then  # if not empty string from disconnecting
                            longestrupsubtime=$rupsubdifftime
                            longestrupsub=$i
                        fi
                fi
        fi

        # get shortest successfull submission time
        if [[ "$i" -ne "0"  ]]; then
                if [[ `echo "$rupsubdifftime $shortestrupsubtime" | awk '{print ($1 < $2)}'` == 1 ]]; then
                        if [[ "$jobcode" -eq "0" ]]; then
                                if [ ! -z $jobcode ]; then
                                    shortestrupsubtime=$rupsubdifftime
                                    shortestrupsub=$i
                                fi
                        fi
                fi
        else
                shortestrupsubtime=$rupsubdifftime # init shortest submission time as job1's time
        fi
	
	#----------------------
	# Track execution times
	# save longest successfull time
        if [[ `echo "$rupdifftime $longestruptime" | awk '{print ($1 > $2)}'` == 1 ]]; then
                if [[ "$jobcode" -eq "0" ]]; then
                        if [ ! -z $jobcode ]; then  # if not empty string from disconnecting
                        longestruptime=$rupdifftime
                        longestrup=$i
                        fi
                fi
        fi

        # get shortest successfull time
        if [[ "$i" -ne "0"  ]]; then

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

	
	# accumulate successful times for averaging
        if [[ "$jobcode" -eq "0" ]]; then
	        averageruptime="$( awk -v n="$averageruptime" -v d=$rupdifftime 'BEGIN{printf "%.2f\n", (n+d) }')"
        fi
	# accumulate submission time
	averagerupsubtime="$( awk -v n="$averagerupsubtime" -v d=$rupsubdifftime 'BEGIN{printf "%.2f\n", (n+d) }')"

 
        
	# Print individual job info if verbose flag is true
        if [[ "$vflag" -eq "1" ]]; then
          if [ -z $jobcode ]; then
		if [ -z "$rupsubdifftime" ]; then
			echo "Rupture-Bundle:$i took $rupsubdifftime to go through submission until execution."
		fi
                echo  "Rupture-Bundle:$i failed and disconnected."
          else
                if [[ $jobcode -eq "0" ]]; then
                        echo "Rupture-Bundle:$i took $rupsubdifftime to go through submission until execution."
			echo  "Rupture-Bundle:$i took $rupdifftime minutes to complete successfully."       
                else
			echo "Rupture-Bundle:$i took $rupsubdifftime to go through submission until execution."
                        echo "Rupture-Bundle:$i failed with exit-code $jobcode and took $rupdifftime minutes."
                fi
          fi
        fi
done



# Calculate average execution and submission time

succrups=$(( $totrupruns - $failedrupatts )) # subtract out the # of failed attempts for averaging
averageruptime="$( awk -v n="$averageruptime" -v d="$succrups" 'BEGIN{printf "%.2f\n", (n/d) }')"
averagerupsubtime="$( awk -v n="$averagerupsubtime" -v d="$totrupruns" 'BEGIN{printf "%.2f\n", (n/d) }')"

# Get total A times from subdag log
cd ~/$dirname/$preparedinput/dagoutput

Asubtime=$(grep -m1 submitted dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $4}')
Aextime=$(grep -m1 executing dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $4}')
Atermtime=$(grep -m1 terminated dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $4}')

datesub=$(grep -m1 submitted dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $3}')
dateex=$(grep -m1 executing dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $3}')
dateterm=$(grep -m1 terminated dag_v2_arup_phase_dagfile.dag.dagman.log | awk '{print $3}')

#Asubdifftime=$(get_time_diff $Asubtime $Aextime $datesub $dateex)
Asubdifftime=$(python ~/getTimeDiff.py $Asubtime $Aextime $datesub $dateex)
#Adifftime=$(get_time_diff $Aextime $Atermtime $dateex $dateterm)
Adifftime=$(python ~/getTimeDiff.py $Aextime $Atermtime $dateex $dateterm)


# Report stats on A Phase
echo "Phase A (make ruptures step) took $Asubdifftime minutes from submission to execution."
echo "All Phase A jobs (ruptures jobs) took $Adifftime minutes from execution to successful completion."
echo "Total failed rupture-runs: $failedrupatts out of $totrupruns"
echo "It took $Adifftime minutes of execution time to make $totruptures ruptures."
echo "The longest job which made ruptures is Rupture bundle:$longestrup which took $longestruptime minutes."
echo "The shortest job which made ruptures is Rupture bundle:$shortestrup which took $shortestruptime minutes."
echo "When making ruptures, the average successful job time was $averageruptime minutes."
echo "When submitting rupture jobs the longest one was run$longestrupsub which took $longestrupsubtime minutes and the shortest was run$shortestrupsub at $shortestrupsubtime minutes."
echo "When submitting rupture jobs the average submission time $averagerupsubtime minutes."

echo -e "------END\n"


# PHASE B ---------------------------------------#
# Give stats
echo -e "Phase B\n---------------------"

cd ~/$dirname/$preparedinput/fakequakes_output_run0

#get the job submitted's time
subtime=$(grep -m1 submitted fakequakes_run0.log | awk '{print $4}')
# Get the time that the job started executing
extime=$(grep -m1 executing fakequakes_run0.log | awk '{print $4}')
# gets the time that the jobs terminated
termtime=$(grep -m1 terminated fakequakes_run0.log | awk '{print $4}')

datesub=$(grep -m1 submitted fakequakes_run0.log | awk '{print $3}')
dateex=$(grep -m1 executing fakequakes_run0.log | awk '{print $3}')
dateterm=$(grep -m1 terminated fakequakes_run0.log | awk '{print $3}')



#diffsubtime=$(get_time_diff $subtime $extime $datesub $dateex)
diffsubtime=$(python ~/getTimeDiff.py $subtime $extime $datesub $dateex)
#diffextime=$(get_time_diff $extime $termtime $dateex $dateterm)
diffextime=$(python ~/getTimeDiff.py $extime $termtime $dateex $dateterm)


# Get job's exit-code
foo=$(grep exit-code fakequakes_run0.log | awk '{print $11}')
job0code="$(printf '%s' "$foo" | cut -c1)"


# if inital job isn't successful
if [[ "$job0code" -eq "1" ]]; then
	echo "The B Phase job took $diffsubtime from submission to start execution" 
	echo "B Phase failed with exit-code $job0code and took $diffextime minutes.."
	#exit 1
elif [ -z $job0code ]; then
        echo "The B Phase job took $diffsubtime from submission to start execution" 
	echo "The B Phase job failed and disconnected."
	#exit 1
fi


echo "The B Phase job took $diffsubtime from submission to start execution" 
echo "B Phase (which created 1 round of waveforms and maybe made G matrices) took $diffextime minutes."

echo -e "------END\n"
cd ..  



# PHASE C ------------------------------ #
echo -e "Phase C\n---------------------\n"

# Loop over all the C phase jobs and collect data

# initialize vars
longestrun=0
longesttime=0

shortestrun=0
shortesttime=$diffextime

averagetime=0
failedatts=0

longestsub=0
longesttime=0

shortestsub=0
shortestsubtime=$diffsubtime

averagesubtime=0


dirnums=$(($totruns * 2))
#dirnums=$(($totruns-2))

# Goes over each run after run0 to get time stats
for (( i=2 ; i<$dirnums ; i+=2 ))
do
	cd fakequakes_output_run$i

	#get the job submitted's time
	subtime=$(grep -m1 submitted fakequakes_run$i.log | awk '{print $4}')

	# execution time
	extime=$(grep -m1 executing fakequakes_run$i.log | awk '{print $4}')	

	# gets the time that the jobs terminated
	termtime=$(grep -m1 terminated fakequakes_run$i.log | awk '{print $4}')

	datesub=$(grep -m1 submitted fakequakes_run$i.log | awk '{print $3}')
	dateex=$(grep -m1 executing fakequakes_run$i.log | awk '{print $3}')
	dateterm=$(grep -m1 terminated fakequakes_run$i.log | awk '{print $3}')


	#diffsubtime=$(get_time_diff $subtime $extime $datesub $dateex)
	diffsubtime=$(python ~/getTimeDiff.py $subtime $extime $datesub $dateex)
	#difftime=$(get_time_diff $extime $termtime $dateex $dateterm)
	difftime=$(python ~/getTimeDiff.py $extime $termtime $dateex $dateterm)
	
	# Get the job's exit-code
	foo=$(grep exit-code fakequakes_run$i.log | awk '{print $11}')
	jobcode="$(printf '%s' "$foo" | cut -c1)"	
	

	# keep track of failed job count
	if [[ "$jobcode" -ne "0"  ]]; then
		failedatts=$(( $failedatts + 1 ))
	fi
	if [ -z $jobcode ]; then
		failedatts=$(( $failedatts + 1 ))
	fi


	# save longest submission successfull time
        if [[ `echo "$diffsubtime $longestsubtime" | awk '{print ($1 > $2)}'` == 1 ]]; then
                if [[ "$jobcode" -eq "0" ]]; then
                        if [ ! -z $jobcode ]; then  # if not empty string from disconnecting
                        longestsubtime=$diffsubtime
                        longestsub=$i
                        fi
                fi
        fi

        # get shortest successfull submission time
        #if [[ "$i" -ne "0"  ]]; then

                if [[ `echo "$diffsubtime $shortestsubtime" | awk '{print ($1 < $2)}'` == 1 ]]; then
                        if [[ "$jobcode" -eq "0" ]]; then
                                if [ ! -z $jobcode ]; then
                                shortestsubtime=$diffsubtime
                                shortestsub=$i
                                fi
                        fi
                fi
        #else
        #        shortestsubtime=$diffsubtime # init shortest time as job1's time
        #fi
	

	# save longest successfull time
	if [[ `echo "$difftime $longesttime" | awk '{print ($1 > $2)}'` == 1 ]]; then
		if [[ "$jobcode" -eq "0" ]]; then
			if [ ! -z $jobcode ]; then  # if not empty string from disconnecting
			longesttime=$difftime
			longestrun=$i	
			fi
		fi
	fi

	# get shortest successfull time
	#if [[ "$i" -ne "0"  ]]; then
		
		if [[ `echo "$difftime $shortesttime" | awk '{print ($1 < $2)}'` == 1 ]]; then  
			if [[ "$jobcode" -eq "0" ]]; then
				if [ ! -z $jobcode ]; then
				shortesttime=$difftime
				shortestrun=$i
				fi
			fi
		fi
	#else
	#	shortesttime=$difftime # init shortest time as job1's time
	#fi

	# accumulate successful times for averaging
	if [[ "$jobcode" -eq "0" ]]; then
	averagetime="$( awk -v n="$averagetime" -v d=$difftime 'BEGIN{printf "%.2f\n", (n+d) }')"	
	fi
	averagesubtime="$( awk -v n="$averagesubtime" -v d=$diffsubtime 'BEGIN{printf "%.2f\n", (n+d) }')"


	 
	# Print individual job info if verbose flag is true
	if [[ "$vflag" -eq "1" ]]; then
	  if [ -z $jobcode ]; then
		echo  "fakequakes_run$i failed and disconnected."
	  else
	
		if [[ $jobcode -eq "0" ]]; then
			
			echo "fakequakes_run$i took $diffsubtime minutes from submission to execution."
			echo "fakequakes_run$i took $difftime  minutes from execution to successfull completion to make waveforms for 2 ruptures."	
		else
			echo "fakequakes_run$i took $diffsubtime minutes from submission to execution."
			echo "fakequakes_run$i failed with exit-code $jobcode and took $difftime minutes."
		fi
	  fi
	fi
	cd ..

done  # end of for loop



totrunminone=$(( $totruns - 1 ))
totrunminone=$(( $totrunminone - $failedatts )) # subtract out the # of failed attempts for averaging
averagetime="$( awk -v n="$averagetime" -v d="$totrunminone" 'BEGIN{printf "%.2f\n", (n/d) }')"

averagesubtime="$( awk -v n="$averagesubtime" -v d="$totruns" 'BEGIN{printf "%.2f\n", (n/d) }')"

echo "Total failed waveform runs: $failedatts out of $totruns"

# Get the total runtime of the DAG
cd ~/$dirname/$preparedinput/dagoutput
Csubtime=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $4}')
Ctermtime=$(grep -m1 terminated dag_v2_4_dagfile.dag.dagman.log | awk '{print $4}')

Cdatesub=$(grep -m1 submitted dag_v2_4_dagfile.dag.dagman.log | awk '{print $3}')
Cdateterm=$(grep -m1 terminated dag_v2_4_dagfile.dag.dagman.log | awk '{print $3}')

#Cdifftime=$(get_time_diff $Csubtime $Ctermtime $Cdatesub $Cdateterm)
Cdifftime=$(python ~/getTimeDiff.py $Csubtime $Ctermtime $Cdatesub $Cdateterm)



# Print out time stats
#echo "The initial job (which calculated all matrices) took $job0time minutes."
echo "The longest job (which made waveforms) is fakequakes_run$longestrun which took $longesttime minutes."
echo "The shortest job (which made waveforms) is fakequakes_run$shortestrun which took $shortesttime minutes."
echo "When making waveforms, the average successful job time is $averagetime minutes."
echo "When submitting waveform jobs the longest one was run$longestsub which took $longestsubtime minutes and the shortest was run$shortestsub at $shortestsubtime minutes."
echo "When submitting waveform jobs the average submission time $averagesubtime minutes."
echo "The entire fakequakes/DAGman process took $Cdifftime minutes to run and complete."


