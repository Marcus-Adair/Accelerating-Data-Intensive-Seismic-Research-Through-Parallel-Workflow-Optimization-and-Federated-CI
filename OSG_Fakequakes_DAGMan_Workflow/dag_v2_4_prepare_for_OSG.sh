#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Date: September 2022   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute
#
# This file prepares/edits all the other files that are needed to launch FakeQuakes over the OSG 
# according to the parameters as chosen by the user over VDC


# Get the variables passed in as set by the user
uniquename=$1
numrupbundles=$2

modfile=$3
faultfile=$4
xyzfile=$5
mshoutfile=$6
gflistfile=$7

utmzone=$8
timeepi=$9
targetmw=${10}
maxslip=${11}
hypocenter=${12}


#uniquename=temp_test_v3
#numrupbundles=5

#modfile=test_v1.mod
#faultfile=test_v1.fault
#xyzfile=test_v1.xyz
#mshoutfile=test_v1.mshout
#gflistfile=test_v1.gflist

#utmzone=test_v1_utm
#timeepi=test_v1_time-epi
#targetmw=test_v1_targetMW
#maxslip=test_v1_maxslip
#hypocenter=test_v1_hypo



# Create the folder in $prepinput for files to be submitted from
cd ~/prepinput
mkdir $uniquename
cd ~

# Make a unique folder in home for this DAGMan to be launched from
mkdir $uniquename

# temp folder for preparing files
tempprepare="tempprepare${uniquename}"
mkdir $tempprepare


# Any input files will have been scp'ed to the OSG home dir in a tarball named "${uniquename}input".tar.gz
inputtarball="${uniquename}_input"
tar -xzf $inputtarball.tar.gz
rm $inputtarball.tar.gz
cd $inputtarball

# If user premade distance matrices to recylcle over OSG, prepare them
if [ -f distancematrices.tar.gz ]; then
	mv distancematrices.tar.gz ~/prepinput/$uniquename
fi

# If user premade ruptures to use over OSG, prepare them
if [ -f ruptures.list ] && [ -f ruptures.tar.gz ]; then
	mv ruptures.list ~/prepinput/$uniquename
	mv ruptures.tar.gz ~/prepinput/$uniquename
	cd ~/prepinput/$uniquename
	tar -xzf ruptures.tar.gz
	rm ruptures.tar.gz
	cd ~/$inputtarball
fi


# Compress the necessary input files into inputfiles.tar.gz and move them into the $prepinput folder to be submitted

mv $modfile ~/$tempprepare
mv $faultfile ~/$tempprepare
mv $xyzfile ~/$tempprepare
mv $mshoutfile ~/$tempprepare
mv $gflistfile ~/$tempprepare
cd ~/$tempprepare
mkdir inputfiles
mv $modfile inputfiles
mv $faultfile inputfiles
mv $xyzfile inputfiles
mv $mshoutfile inputfiles
mv $gflistfile inputfiles
tar -czf inputfiles.tar.gz inputfiles
mv inputfiles.tar.gz ~/prepinput/$uniquename
cd ~
rm -r $tempprepare

rmdir $inputtarball



# Copy all the dag_v2_4 files to the unique folder for this DAGMan run so it can/will be ran from there (and not clash w/ other runs)
cd ~
cp dag_v2_4* $uniquename

# Go into the unique folder to run things from there
cd $uniquename


# Edit the dagfile to have the $prepinput name and the # of rupture bundles to launch

dagfile=dag_v2_4_dagfile.dag
sed -i "s/^SCRIPT PRE A dag_v2_4_A_prescript.sh.*/SCRIPT PRE A dag_v2_4_A_prescript.sh ${uniquename} ${numrupbundles}/" ~/$uniquename/$dagfile
sed -i "s/^SCRIPT POST A dag_v2_4_A_postscript.sh.*/SCRIPT POST A dag_v2_4_A_postscript.sh ${uniquename}/" ~/$uniquename/$dagfile
sed -i "s/^SCRIPT PRE B dag_v2_4_B_prescript.sh.*/SCRIPT PRE B dag_v2_4_B_prescript.sh ${uniquename}/" ~/$uniquename/$dagfile
sed -i "s/^SCRIPT POST B dag_v2_4_B_postscript.sh.*/SCRIPT POST B dag_v2_4_B_postscript.sh ${uniquename}/" ~/$uniquename/$dagfile
sed -i "s/^SCRIPT POST C dag_v2_4_C_postscript.sh.*/SCRIPT POST C dag_v2_4_C_postscript.sh ${uniquename}/" ~/$uniquename/$dagfile


# Edit the OSG wrapper to have the correct parameters set as chosen by the user

osgwrapper=dag_v2_4_mudpy_OSG_config_wrap.sh
sed -i "s/^model_name=.*/model_name=${modfile}/" ~/$uniquename/$osgwrapper
sed -i "s/^fault_name=.*/fault_name=${faultfile}/" ~/$uniquename/$osgwrapper
sed -i "s/^slab_name=.*/slab_name=${xyzfile}/" ~/$uniquename/$osgwrapper
sed -i "s/^mesh_name=.*/mesh_name=${mshoutfile}/" ~/$uniquename/$osgwrapper
sed -i "s/^gf_list=.*/gf_list=${gflistfile}/" ~/$uniquename/$osgwrapper
sed -i "s/^utm_zone=.*/utm_zone=${utmzone}/" ~/$uniquename/$osgwrapper
sed -i "s/^time_epi=.*/time_epi=${timeepi}/" ~/$uniquename/$osgwrapper
sed -i "s/^target_mw=.*/target_mw=${targetmw}/" ~/$uniquename/$osgwrapper
sed -i "s/^max_slip=.*/max_slip=${maxslip}/" ~/$uniquename/$osgwrapper
sed -i "s/^hypocenter=.*/hypocenter=${hypocenter}/" ~/$uniquename/$osgwrapper

# Submit the dagfile

condor_submit_dag $dagfile
