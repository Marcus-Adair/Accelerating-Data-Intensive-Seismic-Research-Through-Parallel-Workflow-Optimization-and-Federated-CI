#!/bin/bash
#
# Author: Marcus Adair (RA for Ivan Rodero)
# Date: October 2022   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute 
#
# This file comes up with a unique name to send to and launch the wrapper with (which launches FakeQuakes)
# This is so all layers of the FakeQuakes scripts have access to that unique name
# This does so using nohup so that things can be ran in a background without being terminated
# if something happens. It also outputs the FakeQuake output to a text file
#----------------------------------------------------------------------------


# If a projects and prepinput dir don't exist on this machine, make them

DIRECTORY=prepinput
if [[ ! -d "$DIRECTORY" ]]
then
    #DIRECTORY doesn't exist, make it on this machine
    mkdir $DIRECTORY
fi

DIRECTORY=projects
if [[ ! -d "$DIRECTORY" ]]
then
    #DIRECTORY doesn't exist, make it on this machine
    mkdir $DIRECTORY
fi

DIRECTORY=fakequakesoutput
if [[ ! -d "$DIRECTORY" ]]
then
    #DIRECTORY doesn't exist, make it on this machine
    mkdir $DIRECTORY
fi


uniquetime=$(date +"%m-%d-%y_%H-%M-%S")

#  The  name of the project and of the folder where input will be stored
uniquedir=fakequakes_run$uniquetime
# THe name of the text file with the console output from the run
uniquename=${uniquedir}_output

echo "Starting on $uniquedir"

> $uniquename.txt

# Launch the FakeQuakes through the wrapper. Write its output to a unique file
nohup bash autofakequakes_v3_wrap.sh $uniquedir > $uniquename.txt

# Move the console input from FakeQuakes run to be stored
mv $uniquename.txt ~/fakequakesoutput/$uniquedir

# Move a file made during autofakequakes_v3.sh that contains time and status
# to be stored
mv ${uniquedir}_status.txt ~/fakequakesoutput/$uniquedir
