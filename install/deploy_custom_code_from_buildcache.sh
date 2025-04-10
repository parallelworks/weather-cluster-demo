#!/bin/bash
#==============================
# System setup script to use an
# existing Spack stack from a
# buildcache. If the buildcache
# is empty, build starts from 
# scratch.
#
# Additionally, this script is a
# template for building an application
# in development mode so custom code
# can be added.
#
# Please see README.md for how how/why
# to use INSTALL_DIR, below.
# A typical invocation can be:
# ./deploy_to_node_from_buildcache /home/${USER}/wrf /spack-cache run01
# The first entry is the root working
# directory, or INSTALL_DIR in this script.
# The second entry is the URI of the Spack
# buildcache (e.g. a local path on filesystem
# or bucket handle pw://... or s3://...)
# The final entry is the run directory for WRF itself.
# This directory will be inside the root working
# directory.
#==============================

#==============================
# CLI parameters from workflow:

export INSTALL_DIR=${1}
export SPACK_ROOT=${INSTALL_DIR}/spack

# The _name is used by Spack.
# The _uri corresponds to the bucket
# identifier available on the PW CLI
# or a path on the local filesystem
# (which could be a mounted bucket/disk/etc.).
export SPACK_BUILDCACHE_NAME="wrf-cache"
export SPACK_BUILDCACHE_URI=${2}

export RUN_DIR=${INSTALL_DIR}/${3}

echo INSTALL_DIR is $INSTALL_DIR
echo RUN_DIR is $RUN_DIR
echo SPACK_ROOT is $SPACK_ROOT
echo SPACK_BUILDCACHE_URI is $SPACK_BUILDCACHE_URI

#==============================
echo Install newer version of gcc...
#==============================

# Older approach is limited to gcc 7
# on CentOS 7
#sudo yum install -y centos-release-scl
#sudo yum install -y devtoolset-7

gcc_version="11"
gcc_version_full="11.2.1"

spack_version="0.23.1"

# WRF 3.9.1.1 may have difficulty to OneAPI?
# so also specify an intel version.
# Tried the following versions of OneAPI:
# 2021.1.2 - oldest available in Spack, still breaks out intel and oneapi
#            Fails with pnetcdf (%intel) and wrf (%oneapi)
# To try: 
# 2023.2.3 - oldest version that still has icc/ifort instead of icx
# https://www.intel.com/content/www/us/en/developer/articles/release-notes/oneapi-c-compiler-release-notes.html
#
# 2024.0.2 - Corresponds to highest version in Spack v0.22.2. Canot use 
# intel-oneapi-compilers-classic OOB because intel-oneapi-compilers
# installs into a "2024.0" directory but *-classic attempts to
# try to find "2024.0.2" which does not exist and fail.
oneapi_version="2023.2.3"

# Most current version for Spack v0.22.2
#oneapi_mpi_version="2021.12.1"

# Most current version for Spack v0.23.1
oneapi_mpi_version="2021.15.0"

# Intel classic attempt
intel_version="2021.11.1"

# Use these for CentOS7
#sudo yum install -y devtoolset-${gcc_version}-gcc
#sudo yum install -y devtoolset-${gcc_version}-gcc-c++
#sudo yum install -y devtoolset-${gcc_version}-gcc-gfortran
#sudo yum install -y devtoolset-${gcc_version}-gdb 

# Use these for Rocky8
sudo yum install -y gcc-toolset-${gcc_version}-gcc
sudo yum install -y gcc-toolset-${gcc_version}-gcc-c++
sudo yum install -y gcc-toolset-${gcc_version}-gcc-gfortran
sudo yum install -y gcc-toolset-${gcc_version}-gdb

#==============================
echo Setting up SPACK_ROOT...
#==============================

# Sudo operations included here in case you
# want to install into the image persistent
# directories (i.e. /var, /opt). But this is
# dropped in favor of a buildcache, so all
# operatoins happen in user space from here on.
#sudo mkdir -p $SPACK_ROOT
#sudo chmod --recursive a+rwx ${INSTALL_DIR}

mkdir -p $SPACK_ROOT
mkdir -p $RUN_DIR

#==============================
echo Downloading spack...
#==============================

git clone -b v${spack_version} -c feature.manyFiles=true https://github.com/spack/spack $SPACK_ROOT

#==============================
echo Set up Spack environment...
#==============================

echo export SPACK_ROOT=${SPACK_ROOT} >> ${HOME}/.bashrc
echo source ${SPACK_ROOT}/share/spack/setup-env.sh >> ${HOME}/.bashrc

# An alternative for local testing is /etc/bashrc
# If you add to /etc/bashrc, it is persistent
# in the image (if there is a snapshot taken) and 
# $HOME/.bashrc sources /etc/bashrc.
#sudo -s eval echo export SPACK_ROOT=${SPACK_ROOT}" >> "/etc/bashrc
#sudo -s eval echo source ${SPACK_ROOT}/share/spack/setup-env.sh" >> "/etc/bashrc

