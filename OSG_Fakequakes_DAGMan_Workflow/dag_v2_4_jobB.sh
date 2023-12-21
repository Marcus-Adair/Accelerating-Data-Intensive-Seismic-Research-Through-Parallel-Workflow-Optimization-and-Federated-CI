# 	This script executes Job B of DAGman_v2 
#
#       This includes making GFs/Synthetics and running make_waveforms once with MudPy to make .mseed matrices and get some waveforms. 
#

#### ----- Configure Parameters below ---------

#  Get the job name from submit file arguments. This is be the name of the directory initialized by
#  MudPy, and each job's output will be transferred out via the stash in the format $PROJNAME.tar.gz
PROJNAME=$1
HOMEPATH=$2

ncpus=$3                                # Number of CPUs. Set to 1 when first running make_ruptures=1     
run_name=$4                             # Run name (Note: this is not linked to the 'runnumber' mentioned above)

model_name=$5                           # Velocity model
fault_name=$6                           # Fault geometry
slab_name=$7                            # Slab 1.0 Ascii file (only used for 3D fault)
mesh_name=$8                            # GMSH output file (only used for 3D fault)
distances_name=$9                       # Name of distance matrix
utm_zone=${10}                          # Look here if unsure (https://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system#/media/File:Utm-zones.jpg)
scaling_law=${11}                       # Options: T for thrust, S for strike-slip, N for normal
dynamic_gflist=${12}                    # dynamic GFlist (True/False)
dist_threshold=${13}                    # #(degree) station to the closest subfault must be closer to this distance

#slip parameters
nrealizations=${14}                     # Number of fake ruptures to generate per magnitude bin. let Nrealizations % ncpus=0
target_mw=${15}                         # Of what approximate magnitudes, parameters of numpy.arange()
max_slip=${16}                          # Maximum slip (m) allowed in the model

# Correlation function parameters
hurst=${17}                             # 0.4~0.7 is reasonable
ldip=${18}                              # Correlation length scaling, 'auto' uses  Mai & Beroza 2002, 
lstrike=${19}                           # MH2019 uses Melgar & Hayes 2019
lognormal=${20}			                # (True/False)
slip_standard_deviation=${21}
num_modes=${22}                         # Modes in K-L expantion (max#= munber of subfaults )
rake=${23}

# Rupture parameters
force_magnitude=${24}                   # Make the magnitudes EXACTLY the value in target_Mw (True/False)
force_area=${25}                        # Forces using the entire fault area defined by the .fault file as opposed to the scaling law (True/False)s
no_random=${26}                         # If true uses median length/width if false draws from prob. distribution (True/False)
time_epi=${27}                          # Defines the hypocentral time
hypocenter=${28}                        # Defines the specific hypocenter location if force_hypocenter=True
force_hypocenter=${29}                  # Forces hypocenter to occur at specified lcoationa s opposed to random (True/False)
mean_slip_name=${30}                         # Provide path to file name of .rupt to be used as mean slip pattern
center_subfault=${31}                   # Integer value, if != None use that subfault as center for defining rupt area. If none then slected at random
use_hypo_fraction=${32}                 # If true use hypocenter PDF positions from Melgar & Hayes 2019, if false then selects at random   (True/False)

# Kinematic parameters
source_time_function=${33}              # options are 'triangle' or 'cosine' or 'dreger'
rise_time_depths=${34}                  # Transition depths for rise time scaling
shear_wave_fraction=${35}               # Fraction of shear wave speed to use as mean rupture velocity
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

# Set the hypocenter paths
inpolygon_fault="$HOMEPATH/$PROJNAME/data/model_info/$inpolygon_fault"
inpolygon_hypocenter="$HOMEPATH/$PROJNAME/data/model_info/$inpolygon_hypocenter"


set -e  # Have job exit if any command returns with non-zero exit status - aka failure

# get the unique name of this run
preparedinput=${56}

rupt1=${57}
rupt2=${58}

# Get the  runnumber from the unique run name  by extracting the numbers
runnum=$(echo "$PROJNAME" | tr -dc '0-9')

# Check preparedinput for existence of .mseedfiles
tar -xzf inputfiles.tar.gz
rm inputfiles.tar.gz

 
mseedsmade=0
#mcount=$(ls *.mseed 2>/dev/null | wc -l)
#if [ "$mcount" != "0" ]; then
#    mseedsmade=1
#fi

# check if mseeds were passed in or not
filetocheck=mseeds.tar.gz
cd  ~
if [ -f "$filetocheck" ]; then
	mseedsmade=1
fi



# If no .mseed matrices were passed in to recycle
#if  [ "$mseedsmade" = "0" ]; then 

# activate the python environment built in to this Singularity image
cd /
. quake3.6/bin/activate
cd ~

