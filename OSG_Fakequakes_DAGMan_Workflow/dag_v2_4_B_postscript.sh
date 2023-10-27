#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Date: August 2022   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute 
#
#  Post script to occur  after  the B phase is complete
#  This creates the DAGfile for the C phase of the dagman (waveform step) and handles output from B


# Get name of input folder
prepin=$1
FDW_PATH=$2

# Make dagfile for C phase
# go throught ruptures.list and for every 2 ruptures (except the first two cuz already done) add the rupture names in as vars to the AN job

cd $FDW_PATH/prepinput/$prepin


> dag_v2_subex_dagfile.dag
i=0
filename="ruptures.list"
thefile=$(cat $filename)
for aLINE in $thefile
do
	# If i == 0 or 1 skip cuz first two rups done already
	if [ "$i" -eq 0 ]; then
		i=$(( $i + 1))
		continue
	elif [ "$i" -eq 1 ]; then
		i=$(( $i + 1))
		continue
	fi

	# get the ruptname by takeing off .rupt from the end 
	rupttoadd=${aLINE%.rupt}


	if [[ $((i % 2)) -eq 0 ]];  then
	# i is even

	# add first half of $i job
	
		echo "JOB C$i dag_v2_4_submitC.submit" >> dag_v2_subex_dagfile.dag
		echo "VARS C$i runnumber=\"$i\"" >> dag_v2_subex_dagfile.dag
		echo "VARS C$i preparedinput=\"$prepin\"" >> dag_v2_subex_dagfile.dag
		echo "VARS C$i ruptname=\"$rupttoadd\"" >> dag_v2_subex_dagfile.dag
		#echo "RETRY C$i 3" >> dag_v2_subex_dagfile.dag
	else # its odd
	
	imin1=$(( $i - 1))

	# add econd half of $i job
		echo "VARS C$imin1 ruptname2=\"$rupttoadd\"" >> dag_v2_subex_dagfile.dag	
		echo "SCRIPT PRE C$imin1 dag_v2_4_mkdir_prescript.sh $imin1" >> dag_v2_subex_dagfile.dag
		echo "SCRIPT POST C$imin1 dag_v2_4_Cn_postscript.sh $imin1" >> dag_v2_subex_dagfile.dag
		#echo "RETRY C$imin1 3" >> dag_v2_subex_dagfile.dag
	fi
	

	i=$(( $i + 1))
done

# Move the sub-dagfile to be used in this DAGMan run
mv dag_v2_subex_dagfile.dag $FDW_PATH


# handle the first waveforms made
cd $FDW_PATH
mv preparedoutput0.tar.gz fakequakes_output_run0
cd fakequakes_output_run0

tar -xzf preparedoutput0.tar.gz
rm preparedoutput0.tar.gz	# this unpacks the waveforms into a dir called waveforms



# A .txt file will be in the directory this DAG was submitted from if G matrices were made made (because the actual ones are too large to reside in home)
cd $FDW_PATH
gfile=GmatricesMade.txt
if [ -f "GmatricesMade.txt" ]; then
	mv $gfile $FDW_PATH/fakequakes_output_run0/other_output
fi
# If .mseed G matrices were made during phase B, there were transferred out via the stash directly to public


