#!/bin/bash
#
#	POST SCript to occur after all C jobs are done
#
#	Cleans up files

prepin=$1
FDW_PATH=$2

# mkdir by with a unique name with the date and time

#uniquetime=$(date +"%m-%d-%y_%H-%M")
#dirname=fakequakes_output$uniquetime

dirname=fakequakes_output$prepin

mkdir $dirname

cd $dirname
mkdir dagoutput
cd ..

# move all the waveforms and other output a unique folder
mv fakequakes_output_run* $dirname

# Move all the dagfiles and output to the dirs

	# move OG dagfile
mv dag_v2_4_dagfile.dag.condor.sub $FDW_PATH/$dirname/dagoutput  
#mv dag_v2_4_dagfile.dag.dagman.log ~/$prepin/$dirname/dagoutput
#mv dag_v2_4_dagfile.dag.dagman.out ~/$prepin/$dirname/dagoutput
mv dag_v2_4_dagfile.dag.lib.err $FDW_PATH$dirname/dagoutput 
mv dag_v2_4_dagfile.dag.lib.out $FDW_PATH/$dirname/dagoutput
#mv dag_v2_4_dagfile.dag.metrics ~/$prepin/$dirname/dagoutput
#mv dag_v2_4_dagfile.dag.nodes.log ~/$$prepin/dirname/dagoutput

cp dag_v2_4_dagfile.dag $FDW_PATH/$dirname/dagoutput

	# move A subdagfiles
mv dag_v2_arup_phase_dagfile.dag.condor.sub $FDW_PATH/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.dagman.log $FDW_PATH/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.dagman.out $FDW_PATH/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.lib.err $FDW_PATH/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.lib.out $FDW_PATH/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.metrics $FDW_PATH/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.nodes.log $FDW_PATH/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag $FDW_PATH/$dirname/dagoutput

	# move B subdagfiles
mv dag_v2_bphase_dagfile.dag.condor.sub $FDW_PATH/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.dagman.log $FDW_PATH/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.dagman.out $FDW_PATH/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.lib.err $FDW_PATH/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.lib.out $FDW_PATH/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.metrics $FDW_PATH/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.nodes.log $FDW_PATH/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag $FDW_PATH/$dirname/dagoutput

	# move C subdagfiles
mv dag_v2_subex_dagfile.dag.condor.sub $FDW_PATH/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.dagman.log $FDW_PATH/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.dagman.out $FDW_PATH/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.lib.err $FDW_PATH/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.lib.out $FDW_PATH/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.metrics $FDW_PATH/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.nodes.log $FDW_PATH/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag $FDW_PATH/$dirname/dagoutput



# Move the ruptures made this run from /prepinput to other_output if they were made
cd $FDW_PATH/$dirname/fakequakes_output_run0/other_output
nooutfile=noout.txt
if [ ! -f "$nooutfile" ]; then
    cd $FDW_PATH/prepinput/$prepin
    mv ruptures $FDW_PATH/$dirname/fakequakes_output_run0/other_output
fi
