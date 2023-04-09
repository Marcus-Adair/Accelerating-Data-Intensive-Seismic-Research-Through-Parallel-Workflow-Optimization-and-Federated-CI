#!/bin/bash
#
# Post script to occur after each individual C job is done
#
#	This moves the output tarball from home and unpacks it to a sorted location

runnum=$1


# Move the waveforms from fakequakes_run$runnum.tar.gz to fakequakes_output_run$runnum
# inside that tarbill will be a dir called waveforms, so move the tarball to the made dir, then unpack

# This will make the dir during the command
mv fakequakes_run$runnum.tar.gz  fakequakes_output_run$runnum
cd fakequakes_output_run$runnum

# unpacks into a dir named waveforms and delete the tarball
tar -xzf fakequakes_run$runnum.tar.gz
rm fakequakes_run$runnum.tar.gz

