#!/bin/bash
#
# Prescript to run before All A jobs happen

# Make a dir for outputting files for Phase A
sh dag_v2_4_mkdir_prescript.sh 0
cd fakequakes_output_run0
mkdir other_output
cd ..

# Tget/set input vars
prepinput=$1

nrupbundles=$2

cd ~/prepinput/$prepinput


ruptsprovided=1

# Make dummy ruptures.list for the A jobs to know if it should make ruptures or not
if [ ! -f "ruptures.list" ]; then
	> ruptures.list
	echo "No ruptures were provided." >> ruptures.list
	ruptsprovided=0
	
	cd ~/runningtemp
        mkdir $prepinput
	cd ~/prepinput/$prepinput	
fi

distsprovided=1
# make a dummy package that's empty so A Phase knows to make distance matrices or not
if [ ! -f "distancematrices.tar.gz" ]; then
	mkdir distancematrices
	tar -czf distancematrices.tar.gz distancematrices
	rmdir distancematrices
	distsprovided=0
fi

# check public for the existence of the prepinput dir, make it if it needs to be done for stashing  large mseeds
cd ~/../../../../../ospool/ap21/data/marcus_adair/prepinput
if [ ! -d "$prepinput" ]; then
	mkdir $prepinput
fi

# go back to the unique folder for launching this DAGMan run
cd ~/$prepinput


# Decide which submit file to use

submitfile=dag_v2_4_submitA.submit	# if making ruptures and distance matrices for the fault geometry
	
if [ "$distsprovided" -eq "1" ]; then		# if making just the ruptures and the matrices are provided
	submitfile=dag_v2_4_submitA_2.submit
	
	if [ "$ruptsprovided" -eq "1" ]; then
		submitfile=dag_v2_4_submitA_3.submit	# if user passed provided ruptures and distance matrices already
	fi

fi


# Make the A subDAG  file for A Job

> dag_v2_arup_phase_dagfile.dag

for ((i=0 ; i<$nrupbundles; i+=1 ))
do
    if [ "$i" -eq "0" ]; then
	echo "JOB A$i $submitfile" >> dag_v2_arup_phase_dagfile.dag
	echo "VARS A$i runnumber=\"$i\"" >> dag_v2_arup_phase_dagfile.dag
	echo "VARS A$i preparedinput=\"$prepinput\"" >> dag_v2_arup_phase_dagfile.dag
	echo "VARS A$i ruptrunnumber=\"$i\"" >> dag_v2_arup_phase_dagfile.dag
	echo "SCRIPT POST A$i dag_v2_4_An_postscript.sh $prepinput $i" >> dag_v2_arup_phase_dagfile.dag
	#echo "RETRY A$i 3" >> dag_v2_arup_phase_dagfile.dag
    else 
	echo "JOB A$i dag_v2_4_submitA_2.submit" >> dag_v2_arup_phase_dagfile.dag
        echo "VARS A$i runnumber=\"0\"" >> dag_v2_arup_phase_dagfile.dag
        echo "VARS A$i preparedinput=\"$prepinput\"" >> dag_v2_arup_phase_dagfile.dag
        echo "VARS A$i ruptrunnumber=\"$i\"" >> dag_v2_arup_phase_dagfile.dag
        echo "SCRIPT POST A$i dag_v2_4_An_postscript.sh $prepinput $i" >> dag_v2_arup_phase_dagfile.dag 
 	echo "PARENT A0 CHILD A$i" >> dag_v2_arup_phase_dagfile.dag
	#echo "RETRY A$i 3" >> dag_v2_arup_phase_dagfile.dag
    fi 
done

