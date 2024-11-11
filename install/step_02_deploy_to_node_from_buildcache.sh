#!/bin/bash
#==============================
# System setup script to use an
# existing Spack stack. These 
# commands are basically the same
# as the start of build_node_image.sh.
#
# Please see README.md for how how/why
# to use install_dir, below.
#==============================

install_dir=${HOME}/wrf
#install_dir=/var/lib/pworks

#==============================
echo Install newer version of gcc...
#==============================

# Older approach is limited to gcc 7
# on CentOS 7
#sudo yum install -y centos-release-scl
#sudo yum install -y devtoolset-7

gcc_version="11"
gcc_version_full="11.2.1"
oneapi_version="2024.1.0"
oneapi_mpi_version="2021.12.1"

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

export SPACK_ROOT=${install_dir}/spack
sudo mkdir -p $SPACK_ROOT
sudo chmod --recursive a+rwx ${install_dir}

#==============================
echo Set permissions...
#==============================
sudo chmod --recursive a+rwx $install_dir

#==============================
echo Downloading spack...
#==============================

git clone -b v0.22.2 -c feature.manyFiles=true https://github.com/spack/spack $SPACK_ROOT

#==============================
echo Set up Spack environment...
#==============================

# An alternative for local testing is $HOME/.bashrc
# Here, this is added to /etc/bashrc so it is persistent
# in the image and $HOME/.bashrc sources /etc/bashrc.
sudo -s eval echo export SPACK_ROOT=${SPACK_ROOT}" >> "/etc/bashrc
sudo -s eval echo source ${SPACK_ROOT}/share/spack/setup-env.sh" >> "/etc/bashrc
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
#
# Spack packages https://packages.spack.io/package.html?name=wrf
# notes that wrf@4.3 is not compatible with %oneapi. Update
# to newest WRF listed in spack@0.22.2 `spack info wrf`,
# which is wrf@4.5.1.
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
source ./step_03_add_buildcache.sh
# For example, I tried to only run `spack install wrf` after
# the setup lines above, and while the environment concretized,
# it still attempted to build from scratch. So there is something
# about how the Spack hash that is defined when the packages
# are compiled that needs to be sorted out/generalized so
# that we can use the app with the OneAPI-runtime and without
# the compiler install.
spack compiler find
spack install -j 2 --no-check-signature patchelf%gcc@${gcc_version_full}
spack install -j 2 --no-check-signature intel-oneapi-compilers@${oneapi_version}
spack load intel-oneapi-compilers
spack compiler find
spack unload
spack install -j 2 --no-check-signature intel-oneapi-mpi@${oneapi_mpi_version}%oneapi
spack install -j 2 --no-check-signature wrf@4.5.1%oneapi build_type=dm+sm +pnetcdf ^intel-oneapi-mpi

# This does not work by itself without attempting
# to rebuild everything from scratch.
#spack install -j 2 --no-check-signature wrf@4.5.1

#==============================
echo Download WRF 12km CONUS config...
#==============================

pushd $install_dir
curl -O https://www2.mmm.ucar.edu/wrf/OnLineTutorial/wrf_cloud/wrf_simulation_CONUS12km.tar.gz
tar -xzf wrf_simulation_CONUS12km.tar.gz
popd

#==============================
echo Make links in model data...
#==============================
# This is the only step in local_setup.sh
# not already done in the Spack stack
# or here. Note that "wrf%intel" needs
# to be relaxed to simply "wrf" because
# of the potential for using oneapi,
# intel, or another compiler.
cd $install_dir
cd conus_12km
spack location -i wrf | xargs -I@ sh -c "ln -s @/test/em_real/* ."

echo Completed deploying to cluster
