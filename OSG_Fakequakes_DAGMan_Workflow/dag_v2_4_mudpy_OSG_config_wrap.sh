# Author: Marcus Adair (RA for Ivan Rodero)
# Date: August 2022   
# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute
#
# Configuration file for setting parameters and launching FakeQuake jobs over OSG
# This file is where you set fakequake parameters and it is the wrapper which is executed by
# submit files over the OSG and it executes the A,B, or C phase jobs. 
#
#
# Modified by Marcus Adair Dec. 2023 
# ---------------------------------#
# Modified to account for Slow Slip Events (SSE) earthquake simulation



#### ----- Configure Parameters below ---------

###      Edit these to change fakequake parameters. Do NOT change variable names. Do not add any whitespace during variable declaration via bash script syntax
##          Note: for things to work over the OSG, keep filenames in lowercase letters (change input files to lowercase if not already)

##		For True or False options, the options to declare that is (T,t,1,F,f,0)


project_name=$1                     # Get the project name passed in from the .submit file on OSG. (in the format fakequakes_runN) (N>0 -> recycle matrices)

ncpus=4                             # Number of CPUs. Set to 1 when first running make_ruptures=1     
run_name=run                        # Run name (not related to the 'project_name' matrix stuff above)(don't change unless you know what you're doing & don't add numbers

# Velocity model (.mod file)
model_name=cascadia.mod

# Fault geometry (.fault file)
fault_name=csz_coarse.fault

# Slab 1.0 Ascii file (only used for 3D fault) (.xyz file)
slab_name=cas_slab2_dep_02.24.18.xyz

 # GMSH output file (only used for 3D fault) (.mshout file)
mesh_name=csz_coarse.mshout

distances_name=csz_coarse    # Name of distance matrix

# Look here if unsure (https://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system#/media/File:Utm-zones.jpg)
utm_zone=10T

scaling_law=SSE                     # Options: T for thrust, S for strike-slip, N for normal
dynamic_gflist=T                    # dynamic GFlist (True/False)
dist_threshold=50.0                 # #(degree) station to the closest subfault must be closer to this distance

#slip parameters
nrealizations=4                     # Number of fake ruptures to generate per magnitude bin. let Nrealizations % ncpus=0

# Of what approximate magnitudes, parameters of numpy.arange()
target_mw=5,8,2

# Maximum slip (m) allowed in the model
max_slip=0.5

# Correlation function parameters
hurst=0.75                           # 0.4~0.7 is reasonable
ldip=auto                           # Correlation length scaling, 'auto' uses  Mai & Beroza 2002, 
lstrike=auto                        # MH2019 uses Melgar & Hayes 2019
lognormal=T			                # (True/False)
slip_standard_deviation=0.46
num_modes=200                       # Modes in K-L expantion (max#= munber of subfaults )
rake=90.0

# Rupture parameters
force_magnitude=F                   # Make the magnitudes EXACTLY the value in target_Mw (True/False)
force_area=F                        # Forces using the entire fault area defined by the .fault file as opposed to the scaling law (True/False)s
no_random=F                         # If true uses median length/width if false draws from prob. distribution (True/False)

# Defines the hypocentral time
time_epi=2014-04-01T23:46:47Z

# Defines the specific hypocenter location if force_hypocenter=True
hypocenter=None
force_hypocenter=F                  # Forces hypocenter to occur at specified lcoationa s opposed to random (True/False)
mean_slip=None                      # Provide path to file name of .rupt to be used as mean slip pattern
center_subfault=None                # Integer value, if != None use that subfault as center for defining rupt area. If none then slected at random
use_hypo_fraction=F                 # If true use hypocenter PDF positions from Melgar & Hayes 2019, if false then selects at random   (True/False)

# Kinematic parameters
source_time_function=ji             # options are 'triangle' or 'cosine' or 'dreger'
rise_time_depths=1,2              # Transition depths for rise time scaling
shear_wave_fraction=0.8             # Fraction of shear wave speed to use as mean rupture velocity
shear_wave_fraction_deep=0.8
shear_wave_fraction_shallow=0.49

# Station information (only used when syntehsizing waveforms) (.gflist file)
gf_list=chile_gnss.gflist
g_name=gnss

# Displacement and velocity waveform parameters and fk-parameters
nfft=60
dt=14400
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



