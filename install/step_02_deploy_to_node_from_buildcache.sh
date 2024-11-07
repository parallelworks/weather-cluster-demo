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
echo Downloading spack...
#==============================

git clone -b v0.18.0 -c feature.manyFiles=true https://github.com/spack/spack $SPACK_ROOT

#==============================
echo Configuring external packages...
#==============================

spack_packages=${SPACK_ROOT}/etc/spack/packages.yaml
echo "packages:" > $spack_packages
echo "    all:" >> $spack_packages
echo "        target: ['x86_64']" >> $spack_packages
echo "    gcc:" >> $spack_packages
echo "        externals:" >> $spack_packages
echo "        - spec: gcc@7.3.1" >> $spack_packages
echo "          prefix: /opt/rh/devtoolset-7/root/usr" >> $spack_packages
echo "        buildable: False" >> $spack_packages
echo "    slurm:" >> $spack_packages
echo "        variants: +pmix sysconfdir=/mnt/shared/etc/slurm" >> $spack_packages
echo "        externals:" >> $spack_packages
echo "        - spec: slurm@20.02.7 +pmix sysconfdir=/mnt/shared/etc/slurm" >> $spack_packages
echo "          prefix: /usr" >> $spack_packages
echo "        buildable: False" >> $spack_packages

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
echo Adding mirror with buildcache...
#==============================
./step_03_add_buildcache.sh

#==============================
echo Set up Spack...
#==============================
# spack install -j nproc is set to -j 30
# because 30 CPU is the typical minimum
# amount of CPU for high-speed networking
# instance types.
echo 'source ~/.bashrc; \
spack compiler find; \
spack install -j 30 --no-check-signature patchelf; \
spack install -j 30 --no-check-signature intel-oneapi-compilers@2022.1.0; \
spack load intel-oneapi-compilers; \
spack compiler find; \
spack unload; \
spack install -j 30 --no-check-signature intel-oneapi-mpi%intel; \
spack install -j 30 --no-check-signature wrf@4.3.3%intel build_type=dm+sm ^intel-oneapi-mpi; ' | scl enable devtoolset-7 bash

#==============================
echo Set permissions...
#==============================
sudo chmod --recursive a+rwx $install_dir

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
# or here.
cd $install_dir
cd conus_12km
spack location -i wrf%intel | xargs -I@ sh -c "ln -s @/test/em_real/* ."

echo Completed deploying to cluster
