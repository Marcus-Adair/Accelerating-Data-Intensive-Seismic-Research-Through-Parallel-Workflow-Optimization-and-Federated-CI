#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Date: October 2022   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute 
#
# This file call autofakequakes_v1.sh to run FakeQuakes and writes it console output to a .txt file
# ------------------------------------------------------------------------------------------------#


#  The  name of the project and of the folder where input will be stored
uniquedir=$1

# Make file for tracking time-stamps, status, etc.
> ${uniquedir}_status.txt

pendtime=$(date +"%T")
penddate=$(date +"%Y-%m-%d")
some_output=$(echo "PENDING:")
echo "$some_output" >> ${uniquedir}_status.txt
some_output=$(echo "This Fakequakes run started pending/preparing at the time $pendtime during the day $penddate.")
echo "$some_output" >> ${uniquedir}_status.txt
some_output=$(echo -e "--------------------------------\n")
echo "$some_output" >> ${uniquedir}_status.txt


# Make a dir in prepinput named $uniquedir for holding input files
cd ~/prepinput
mkdir $uniquedir

# Make a dir in fakequakesoutput named $uniquedir for holding fakequakes output 
cd ~/fakequakesoutput
mkdir $uniquedir


# Copy the retrieve dataset pyton to the unique prepinput folder for getting input from OSG
cd ~
cp get_dataset_fromOSG.py ~/prepinput/$uniquedir
cd prepinput/$uniquedir

# Set the dataset for retrieving input from OSG
dataset=full_chile_recycle

# Get the specified dataset of input files
python get_dataset_fromOSG.py $dataset

# unpack the input files, move them to the unique dir, and clean things up
tar -xzf inputfiles.tar.gz
rm inputfiles.tar.gz
cd inputfiles
mv * ..
cd ..
rmdir inputfiles

# Get/set the name of the retrieved input files from the dataset
faultfile=$(find ./ -name *.fault)
faultfile=$(echo ${faultfile#.*/})

modfile=$(find ./ -name *.mod)
modfile=$(echo ${modfile#.*/})

mshoutfile=$(find ./ -name *.mshout)
mshoutfile=$(echo ${mshoutfile#.*/})

xyzfile=$(find ./ -name *.xyz)
xyzfile=$(echo ${xyzfile#.*/})

gflistfile=$(find ./ -name *.gflist)
gflistfile=$(echo ${gflistfile#.*/})


# Set to determine the number of ruptures to generate  (Number of ruptures = Nrealizations * length of Target_MW (which is set at 4 for our purposes))
# So the total ruptures (& waveforms for them) will be 4x the what Nrealizations is set to here (at a minimum there will be 16 ruptures made & waveforms)
# IMPORTANT NOTE:  let Nrealizations % ncpus=0 --> So Nrealizations must be a multiple of 4 and 4 is the minimum (ncpus is either 4 or 1 when running)
Nrealizations=4

# Set the important parameters as chosen by the user
utmzone=19J
timeepi=2016-09-07T14:42:26
targetmw=8.5,9.2,0.2
maxslip=100
hypocenter=0.8301,0.01,27.67


# Run the FakeQuakes in a Singularity container
cd ~
singularity exec madair_mudpy_mudsing_image_complete_v1.sif ~/autofakequakes_v3.sh $uniquedir $Nrealizations $gflistfile $faultfile $modfile $xyzfile $mshoutfile $utmzone $timeepi $targetmw $maxslip $hypocenter


# Copy all of the output files to ~/fakequakesoutput/$uniquedir
cd ~/projects
cp -r $uniquedir ~/fakequakesoutput/$uniquedir/
