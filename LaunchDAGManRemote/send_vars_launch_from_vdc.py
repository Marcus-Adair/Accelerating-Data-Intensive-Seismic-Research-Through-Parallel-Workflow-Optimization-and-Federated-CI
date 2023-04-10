import dag_v2_4_prepare_from_vdc


# The number of rupture bundles to be made. There are 16 ruptures made per bundle. Bundles get split over jobs.
numruptures = "125"

# The input files required to run FakeQuakes
#modfile = "cascadia.mod"
#faultfile = "cascadia_slab2_40km.fault"
#xyzfile = "cas_slab2_dep_02.24.18.xyz"
#mshoutfile = "cascadia_slab2_40km.mshout"
#gflistfile = "cascadia_two.gflist"

modfile = "vel1d_chile.mod"
faultfile = "chile.fault"
xyzfile = "chile.xyz"
mshoutfile = "chile.mshout"
gflistfile = "chile_gnss.gflist"



# Important parameters the user can set when running FakeQuakes
# Chile
utmzone = "19J"
timeepi = "2016-09-07T14:42:26"
targetmw = "8.5,9.2,0.2"
maxslip = "100"
hypocenter = "0.8301,0.01,27.67"

# Important parameters the user can set when running FakeQuakes
# Cascadia
#utmzone = "10T"
#timeepi = "2014-04-01T23:46:47Z"
#targetmw = "8.5,9.2,0.2"
#maxslip = "100"
#hypocenter = "None"



# Launch the python script to prepare things, SSH into OSG, prepare more, and then launch FakeQuakes
dag_v2_4_prepare_from_vdc.main(numruptures, modfile, faultfile, xyzfile, mshoutfile, gflistfile, utmzone, timeepi, targetmw, maxslip, hypocenter)

