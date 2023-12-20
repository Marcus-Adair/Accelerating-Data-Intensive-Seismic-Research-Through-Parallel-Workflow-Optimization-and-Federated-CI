#
#
#

#
#       This script executes Job C of DAGman_v2 
#
#       This includes running make_waveforms a single time with MudPy with load_G_files=1
#       This script will be ran N times where N is the number of simulations to be ran specified by the user.
#       These fakequakes are based off of ruptures.list, the station list, and the rest of the preparedinput.
#
#       This will zip up output waveform files to be saved (those waveforms files will be used to train machine learning models.)
#

#### ----- Configure Parameters below ---------

#  Get the job name from submit file arguments. This is be the name of the directory initialized by
#  MudPy, and each job's output will be transferred out via the stash in the format $PROJNAME.tar.gz
PROJNAME=$1
HOMEPATH=$2

ncpus=$3                             # Number of CPUs. Set to 1 when first running make_ruptures=1     
run_name=$4                    # Run name (Note: this is not linked to the 'runnumber' mentioned above)

model_name=$5          # Velocity model
fault_name=$6              # Fault geometry
slab_name=$7                 # Slab 1.0 Ascii file (only used for 3D fault)
mesh_name=$8              # GMSH output file (only used for 3D fault)
distances_name=$9    # Name of distance matrix
utm_zone=${10}                        # Look here if unsure (https://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system#/media/File:Utm-zones.jpg)
scaling_law=${11}                       # Options: T for thrust, S for strike-slip, N for normal
dynamic_gflist=${12}                    # dynamic GFlist (True/False)
dist_threshold=${13}                 # #(degree) station to the closest subfault must be closer to this distance

#slip parameters
nrealizations=${14}                     # Number of fake ruptures to generate per magnitude bin. let Nrealizations % ncpus=0
target_mw=${15}               # Of what approximate magnitudes, parameters of numpy.arange()
max_slip=${16}                        # Maximum slip (m) allowed in the model

# Correlation function parameters
hurst=${17}                           # 0.4~0.7 is reasonable
ldip=${18}                           # Correlation length scaling, 'auto' uses  Mai & Beroza 2002, 
lstrike=${19}                        # MH2019 uses Melgar & Hayes 2019
lognormal=${20}			                # (True/False)
slip_standard_deviation=${21}
num_modes=${22}                       # Modes in K-L expantion (max#= munber of subfaults )
rake=${23}

# Rupture parameters
force_magnitude=${24}                   # Make the magnitudes EXACTLY the value in target_Mw (True/False)
force_area=${25}                        # Forces using the entire fault area defined by the .fault file as opposed to the scaling law (True/False)s
no_random=${26}                         # If true uses median length/width if false draws from prob. distribution (True/False)
time_epi=${27}        # Defines the hypocentral time
hypocenter=${28}        # Defines the specific hypocenter location if force_hypocenter=True
force_hypocenter=${29}                  # Forces hypocenter to occur at specified lcoationa s opposed to random (True/False)
mean_slip=${30}                      # Provide path to file name of .rupt to be used as mean slip pattern
center_subfault=${31}                # Integer value, if != None use that subfault as center for defining rupt area. If none then slected at random
use_hypo_fraction=${32}                 # If true use hypocenter PDF positions from Melgar & Hayes 2019, if false then selects at random   (True/False)

# Kinematic parameters
source_time_function=${33}         # options are 'triangle' or 'cosine' or 'dreger'
rise_time_depths=${34}             # Transition depths for rise time scaling
shear_wave_fraction=${35}             # Fraction of shear wave speed to use as mean rupture velocity
shear_wave_fraction_deep=${36}
shear_wave_fraction_shallow=${37}

# Station information (only used when syntehsizing waveforms)
gf_list=${38}
g_name=${39}

# Displacement and velocity waveform parameters and fk-parameters
nfft=${40}
dt=${41}
zeta=${42}
dk=${43}
pmin=${44}
pmax=${45}
kmax=${46}
custom_stf=${47}
rupture_list=${48}         # Don't change this (unless you know waht you're doing!)
max_slip_rule=${49}
slip_tol=${50}
stf_falloff_rate=${51}
rupture_name=${52}
hot_start=${53}
impulse=${54}				# (True/False)
epicenter=${55}


# New SSE params
moho_depth_in_km=${59}
hf_dt=${60}
duration=${61}
pwave=${62}
zero_phase=${63}
order=${64}
fcorner=${65}
inpolygon_fault=${66}
inpolygon_hypocenter=${67}
high_stress_depth=${68}
stress_parameter=${69}


########---------------- DO NOT CHANGE ANYTHING UNDER THIS (unless you know what you're doing)

##############################################################################################

set -e  # Have job exit if any command returns with non-zero exit status - aka failure

#  get name of this unique run
preparedinput=${56}

# get the names of the  ruptuers to work on
rupt1=${57}
rupt2=${58}

# get the runnumber off the project_name (each project name should have a number in it which is N and the runnumber)
runnum=$(echo "$PROJNAME" | tr -dc '0-9') 

# activate the python environment built in to this Singularity image
cd /
. quake3.6/bin/activate
cd ~

