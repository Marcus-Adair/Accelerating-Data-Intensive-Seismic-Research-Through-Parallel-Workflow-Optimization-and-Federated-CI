#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute 
#
# This file calls the getStatsPost_v2_5.sh and writes its output to a txt file

prepinput=$1

uniquetime=$(date +"%m-%d-%y_%H:%M")

uniquename=TimeStatsPostOutput$prepinput$uniquetime

> $uniquename.txt

theoutput=$(sh getStatsPost_v2_5.sh -v $prepinput)
echo "$theoutput" >> $uniquename.txt
mv $uniquename.txt ~/verbosePostStats
echo "The output was writen to ~/verbosePostStats/$uniquename.txt"