echo "initializing folder ..."
# Intialize a MudPy folder structure with the given $PROJNAME. 
#python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py init -load_distances=0 -g_from_file=0 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -epicenter=$epicenter -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -dynamic_gflist=$dynamic_gflist -dist_threshold=$dist_threshold -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -no_random=$no_random -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -mean_slip=$mean_slip -center_subfault=$center_subfault -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -shear_wave_fraction=$shear_wave_fraction -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -slip_tol=$slip_tol -shear_wave_fraction_deep=$shear_wave_fraction_deep -shear_wave_fraction_shallow=$shear_wave_fraction_shallow -zeta=$zeta -stf_falloff_rate=$stf_falloff_rate -rupture_name=$rupture_name -hot_start=$hot_start -impulse=$impulse -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name

python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_SSE.fq.py init -load_distances=0 -g_from_file=0 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter  -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -stf_falloff_rate=$stf_falloff_rate -hot_start=$hot_start -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name -moho_depth_in_km=$moho_depth_in_km -hf_dt=$hf_dt -duration=$duration -pwave=$pwave -zero_phase=$zero_phase -order=$order -fcorner=$fcorner -inpolygon_fault=$inpolygon_fault -inpolygon_hypocenter=$inpolygon_hypocenter -high_stress_depth=$high_stress_depth -stress_parameter=$stress_parameter -mean_slip_name=$mean_slip_name

# Put the prepared input by the user into it's place    
cd ~/inputfiles
mv *.mod $HOMEPATH/$PROJNAME/structure
mv *.fault $HOMEPATH/$PROJNAME/data/model_info
mv *.mshout $HOMEPATH/$PROJNAME/data/model_info
mv *.xyz $HOMEPATH/$PROJNAME/data/model_info
mv *.gflist $HOMEPATH/$PROJNAME/data/station_info
mv hypo_4548 $HOMEPATH/$PROJNAME/data/model_info


echo "moved input data to folder..."

# Move the rupture files & rupture.list to the right place so waveforms can be made
#mv ruptures.list $HOMEPATH/$PROJNAME/data


# Move the files for the 2 ruptures brought in by the submit file to their place
# and creat the ruptures.list for those 2 ruptures.
cd ~

> ruptures.list
echo -e $rupt1.rupt >> ruptures.list
echo -e $rupt2.rupt >> ruptures.list
mv ruptures.list $HOMEPATH/$PROJNAME/data

mv $rupt1.rupt $HOMEPATH/$PROJNAME/output/ruptures
mv $rupt1.log $HOMEPATH/$PROJNAME/output/ruptures
mv $rupt2.rupt $HOMEPATH/$PROJNAME/output/ruptures
mv $rupt2.log $HOMEPATH/$PROJNAME/output/ruptures


#mv ruptures.tar.gz $HOMEPATH/$PROJNAME/output
#cd $HOMEPATH/$PROJNAME/output
#tar -xzf ruptures.tar.gz
#rm ruptures.tar.gz


# If no .mseed matrices were passed in to recycle
if  [ "$mseedsmade" = "0" ]; then	

	echo "making g files ... "

    # Make GFs/synthetics
    #python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_g_files -load_distances=0 -g_from_file=0 -ncpus=$ncpus -model_name=$model_name -epicenter=$epicenter -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -dynamic_gflist=$dynamic_gflist -dist_threshold=$dist_threshold -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -no_random=$no_random -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -mean_slip=$mean_slip -center_subfault=$center_subfault -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -shear_wave_fraction=$shear_wave_fraction -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -slip_tol=$slip_tol -shear_wave_fraction_deep=$shear_wave_fraction_deep -shear_wave_fraction_shallow=$shear_wave_fraction_shallow -zeta=$zeta -stf_falloff_rate=$stf_falloff_rate -rupture_name=$rupture_name -hot_start=$hot_start -impulse=$impulse -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name
    python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_SSE.fq.py make_g_files -load_distances=0 -g_from_file=0 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter  -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -stf_falloff_rate=$stf_falloff_rate -hot_start=$hot_start -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name -moho_depth_in_km=$moho_depth_in_km -hf_dt=$hf_dt -duration=$duration -pwave=$pwave -zero_phase=$zero_phase -order=$order -fcorner=$fcorner -inpolygon_fault=$inpolygon_fault -inpolygon_hypocenter=$inpolygon_hypocenter -high_stress_depth=$high_stress_depth -stress_parameter=$stress_parameter -mean_slip_name=$mean_slip_name

fi



#  Move the .npy/distance matrices
#cd ~/preparedinput
#mv *.npy $HOMEPATH/$PROJNAME/data/distances

#cd ~               
    
