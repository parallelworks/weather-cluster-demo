#!/bin/bash
#==============================
# Download the model config and
# boundary conditions
#==============================

# Download
cd /var/lib/pworks
curl -O https://www2.mmm.ucar.edu/wrf/OnLineTutorial/wrf_cloud/wrf_simulation_CONUS12km.tar.gz
tar -xzf wrf_simulation_CONUS12km.tar.gz
rm -f wrf_simulation_CONUS12km.tar.gz

# The decompression step above put the
# files in /var/lib/pworks/conus_12km
chmod --recursive a+rwx conus_12km