# Have MudPy intialize a folder structure to write output data to named $PROJNAME.
#python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py init -load_distances=0 -g_from_file=0 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -epicenter=$epicenter -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -dynamic_gflist=$dynamic_gflist -dist_threshold=$dist_threshold -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -no_random=$no_random -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -mean_slip=$mean_slip -center_subfault=$center_subfault -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -shear_wave_fraction=$shear_wave_fraction -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -slip_tol=$slip_tol -shear_wave_fraction_deep=$shear_wave_fraction_deep -shear_wave_fraction_shallow=$shear_wave_fraction_shallow -zeta=$zeta -stf_falloff_rate=$stf_falloff_rate -rupture_name=$rupture_name -hot_start=$hot_start -impulse=$impulse -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name

python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_SSE.fq.py init -load_distances=0 -g_from_file=0 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -mean_slip=$mean_slip -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -stf_falloff_rate=$stf_falloff_rate -hot_start=$hot_start -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name -moho_depth_in_km=$moho_depth_in_km -hf_dt=$hf_dt -duration=$duration -pwave=$pwave -zero_phase=$zero_phase -order=$order -fcorner=$fcorner -inpolygon_fault=$inpolygon_fault -inpolygon_hypocenter=$inpolygon_hypocenter -high_stress_depth=$high_stress_depth -stress_parameter=$stress_parameter

# Unpack the input files prepared by the user
# and move them into the right places 
tar -xzf inputfiles.tar.gz
rm inputfiles.tar.gz
cd inputfiles
mv *.mod $HOMEPATH/$PROJNAME/structure
mv *.fault $HOMEPATH/$PROJNAME/data/model_info
mv *.mshout $HOMEPATH/$PROJNAME/data/model_info
mv *.xyz $HOMEPATH/$PROJNAME/data/model_info
mv *.gflist $HOMEPATH/$PROJNAME/data/station_info

# Make the ruptures list from the 2 rupture varss
cd ~
> ruptures.list
echo "$rupt1.rupt" >> ruptures.list
echo "$rupt2.rupt" >> ruptures.list

# Move the rupture list and the rupture files to their place
mv ruptures.list $HOMEPATH/$PROJNAME/data

#  move the rupture files to their place
mv $rupt1.rupt $HOMEPATH/$PROJNAME/output/ruptures
mv $rupt1.log $HOMEPATH/$PROJNAME/output/ruptures
mv $rupt2.rupt $HOMEPATH/$PROJNAME/output/ruptures
mv $rupt2.log $HOMEPATH/$PROJNAME/output/ruptures

# Unpack the mseeds.tar.gz and mv them to their place
tar -xzf mseeds.tar.gz
rm mseeds.tar.gz
cd mseeds
mv *.mseed $HOMEPATH/$PROJNAME/GFs/matrices
cd ~

# Move the rupture files (.rupt/.log) and ruptures.list to the right place
#mv ruptures.list $HOMEPATH/$PROJNAME/data
#mv ruptures.tar.gz $HOMEPATH/$PROJNAME/output
#cd $HOMEPATH/$PROJNAME/output
#tar -xzf ruptures.tar.gz
#rm ruptures.tar.gz

#  Move the .npy/distance  and .mseed matrices
#cd ~/preparedinput
#mv *.npy $HOMEPATH/$PROJNAME/data/distances
#mv *.mseed $HOMEPATH/$PROJNAME/GFs/matrices
#cd ..               

# run simulation/make waveforms
#python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_waveforms -load_distances=0 -g_from_file=1  -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -dynamic_gflist=$dynamic_gflist -dist_threshold=$dist_threshold -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -no_random=$no_random -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -mean_slip=$mean_slip -center_subfault=$center_subfault -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -shear_wave_fraction=$shear_wave_fraction -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -slip_tol=$slip_tol -shear_wave_fraction_deep=$shear_wave_fraction_deep -shear_wave_fraction_shallow=$shear_wave_fraction_shallow -zeta=$zeta -stf_falloff_rate=$stf_falloff_rate -rupture_name=$rupture_name -hot_start=$hot_start -impulse=$impulse -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name

python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_SSE.fq.py make_waveforms -load_distances=0 -g_from_file=1 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -mean_slip=$mean_slip -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -stf_falloff_rate=$stf_falloff_rate -hot_start=$hot_start -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name -moho_depth_in_km=$moho_depth_in_km -hf_dt=$hf_dt -duration=$duration -pwave=$pwave -zero_phase=$zero_phase -order=$order -fcorner=$fcorner -inpolygon_fault=$inpolygon_fault -inpolygon_hypocenter=$inpolygon_hypocenter -high_stress_depth=$high_stress_depth -stress_parameter=$stress_parameter

# Compress the directory with the simulation data to transfer out
# Don't transfer the entire dir out, just the waveforms
cd $HOMEPATH/$PROJNAME/output
FILENAME=$PROJNAME.tar.gz
echo "The FILENAME which contains waveforms is: $FILENAME"
tar -czf $FILENAME waveforms 
mv $FILENAME ~
cd ~



# Get the output file size in bytes
#FILESIZE=$(wc -c < $FILENAME)
# convert bytes to megabytes
#FILESIZE=$((FILESIZE >> 20)) 
#echo "Size of output file: $FILENAME = $FILESIZE MB."

# output tarball left in home dir so it's output to /home/<username>
#echo "Output: $FILENAME was transferred back to the OSG user."