# If no .mseed matrices were passed in to recycle
if  [ "$mseedsmade" = "0" ]; then
    
    echo "making waveforms and mseeds"	
	
    # Run make waveforms with load_G_files=0 to generate the .mseed matrices for an (N-1) number of simulations to use. Also generating one round of waveforms
    #python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_waveforms -load_distances=0 -g_from_file=0 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -epicenter=$epicenter -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -dynamic_gflist=$dynamic_gflist -dist_threshold=$dist_threshold -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -no_random=$no_random -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -mean_slip=$mean_slip -center_subfault=$center_subfault -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -shear_wave_fraction=$shear_wave_fraction -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -slip_tol=$slip_tol -shear_wave_fraction_deep=$shear_wave_fraction_deep -shear_wave_fraction_shallow=$shear_wave_fraction_shallow -zeta=$zeta -stf_falloff_rate=$stf_falloff_rate -rupture_name=$rupture_name -hot_start=$hot_start -impulse=$impulse -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name
    python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_SSE.fq.py make_waveforms -load_distances=0 -g_from_file=0 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -stf_falloff_rate=$stf_falloff_rate -hot_start=$hot_start -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name -moho_depth_in_km=$moho_depth_in_km -hf_dt=$hf_dt -duration=$duration -pwave=$pwave -zero_phase=$zero_phase -order=$order -fcorner=$fcorner -inpolygon_fault=$inpolygon_fault -inpolygon_hypocenter=$inpolygon_hypocenter -high_stress_depth=$high_stress_depth -stress_parameter=$stress_parameter

else 

	echo "making waveforms and recycling mseeds"
	# Move the mseeds  to the right place to be used
	cd ~
	tar -xzf mseeds.tar.gz 
	rm mseeds.tar.gz
	cd mseeds
	mv *.mseed $HOMEPATH/$PROJNAME/GFs/matrices

	# Recycle .mseed matrices
        #python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_chile.fq.py make_waveforms -load_distances=0 -g_from_file=1 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -epicenter=$epicenter -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -dynamic_gflist=$dynamic_gflist -dist_threshold=$dist_threshold -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -no_random=$no_random -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -mean_slip=$mean_slip -center_subfault=$center_subfault -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -shear_wave_fraction=$shear_wave_fraction -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -slip_tol=$slip_tol -shear_wave_fraction_deep=$shear_wave_fraction_deep -shear_wave_fraction_shallow=$shear_wave_fraction_shallow -zeta=$zeta -stf_falloff_rate=$stf_falloff_rate -rupture_name=$rupture_name -hot_start=$hot_start -impulse=$impulse -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name
	python3 /MudPy/examples/fakequakes/planar/mudpy_single_exec_SSE.fq.py make_waveforms -load_distances=0 -g_from_file=1 -ncpus=$ncpus -model_name=$model_name -fault_name=$fault_name -slab_name=$slab_name -mesh_name=$mesh_name -distances_name=$distances_name -utm_zone=$utm_zone -scaling_law=$scaling_law -nrealizations=$nrealizations -max_slip=$max_slip -hurst=$hurst -ldip=$ldip -lstrike=$lstrike -lognormal=$lognormal -slip_standard_deviation=$slip_standard_deviation -num_modes=$num_modes -rake=$rake -force_magnitude=$force_magnitude -force_area=$force_area -time_epi=$time_epi -hypocenter=$hypocenter -force_hypocenter=$force_hypocenter -use_hypo_fraction=$use_hypo_fraction -source_time_function=$source_time_function -rise_time_depths=$rise_time_depths -gf_list=$gf_list -g_name=$g_name -nfft=$nfft -dt=$dt -dk=$dk -pmin=$pmin -pmax=$pmax -kmax=$kmax -custom_stf=$custom_stf -rupture_list=$rupture_list -target_mw=$target_mw -max_slip_rule=$max_slip_rule -stf_falloff_rate=$stf_falloff_rate -hot_start=$hot_start -home=$HOMEPATH -project_name=$PROJNAME -run_name=$run_name -moho_depth_in_km=$moho_depth_in_km -hf_dt=$hf_dt -duration=$duration -pwave=$pwave -zero_phase=$zero_phase -order=$order -fcorner=$fcorner -inpolygon_fault=$inpolygon_fault -inpolygon_hypocenter=$inpolygon_hypocenter -high_stress_depth=$high_stress_depth -stress_parameter=$stress_parameter


fi


# make dir to contain the output
cd ~
mkdir preparedoutput$runnum		# I think this line is not needed

# If G matrices weren't premade,  and made during this job, transfer out
if  [ "$mseedsmade" = "0" ]; then

    # Move the .mseed matrices to the preparedoutput
    cd $HOMEPATH/$PROJNAME/GFs/matrices
    

    # Compress & mv the .mseeds home to be transferred out via the stash
    mkdir mseeds
    mv *.mseed mseeds
    tar -czf mseeds.tar.gz mseeds
    mv mseeds.tar.gz ~

    # create a txt file to send to the DAGMan working dir for a way to know that G matrices made
    > GmatricesMade.txt
    echo "G matrices were made." >> GmatricesMade.txt
    echo "Find them your public OSG data directory in prepinput/$preparedinput." >>  GmatricesMade.txt
    mv GmatricesMade.txt ~
fi

# Zip up the waveforms dir into a tarball and move
cd $HOMEPATH/$PROJNAME/output
#tar -czf waveforms.tar.gz waveforms
#mv waveforms.tar.gz ~/preparedoutput$runnum

# actually move the waveform dir home to be compressed
mv waveforms ~

# Zip up the output to sent back to the OSG home dir to be moved
cd ~
tar -czf preparedoutput$runnum.tar.gz waveforms









