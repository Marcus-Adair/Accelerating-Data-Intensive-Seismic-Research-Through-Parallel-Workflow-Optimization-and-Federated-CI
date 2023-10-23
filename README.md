# Accelerating Data-Intensive Seismic Research Through Parallel Workflow Optimization and Federated Cyberinfrastructure

# FakeQuakes DAGMan Workflow (FDW) Source Code

This repository contains source code for the FakeQuakes DAGMan Workflow, a tool that utilizes OSG to parallelize and expedite FakeQuakes earthquakes simulation. This workflow is to be integrated into the VDC.

The submit files for running OSG jobs use a custom Singularity image with MudPy installed and other required scripts required for the DAGMan workflow to work.
They access it via the public stash so there is no need to download the image.

However it is available at the /public OSG location: /ospool/ap21/data/marcus_adair/old-public/madair_mudpy_mudsing_image_complete_v1.sif

Or you can also find it at https://drive.google.com/file/d/1tkUlKqFBiDC01UUd1V5tTenZxSP4cmY3/view?usp=sharing


If you are running this workflow you must change the username from 'marcus_adair' to your OSG username for stuff relating to the public OSG directoy and mseeed files - this is so modifications can be made the the public directoy which hold the large mseeds files (that are to big to hold in private).