source $HOME/.bashrc

#==============================
echo Install some dependencies to check download certificates...
#==============================

#pip3 install botocore==1.23.46 boto3==1.20.46
pip3 install botocore
pip3 install boto3

#==============================
echo Configuring external packages...
#==============================

# Manually specify gcc version below.
# Checked that subversion .2.1 is the
# same across Rocky8 and CentOS7.

# Slurm version changes depending on image:
# CentOS7
#slurm_version="20.02.7"
# Rocky8
slurm_version="23.11.9"

spack_packages=${SPACK_ROOT}/etc/spack/packages.yaml
echo "packages:" > $spack_packages
echo "    all:" >> $spack_packages
echo "        target: ['x86_64']" >> $spack_packages 
echo "    gcc:" >> $spack_packages
echo "        externals:" >> $spack_packages
echo "        - spec: gcc@${gcc_version_full}" >> $spack_packages
echo "          prefix: /opt/rh/devtoolset-${gcc_version}/root/usr" >> $spack_packages
echo "        buildable: False" >> $spack_packages
echo "    slurm:" >> $spack_packages
echo "        variants: +pmix sysconfdir=/etc/slurm" >> $spack_packages
echo "        externals:" >> $spack_packages
echo "        - spec: slurm@${slurm_version} +pmix sysconfdir=/etc/slurm" >> $spack_packages
echo "          prefix: /usr" >> $spack_packages
echo "        buildable: False" >> $spack_packages

#==============================
echo Set up Spack...
#==============================
# spack install -j nproc is set to -j 30
# because 30 CPU is the typical minimum
# amount of CPU for high-speed networking
# instance types.
#==============================
# Older approach with using devtoolset
# on CentOS7. Note change from %intel to
# %oneapi, below.
#echo 'source ~/.bashrc; \
#spack compiler find; \
#spack install -j 30 --no-check-signature patchelf; \
#spack install -j 30 --no-check-signature intel-oneapi-compilers@2022.1.0; \
#spack load intel-oneapi-compilers; \
#spack compiler find; \
#spack unload; \
#spack install -j 30 --no-check-signature intel-oneapi-mpi%intel; \
#spack install -j 30 --no-check-signature wrf@4.3.3%intel build_type=dm+sm ^intel-oneapi-mpi; ' | scl enable devtoolset-7 bash

#==============================
# New approach:
# CentOS7
#source /opt/rh/devtoolset-${gcc_version}/enable
# Rocky8
source /opt/rh/gcc-toolset-${gcc_version}/enable

#==============================
# Need to specify a long path padding to
# allow for different install locations.
# WORKING HERE:
# If this is 512, Intel OneAPI fails to install
# lz4 is failing to install with any reasonable 
# value of this setting (Spack paths tend to be
# about 100 characters including the hash).
spack config add config:install_tree:padded_length:256

#=============================
echo Adding buildcache...
#============================
# Spack packages https://packages.spack.io/package.html?name=wrf
# notes that wrf@4.3 is not compatible with %oneapi. Update
# to newest WRF listed in spack@0.22.2 `spack info wrf`,
# which is wrf@4.5.1.
# For WRF 3.9.1.1, try intel too.
#
# WORKING HERE - if in a buildcache, may not need
# to install the compiler - just pull the runtime.
# This will speed things up considerably.
# HOWEVER, when you run `spack install wrf%oneapi`, Spack
# treats OneAPI as a dependency and cannot proceed without
# the compiler installed. There's probably a way around
# this using the runtime, but I haven't tried yet (perhaps
# even specifying `wrf ^intel-oneapi-runtime`. It looks like
# compiler runtimes are a new feature (added in spack 0.22)
# and may only work with select compilers (gcc) but not yet
# with OneAPI:
# https://spack-tutorial.readthedocs.io/en/latest/tutorial_binary_cache.html#reuse-of-binaries-from-a-build-cache

# Register the buildcache with Spack by
# first starting Spack and then adding the
# cache.
source ${SPACK_ROOT}/share/spack/setup-env.sh

# If we are using the PW CLI to get the bucket credentials
# and the $BUCKET_URI, run the following commands.
# Otherwise, we assume a local directory on the filesystem.
if [[ $SPACK_BUILDCACHE_URI == "pw://"* ]]; then
    echo Getting bucket credentials from PW CLI for buildcache...
    eval `pw buckets get-token ${SPACK_BUILDCACHE_URI}`
    spack mirror add ${SPACK_BUILDCACHE_NAME} ${BUCKET_URI}
else
    echo Assuming buildcache is mounted on local filesystem...
    spack mirror add ${SPACK_BUILDCACHE_NAME} ${SPACK_BUILDCACHE_URI}
fi

