# Optimizing Earthquake Simulations and the OSG to Promote Interdisciplinary, Data-Intensive Research

This repository contains source code for the FakeQuakes DAGMan Workflow, a tool that utilizes OSG to parallelize and expedite FakeQuakes earthquakes simulation. This workflow is to be integrated into the VDC.

The submit files for running OSG jobs use a custom Singularity image with MudPy installed and other required scripts required for the DAGMan workflow to work.
They access it via the public stash so there is no need to download the image.

However it is available at marcus_adair@login05.osgconnect.net:/public/marcus_adair/madair_mudpy_mudsing_image_complete_v1.sif

Or you can also find it at https://drive.google.com/file/d/1tkUlKqFBiDC01UUd1V5tTenZxSP4cmY3/view?usp=sharing
