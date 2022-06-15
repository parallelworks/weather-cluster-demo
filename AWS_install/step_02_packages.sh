#!/bin/bash
#=======================
# Steps to install the compilers.
# Note that we DO NOT want to use
# the AWS mirror because all the
# packages force you to use Amazon
# Linux.
#========================

# Lists available packages
spack list -d oneAPI

# Required for nearly all packages - will
# apply patches as needed automatically.
spack install patchelf

# Lists installed packages
spack find

# A compiler first needs to be installed
# and then loaded and added.
spack install --no-cache intel-oneapi-compilers@2022.0.2
spack load intel-oneapi-compilers
spack compiler find
spack unload

# Install the Intel-MPI + AWS EFA
spack install --no-cache intel-oneapi-mpi+external-libfabric%intel

# Install WRF packages (takes a WHILE! 42 min for wrf alone)
# -j 18 => run with 18 cores (whatever is available...)
spack install -j 18 wrf@4.3.3%intel build_type=dm+sm ^intel-oneapi-mpi+external-libfabric

# Install NCL for visualization and set
# default NCL window size. This fails
# during compilation of util-linux-uuid.
# Unclear why b/c running:
# spack install util-linux-uuid@2.37.4
# succeeds.
#========================================
#spack install ncl^hdf5@1.8.22
#cat <<EOF > $HOME/.hluresfile
#*windowWorkstationClass*wkWidth  : 1000
#*windowWorkstationClass*wkHeight : 1000
#EOF
#========================================

# Instead of using NCL, let's install Pyferret.
# This is done in step_03 along with installing
# miniconda, ipykernel, parsl, etc. in case we
# want to have other workflow tooling in place.
