#   Wrapper/config file for executing a single job which is a fakequake simulation inside of a Singularity shell
#
#   This utilizes a file called 'mudpy_config_exec' which is built into a Singularity image along 
#   with the MudPy simulation software (and this file). This file sets paramaters and then
#   calls the file to run a fakequake simulation.
#
#   Change the input parameters below to customize your fakequake simulations
#   When this is done there will be a directory in ~/mudprojects dir named after 'project_name' 
#   which is set by the user (make sure to format project_name right for things to work, directions given below)
#
#  This script assumes there's a tarball in the home dir which holds the 5 neccesary input files for fakequakes to run.
#  These are files that end in .mod, .xyz, .mshout, gflist, .fault (one of each) and are held in 'preparedinput.tar.gz'
#  To prepare your own files for fakequake simulations: 
#  1. Create a directory called 'preparedinput'. 2. Move files (.mod, .xyz, etc.) into the new dir.
#  3. Wrap to a tarbal with command 'tar -czf preparedinput.tar.gz preparedinput'   4. Move 'preparedinput.tar.gz' to the home directory before running this script (~).
#
#  After running an initial simulation, there will be a tarball callad 'matricesoutput.tar.gz' in the home dir which contans matrices that can be recycled for 
#  simulations which use the same input files (above). To recycle these just launch a simulation where the 'project_name' contains some positive number (not 0)
#
#  * MAKE SURE THAT YOUR INPUT FILES' NAMES MATCH THEIR CORRESPONDING PARAMETERS BELOW (model_name, fault_name, slab_name, mesh_name, gf_list)

#### ----- Configure Parameters below ---------

###      Edit these to change fakequake parameters. Do NOT change variable names. Do not add any whitespace during variable declaration via bash script syntax

##		For True or False options, the options to declare that is (T,t,1,F,f,0)


# 'project_name' can be any word but must contain a number which is 0 or some positive integer. The script which this wrapper
# calls extracts the digits in the 'project_name' and uses them to see if G and distance matrices should be recycled or not.
# If that number is 0 then matrices will be calculated. If it is some other positive number then it is assumed
# that matrices are present as a tarball in the home dir and are to be recycled in simulations. (So unless you are recycling distance or G matrices,
#  always have it so the runnumber will be 0. e.g pass in as an argument to this script: "fakequakes_run0", "0", "run0")
project_name=fakequakes_run0       

ncpus=4                             # Number of CPUs. Set to 1 when first running make_ruptures=1     
run_name=run_v1                     # Run name for labeling certain files within the run (not related to the 'project_name' matrix stuff above)

model_name=vel1d_chile.mod          # Velocity model
fault_name=chile.fault              # Fault geometry
slab_name=chile.xyz                 # Slab 1.0 Ascii file (only used for 3D fault)
mesh_name=chile.mshout              # GMSH output file (only used for 3D fault)
distances_name=planar_subduction    # Name of distance matrix
utm_zone=19J                        # Look here if unsure (https://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system#/media/File:Utm-zones.jpg)
scaling_law=T                       # Options: T for thrust, S for strike-slip, N for normal
dynamic_gflist=T                    # dynamic GFlist (True/False)
dist_threshold=50.0                 # #(degree) station to the closest subfault must be closer to this distance

#slip parameters
nrealizations=4                     # Number of fake ruptures to generate per magnitude bin. let Nrealizations % ncpus=0
target_mw=8.5,9.2,0.2               # Of what approximate magnitudes, parameters of numpy.arange()
max_slip=100                        # Maximum slip (m) allowed in the model

# Correlation function parameters
hurst=0.4                           # 0.4~0.7 is reasonable
ldip=auto                           # Correlation length scaling, 'auto' uses  Mai & Beroza 2002, 
lstrike=auto                        # MH2019 uses Melgar & Hayes 2019
lognormal=T			                # (True/False)
slip_standard_deviation=0.9
num_modes=100                       # Modes in K-L expantion (max#= munber of subfaults )
rake=90.0

# Rupture parameters
force_magnitude=F                   # Make the magnitudes EXACTLY the value in target_Mw (True/False)
force_area=F                        # Forces using the entire fault area defined by the .fault file as opposed to the scaling law (True/False)s
no_random=F                         # If true uses median length/width if false draws from prob. distribution (True/False)
time_epi=2016-09-07T14:42:26        # Defines the hypocentral time
hypocenter=0.8301,0.01,27.67        # Defines the specific hypocenter location if force_hypocenter=True
force_hypocenter=F                  # Forces hypocenter to occur at specified lcoationa s opposed to random (True/False)
mean_slip=None                      # Provide path to file name of .rupt to be used as mean slip pattern
center_subfault=None                # Integer value, if != None use that subfault as center for defining rupt area. If none then slected at random
use_hypo_fraction=F                 # If true use hypocenter PDF positions from Melgar & Hayes 2019, if false then selects at random   (True/False)

# Kinematic parameters
source_time_function=dreger         # options are 'triangle' or 'cosine' or 'dreger'
rise_time_depths=10,15              # Transition depths for rise time scaling
shear_wave_fraction=0.8             # Fraction of shear wave speed to use as mean rupture velocity
shear_wave_fraction_deep=0.8
shear_wave_fraction_shallow=0.49

# Station information (only used when syntehsizing waveforms)
gf_list=chile_gnss_small.gflist
g_name=GFs

# Displacement and velocity waveform parameters and fk-parameters
nfft=128
dt=1.0
zeta=0.2
dk=0.1
pmin=0
pmax=1
kmax=20
custom_stf=None
rupture_list=ruptures.list          # Don't change this (unless you know waht you're doing!)
max_slip_rule=T
slip_tol=0.01
stf_falloff_rate=4.0
rupture_name=None
hot_start=0
impulse=F				# (True/False)
epicenter=None

########---------------- DO NOT CHANGE ANYTHING UNDER THIS (unless you know what you're doing)

##############################################################################################

# Set the path of the directory where MudPy 'projects' are initialized ( in this case it is the home dir (~)).
# This can be changed if needed but is not advised (unless you know what you're doing.)
cd ~                
HOMEPATH=$PWD          

# Call the executeable in the image with all the parameters set above
sh /launch_mudpy/mudpy_config_exec.sh $project_name $HOMEPATH $ncpus $run_name $model_name $fault_name $slab_name $mesh_name $distances_name $utm_zone $scaling_law $dynamic_gflist $dist_threshold $nrealizations $target_mw $max_slip $hurst $ldip $lstrike $lognormal $slip_standard_deviation $num_modes $rake $force_magnitude $force_area $no_random $time_epi $hypocenter $force_hypocenter $mean_slip $center_subfault $use_hypo_fraction $source_time_function $rise_time_depths $shear_wave_fraction $shear_wave_fraction_deep $shear_wave_fraction_shallow $gf_list $g_name $nfft $dt $zeta $dk $pmin $pmax $kmax $custom_stf $rupture_list $max_slip_rule $slip_tol $stf_falloff_rate $rupture_name $hot_start $impulse $epicenter


