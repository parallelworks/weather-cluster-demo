#!/bin/bash
#==============================
# General build script for WRF in spack
# This takes about ~2 hours to run
# (including time for the cloud provider
# to register the image).
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
# on CentOS7
#sudo yum install -y centos-release-scl
#sudo yum install -y devtoolset-7

gcc_version="11"
gcc_version_full="11.2.1"

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
echo Downloading spack...
#==============================

# Used 0.18.0 for a while.
# Upgrade to 0.22.2 now.
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
pip3 install boto3
pip3 install botocore

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
echo Installing spack packages...
#==============================
# spack install -j nproc is set to -j 30
# because 30 CPU is the typical minimum
# amount of CPU for high-speed networking
# instance types.
#==========================================
# Older approach with using devtoolset on
# CentOS7. Note change from %intel to %oneapi
# below.
#echo 'source ~/.bashrc; \
#spack compiler find; \
#spack install -j 30 patchelf; \
#spack install -j 30 intel-oneapi-compilers; \
#spack load intel-oneapi-compilers; \
#spack compiler find; \
#spack unload; \
#spack install -j 30 intel-oneapi-mpi%intel; \
#spack install -j 30 wrf@4.3.3%intel build_type=dm+sm ^intel-oneapi-mpi; ' | scl enable devtoolset-7 bash
#==========================================
# New approach:
# CentOS7
#source /opt/rh/devtoolset-${gcc_version}/enable
# Rocky8
#
# Spack packages https://packages.spack.io/package.html?name=wrf
# notes that wrf@4.3 is not compatible with %oneapi. Update
# to newest WRF listed in spack@0.22.2 `spack info wrf`,
# which is wrf@4.5.1.
source /opt/rh/gcc-toolset-${gcc_version}/enable
spack compiler find
spack install -j 30 patchelf%gcc@${gcc_version_full}
spack install -j 30 intel-oneapi-compilers
spack load intel-oneapi-compilers
spack compiler find
spack unload
spack install -j 30 intel-oneapi-mpi%oneapi
spack install -j 30 wrf@4.5.1%oneapi build_type=dm+sm +pnetcdf ^intel-oneapi-mpi

#==============================
echo Cache a copy of model data...
#==============================
cd $install_dir
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/wrf_cloud/wrf_simulation_CONUS12km.tar.gz
tar -xzf wrf_simulation_CONUS12km.tar.gz
rm -f wrf_simulation_CONUS12km.tar.gz

#==============================
echo Install local Miniconda...
#==============================
miniconda_loc=${install_dir}/miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-x86_64.sh
chmod u+x Miniconda3-py39_4.9.2-Linux-x86_64.sh
./Miniconda3-py39_4.9.2-Linux-x86_64.sh -b -p $miniconda_loc
rm -f Miniconda3-py39_4.9.2-Linux-x86_64.sh

# (Do not run conda init as part of install)
source ${miniconda_loc}/etc/profile.d/conda.sh
conda create -y --name parsl_py39
conda activate parsl_py39

# Install Pyferret first because its installer
# searches only for a Python version x.x and
# breaks when Pyton is 3.10 or more because it
# thinks the system is at Python 3.1.
#conda install -y -c conda-forge pyferret
#conda install -y -c conda-forge parsl
conda install -y requests
conda install -y ipykernel
conda install -y -c anaconda jinja2

#==============================
echo Set permissions...
#==============================
sudo chmod --recursive a+rwx $install_dir

echo Completed setting up WRF

