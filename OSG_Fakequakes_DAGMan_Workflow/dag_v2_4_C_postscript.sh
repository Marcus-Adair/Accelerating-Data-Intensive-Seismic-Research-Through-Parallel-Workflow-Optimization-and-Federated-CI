#!/bin/bash
#
#	POST SCript to occur after all C jobs are done
#
#	Cleans up files

prepin=$1

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
mv dag_v2_4_dagfile.dag.condor.sub ~/$prepin/$dirname/dagoutput  
#mv dag_v2_4_dagfile.dag.dagman.log ~/$prepin/$dirname/dagoutput
#mv dag_v2_4_dagfile.dag.dagman.out ~/$prepin/$dirname/dagoutput
mv dag_v2_4_dagfile.dag.lib.err ~/$prepin/$dirname/dagoutput 
mv dag_v2_4_dagfile.dag.lib.out ~/$prepin/$dirname/dagoutput
#mv dag_v2_4_dagfile.dag.metrics ~/$prepin/$dirname/dagoutput
#mv dag_v2_4_dagfile.dag.nodes.log ~/$$prepin/dirname/dagoutput

cp dag_v2_4_dagfile.dag ~/$prepin/$dirname/dagoutput

	# move A subdagfiles
mv dag_v2_arup_phase_dagfile.dag.condor.sub ~/$prepin/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.dagman.log ~/$prepin/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.dagman.out ~/$prepin/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.lib.err ~/$prepin/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.lib.out ~/$prepin/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.metrics ~/$prepin/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag.nodes.log ~/$prepin/$dirname/dagoutput
mv dag_v2_arup_phase_dagfile.dag ~/$prepin/$dirname/dagoutput

	# move B subdagfiles
mv dag_v2_bphase_dagfile.dag.condor.sub ~/$prepin/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.dagman.log ~/$prepin/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.dagman.out ~/$prepin/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.lib.err ~/$prepin/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.lib.out ~/$prepin/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.metrics ~/$prepin/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag.nodes.log ~/$prepin/$dirname/dagoutput
mv dag_v2_bphase_dagfile.dag ~/$prepin/$dirname/dagoutput

	# move C subdagfiles
mv dag_v2_subex_dagfile.dag.condor.sub ~/$prepin/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.dagman.log ~/$prepin/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.dagman.out ~/$prepin/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.lib.err ~/$prepin/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.lib.out ~/$prepin/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.metrics ~/$prepin/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag.nodes.log ~/$prepin/$dirname/dagoutput
mv dag_v2_subex_dagfile.dag ~/$prepin/$dirname/dagoutput



# Move the ruptures made this run from /prepinput to other_output if they were made
cd ~/$prepin/$dirname/fakequakes_output_run0/other_output
nooutfile=noout.txt
if [ ! -f "$nooutfile" ]; then
    cd ~/prepinput/$prepin
    mv ruptures ~/$prepin/$dirname/fakequakes_output_run0/other_output
fi
