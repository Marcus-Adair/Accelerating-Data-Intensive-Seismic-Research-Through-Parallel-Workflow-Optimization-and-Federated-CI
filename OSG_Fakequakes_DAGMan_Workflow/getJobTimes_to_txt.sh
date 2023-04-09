#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Date: March 2023   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute 
#
# This file calls the getJobTimes.sh and writes its output to a txt file

prepinput=$1

uniquetime=$(date +"%m-%d-%y_%H:%M")

underscore="_"

uniquename=GetJobTimesOutput_$prepinput$underscore$uniquetime

> $uniquename.txt

theoutput=$(sh getJobTimes.sh $prepinput)
echo "$theoutput" >> $uniquename.txt

mv $uniquename.txt ~/GetJobTimesOutput

echo "The getJobTimes output was writen to ~/GetJobTimesOutput/$uniquename.txt"
