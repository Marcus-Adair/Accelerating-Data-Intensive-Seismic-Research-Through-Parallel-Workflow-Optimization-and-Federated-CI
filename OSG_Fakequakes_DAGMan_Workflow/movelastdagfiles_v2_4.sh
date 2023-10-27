#!/bin/bash
#
# Moves last DAGMan files to the output dir after a FakeQuakes run is done (in its unique folder)

# The unique folder that the DAGman was ran in


#dirname=$1
outputdir=$1


#cd $dirname

# get the name of the folder that the output is in
#outputdir=$( ls | grep -m1 "^fakequakes_output" )

#echo "Moving dagfiles to $dirname/$outputdir"
echo "Moving dagfiles to $outputdir/output"

mv dag_v2_4_dagfile.dag $outputdir/dagoutput
mv dag_v2_4_dagfile.dag.dagman.log $outputdir/dagoutput  	 
mv dag_v2_4_dagfile.dag.dagman.out $outputdir/dagoutput
#mv dag_v2_4_dagfile.dag.lock $outputdir/dagoutput
mv dag_v2_4_dagfile.dag.nodes.log $outputdir/dagoutput
mv dag_v2_4_dagfile.dag.metrics $outputdir/dagoutput
#mv dag_v2_4_dagfile.dag.rescue001 $outputdir/dagoutput
