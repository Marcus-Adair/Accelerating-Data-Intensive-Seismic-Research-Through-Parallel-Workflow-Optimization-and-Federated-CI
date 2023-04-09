#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Date: September 2022   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute 
#
# This file calls the getStatsDuring_v2_4.sh and writes its output to a txt file

prepinput=$1

uniquetime=$(date +"%m-%d-%y_%H:%M")

uniquename=TimeStatsDuringOutput$prepinput$uniquetime

> $uniquename.txt

theoutput=$(sh getStatsDuring_v2_4.sh $prepinput)
echo "$theoutput" >> $uniquename.txt

echo "The output was writen to $uniquename.txt"
