This folder contains the source code for the FakeQuakes DAGMan Workflow (FDW).

Put these file in the home directory of your OSG login node (you must have an OSG account to run).

to run simulations, edit the file 'OSG_Fakequakes_DAGMan_Workflow/dag_v2_4_mudpy_OSG_config_wrap.sh' to change FakeQuakes simulation parameters. Next, edit the dagfile 'dag_v2_4_dagfile.dag'. Make it so lines 4-8 have a unique name as a parameter which is the project name. Also edit line 4 so the last parameters is the number of rupture bundles made. The final number of waveforms is that number multiplied by 16.


This is the Slow Slip Events (SSE) Branch. 