#============================
echo Start Spack build.
#===========================
# For example, I tried to only run `spack install wrf` after
# the setup lines above, and while the environment concretized,
# it still attempted to build from scratch. So there is something
# about how the Spack hash that is defined when the packages
# are compiled that needs to be sorted out/generalized so
# that we can use the app with the OneAPI-runtime and without
# the compiler install.
#
# The build has a short term 48GB RAM peak. Most instances with
# that much memory are in the 8-16 CPU range, so allow for many
# simultaneous jobs.
#
# In the spack devel tutorial, spack compiler find is run
# before setting up the environment:
# https://spack-tutorial.readthedocs.io/en/latest/tutorial_developer_workflows.html
spack compiler find

# spack develop **requires** using an environment
mkdir -p ${SPACK_ROOT}/wrf-dev
cd ${SPACK_ROOT}/wrf-dev
spack env create -d .
sleep 10
spack env activate .
sleep 10

# You must first spack add before running spack install (or spack install --add).
# Let's add-concretize-install the compilers first, then WRF after we find the
# compilers.
spack install --add -j 16 --no-check-signature patchelf%gcc@${gcc_version_full}

# Intel OneAPI (required for Intel Classic)
#spack install --add -j 16 --no-check-signature intel-oneapi-compilers #@${oneapi_version}
#spack load intel-oneapi-compilers #@${oneapi_version}
#spack compiler find
#spack unload

# Intel Classic - does not work OOB with Spack -v 0.22.2, see note above.
# It's possible it does work with v0.22.2 BUT - you shouldn't attempt to install
# intel-oneapi-compilers-classic alongside manually selected intel-oneapi-compilers.
# The *-classic install depdends on a specific version of intel-oneapi-compilers
# (for Spack v0.23.1, this is OneAPI 2023.2.4). Installing *-classic tends to fail
# for opaque reasons if you preinstall other versions of intel-oneapi-compilers!
spack install --add -j 16 --no-check-signature intel-oneapi-compilers-classic #@${intel_version}
spack load intel-oneapi-compilers-classic
spack compiler find
spack unload

# WORKING HERE - Consider removing %intel? - Spack reports
# duplicate paths for libfabric and mpi/lib
spack install --add -j 16 --no-check-signature intel-oneapi-mpi #@${oneapi_mpi_version}%intel #oneapi@${oneapi_version}

# Same strange bug as with WRF4.5 - lz does not install when automated, 
# but installs manually. So:
# 1. run this script until it fails here.
# 2. start a new shell (which will pick up the SPACK_ROOT
#    in ~/.bashrc)
# 3. change to the directory of the Spack env
# 4. spacktivate .
# 5. run the command below manually
# 6. rerun this script as before.
spack install --add -j 16 --no-check-signature lz4@1.9.4%intel #oneapi@${oneapi_version}

echo Add WRF...
#spack add wrf@3.9.1.1%oneapi@${oneapi_version} build_type=dm+sm +pnetcdf ^intel-oneapi-mpi
# Some packages don't compile with Intel Classic, so force use of OneAPI.
spack add wrf@3.9.1.1%intel build_type=dm+sm +pnetcdf ^intel-oneapi-mpi ^diffutils@3.10%oneapi ^gettext@0.22.5%oneapi

echo Run spack develop...
# Instead of right to spack install here, first use spack develop
# Check in spack.yaml for the dev_path for this package.
# Note that spack develop by itself only clones the source code;
# you must add the spec to the environment, too (see step above).
spack develop wrf@3.9.1.1%intel build_type=dm+sm +pnetcdf ^intel-oneapi-mpi ^diffutils@3.10%oneapi ^gettext@0.22.5%oneapi

echo Env concretization...
# Concretize the environment
spack concretize -f

echo First install attempt from src...
# Then, we install the first time (build original package)
spack install -j 16 --no-check-signature

# Make the changes to the code

# Then, we install a second time with the modified code

# This does not work by itself without attempting
# to rebuild everything from scratch.
#spack install -j 2 --no-check-signature wrf@4.5.1

#==============================
echo Download WRF 12km CONUS config...
#==============================
pushd $RUN_DIR
curl -O https://www2.mmm.ucar.edu/wrf/OnLineTutorial/wrf_cloud/wrf_simulation_CONUS12km.tar.gz
curl -O https://www2.mmm.ucar.edu/wrf/OnLineTutorial/wrf_cloud/wrf_simulation_CONUS12km.tar.gz
tar -xzf wrf_simulation_CONUS12km.tar.gz

#==============================
echo Make links in model data...
#==============================
# Note that "wrf%intel" needs
# to be relaxed to simply "wrf" because
# of the potential for using oneapi,
# intel, or another compiler.
pushd conus_12km
spack location -i wrf | xargs -I@ sh -c "ln -s @/test/em_real/* ."
popd
popd

echo Completed deploying to cluster

