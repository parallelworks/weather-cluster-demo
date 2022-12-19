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

install_dir=/var/lib/pworks

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
echo Set up Spack environment...
#==============================

# An alternative for local testing is $HOME/.bashrc
# Here, this is added to /etc/bashrc so it is persistent
# in the image and $HOME/.bashrc sources /etc/bashrc.
sudo echo "export SPACK_ROOT="${SPACK_ROOT} >> /etc/bashrc
sudo echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> /etc/bashrc
source $HOME/.bashrc

#==============================
echo Install some dependencies to check download certificates...
#==============================

pip3 install botocore==1.23.46 boto3==1.20.46

#==============================
echo Configuring external packages...
#==============================

spack_packages=${SPACK_ROOT}/etc/spack/packages.yaml
echo "packages:" > $spack_packages
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
echo Installing spack packages...
#==============================
echo 'source ~/.bashrc; \
spack compiler find; \
spack install patchelf; \
spack install intel-oneapi-compilers; \
spack load intel-oneapi-compilers; \
spack compiler find; \
spack unload; \
spack install intel-oneapi-mpi%intel; \
spack install wrf@4.3.3%intel build_type=dm+sm ^intel-oneapi-mpi; ' | scl enable devtoolset-7 bash

#==============================
echo Cache a copy of model data...
#==============================
cd $install_dir
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/wrf_cloud/wrf_simulation_CONUS12km.tar.gz
tar -xzf wrf_simulation_CONUS12km.tar.gz
rm -f wrf_simulation_CONUS12km.tar.gz

#==============================
echo Set permissions...
#==============================
sudo chmod --recursive a+rwx $install_dir

echo Completed building image
# It is essential to have a newline at the end of this file!
