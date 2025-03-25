#!/bin/bash
#========================
# Run post workflow clean 
# up operations
#========================

echo Starting to run clean.sh...

# Go into the run directory
rundir=${1}
cd ${rundir}

echo Working in ${PWD}

# Rename output files
for file in `ls -1 wrfout_*`
do
    mv -v $file ${file}.nc
done

# Create archive bundle
tar -czvf wrfout.tar.gz wrfout_*.nc

# Done
echo Done cleaning up WRF