# TODO: Add new SSE Params 
moho_depth_in_km=25.0
hf_dt=0.01
duration=120
pwave=T
zero_phase=F
order=4
fcorner=1.0
inpolygon_fault=hypo_4548
inpolygon_hypocenter=hypo_4548
high_stress_depth=30
stress_parameter=50


########---------------- DO NOT CHANGE ANYTHING UNDER THIS (unless you know what you're doing)

##############################################################################################


# make a path that the system can write to on the execute node
cd ~
mkdir mudprojects
cd mudprojects
HOMEPATH=$PWD           #get the path of the directory where MudPy 'projects' are initialized
cd ..

# Get arg passed in from .submit file which determines which job/script to run
jobphase=$2

# get the arg passin in which is the unique name for this run
prepinput=$3
 
if [ "$jobphase" = "A" ]; then

    ruptrun=$4
    run_name="${run_name}_${ruptrun}"
	
    sh dag_v2_4_jobA.sh $project_name $HOMEPATH $ncpus $run_name $model_name $fault_name $slab_name $mesh_name $distances_name $utm_zone $scaling_law $dynamic_gflist $dist_threshold $nrealizations $target_mw $max_slip $hurst $ldip $lstrike $lognormal $slip_standard_deviation $num_modes $rake $force_magnitude $force_area $no_random $time_epi $hypocenter $force_hypocenter $mean_slip $center_subfault $use_hypo_fraction $source_time_function $rise_time_depths $shear_wave_fraction $shear_wave_fraction_deep $shear_wave_fraction_shallow $gf_list $g_name $nfft $dt $zeta $dk $pmin $pmax $kmax $custom_stf $rupture_list $max_slip_rule $slip_tol $stf_falloff_rate $rupture_name $hot_start $impulse $epicenter $prepinput $moho_depth_in_km $hf_dt $duration $pwave $zero_phase $order $fcorner $inpolygon_fault $inpolygon_hypocenter $high_stress_depth $stress_parameter
elif [ "$jobphase" = "B" ]; then

    rupt1=$4
    rupt2=$5	

    sh dag_v2_4_jobB.sh $project_name $HOMEPATH $ncpus $run_name $model_name $fault_name $slab_name $mesh_name $distances_name $utm_zone $scaling_law $dynamic_gflist $dist_threshold $nrealizations $target_mw $max_slip $hurst $ldip $lstrike $lognormal $slip_standard_deviation $num_modes $rake $force_magnitude $force_area $no_random $time_epi $hypocenter $force_hypocenter $mean_slip $center_subfault $use_hypo_fraction $source_time_function $rise_time_depths $shear_wave_fraction $shear_wave_fraction_deep $shear_wave_fraction_shallow $gf_list $g_name $nfft $dt $zeta $dk $pmin $pmax $kmax $custom_stf $rupture_list $max_slip_rule $slip_tol $stf_falloff_rate $rupture_name $hot_start $impulse $epicenter $prepinput $rupt1 $rupt2 $moho_depth_in_km $hf_dt $duration $pwave $zero_phase $order $fcorner $inpolygon_fault $inpolygon_hypocenter $high_stress_depth $stress_parameter
elif [ "$jobphase" = "C" ]; then

    rupt1=$4
    rupt2=$5

    sh dag_v2_4_jobC.sh $project_name $HOMEPATH $ncpus $run_name $model_name $fault_name $slab_name $mesh_name $distances_name $utm_zone $scaling_law $dynamic_gflist $dist_threshold $nrealizations $target_mw $max_slip $hurst $ldip $lstrike $lognormal $slip_standard_deviation $num_modes $rake $force_magnitude $force_area $no_random $time_epi $hypocenter $force_hypocenter $mean_slip $center_subfault $use_hypo_fraction $source_time_function $rise_time_depths $shear_wave_fraction $shear_wave_fraction_deep $shear_wave_fraction_shallow $gf_list $g_name $nfft $dt $zeta $dk $pmin $pmax $kmax $custom_stf $rupture_list $max_slip_rule $slip_tol $stf_falloff_rate $rupture_name $hot_start $impulse $epicenter $prepinput $rupt1 $rupt2 $moho_depth_in_km $hf_dt $duration $pwave $zero_phase $order $fcorner $inpolygon_fault $inpolygon_hypocenter $high_stress_depth $stress_parameter
fi

