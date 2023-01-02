#!/bin/bash
#===============================
# Install Spack, based on step
# d in Smith et al. (2020):
# https://weather.hpcworkshops.com/02-cluster/04-install-spack.html
#===============================

# This particular variant designed to minimize
# the number of system installs and try to keep
# everything in the spack archive.

# We want to save installed software in a persistent place
echo Setting up SPACK_ROOT...
export SPACK_ROOT=/shared/wrf/spack
sudo mkdir -p $SPACK_ROOT
sudo chmod --recursive a+rwx $SPACK_ROOT

echo Downloading Spack...
git clone -b v0.18.0 -c feature.manyFiles=true https://github.com/spack/spack $SPACK_ROOT

echo Set up Spack environment...
# An alternative for local testing is $HOME/.bashrc
# Here, this is added to /etc/bashrc so it is persistent
# in the image and $HOME/.bashrc sources /etc/bashrc.
echo "export SPACK_ROOT="${SPACK_ROOT} >> $HOME/.bashrc
echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> $HOME/.bashrc
source $HOME/.bashrc

echo Install some dependencies...
sudo yum install -y patch
sudo yum install -y lbzip2

# These updates allow spack to check SSL certificates
# on the downloaded packages. Try rebuilding on a 
# platform with pip3 (Centos7 does not by default)
# to make a secure-signed archive.
sudo pip3 install botocore==1.23.46 boto3==1.20.46

#=================================================
# Mirror is suggested by Smith et al. (2020) but
# all files in this mirror assume using Amazon Linux
# and we are using Centos.  The mirror's list overwrites
# the default list, so all installs fail because of the
# OS mismatch. Proceed with default mirror only.
#================================================
#echo Adding mirror and GPG keys...
#spack mirror add aws-hpc-weather s3://aws-hpc-weather/spack/
#spack buildcache keys --install --trust --force

# The packages here differ slightly from the ones listed
# in Smith et al. (2020) because they are using a slightly
# newer base image for their AWS PCluster.
echo Configuring external packages...
cat <<EOF > $SPACK_ROOT/etc/spack/packages.yaml
packages:
    gcc:
        externals:
        - spec: gcc@7.3.1
          prefix: /opt/rh/devtoolset-7/root/usr
        buildable: False
    slurm:
        variants: +pmix sysconfdir=/etc/slurm
        externals:
        - spec: slurm@18.08.8 +pmix sysconfdir=/etc/slurm
          prefix: /usr
        buildable: False
EOF

#================================
# This is the suggestion for 
# a WRF "manual install" from Smith et al. (2020).
# Keep disabled for now.
# An alternative for manual install is:
# https://pratiman-91.github.io/2020/09/01/Installing-WRF-from-scratch-in-an-HPC-using-Intel-Compilers.html
# (but there is no suggestion for AWS EFA)
# WRF in this case is installed in step_02_packages.sh.
#===============================
if [ 1 == 0 ]; then
cat <<EOF > wrf_build.yaml
# This is a Spack Environment file.
#
# It describes a set of packages to be installed, along with
# configuration settings.
spack:
  concretization: together
  packages:
    all:
      compiler: [intel]
      providers:
        mpi: [intel-oneapi-mpi+external-libfabric%intel]
  specs:
  - intel-oneapi-compilers
  - intel-oneapi-mpi+external-libfabric%intel
  - jasper%intel
  - netcdf-c%intel
  - netcdf-fortran%intel
  - parallel-netcdf%intel
  view: true
EOF

spack env create wrf_build wrf_build.yaml
spack env activate wrf_build
spack install -j 16
fi
