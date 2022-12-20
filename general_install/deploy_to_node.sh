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

sudo yum install -y centos-release-scl
sudo yum install -y devtoolset-7

#==============================
echo Setting up SPACK_ROOT...
#==============================

export SPACK_ROOT=${install_dir}/spack
sudo mkdir -p $SPACK_ROOT
sudo chmod --recursive a+rwx ${install_dir}

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

pip3 install botocore==1.23.46 boto3==1.20.46

#==============================
echo Set up Spack...
#==============================
# spack install -j nproc is set to -j 30
# because 30 CPU is the typical minimum
# amount of CPU for high-speed networking
# instance types.
echo 'source ~/.bashrc; \
spack compiler find; \
spack load intel-oneapi-compilers; \
spack compiler find; \
spack unload; ' | scl enable devtoolset-7 bash

#==============================
echo Set permissions...
#==============================
sudo chmod --recursive a+rwx $install_dir

echo Completed deploying to cluster
