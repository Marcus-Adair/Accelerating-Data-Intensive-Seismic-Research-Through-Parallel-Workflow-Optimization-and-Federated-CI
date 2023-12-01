#!/bin/bash
#
# Pre Script which occurs before the B Phase of the DAGman starts
#
# This occurs once

prepinput=$1
FDW_PATH=$2

# If mseeds exist in public dir then choose the submit file that won't make them
# 2  options for B submit files, either one that sends in premade .mseed matrices or one that doeesn't

submitfile=dag_v2_4_submitB_b.submit
cd ~/../../../../../ospool/ap21/data/marcus_adair/old-public/prepinput/$prepinput
if [ ! -f "mseeds.tar.gz" ]; then
	submitfile=dag_v2_4_submitB.submit
fi
#cd ~
#cd $FDW_PATH

# Get the first two ruptures
cd $FDW_PATH/prepinput/$prepinput

firstrup=temp
secrup=temp

i=0
FILENAME="ruptures.list"
FILE=$(cat $FILENAME)
for LINE in $FILE
do
	# if i == 2 break out of loop
	if [ $i -eq 2 ]; then
		break
	fi
	
	rupttoadd=${LINE%.rupt}
	
	if [ $i -eq 0 ]; then
		firstrup=$rupttoadd
	elif [ $i -eq 1 ]; then
		secrup=$rupttoadd
	fi
	
	
	i=$(( i + 1 ))	# increment i
done


# Create the DAGfile for B
> dag_v2_bphase_dagfile.dag

echo "JOB B1 $submitfile" >> dag_v2_bphase_dagfile.dag
echo "VARS B1 runnumber=\"0\"" >> dag_v2_bphase_dagfile.dag
echo "VARS B1 preparedinput=\"$prepinput\"" >> dag_v2_bphase_dagfile.dag
echo "VARS B1 ruptname=\"$firstrup\"" >> dag_v2_bphase_dagfile.dag
echo "VARS B1 ruptname2=\"$secrup\"" >> dag_v2_bphase_dagfile.dag

mv dag_v2_bphase_dagfile.dag $FDW_PATH
