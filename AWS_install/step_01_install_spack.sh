#!/bin/bash
#===============================
# Install Spack, based on step
# d in Smith et al. (2020):
# https://weather.hpcworkshops.com/02-cluster/04-install-spack.html
#===============================

# We want to save installed software in a persistent place
echo Setting up SPACK_ROOT...
export SPACK_ROOT=/var/lib/pworks/spack
sudo mkdir -p $SPACK_ROOT
sudo chmod a+rwx $SPACK_ROOT

echo Downloading Spack...
git clone -b v0.18.0 -c feature.manyFiles=true https://github.com/spack/spack $SPACK_ROOT

echo Set up Spack environment...
# An alternative for local testing is $HOME/.bashrc
# Here, this is added to /etc/bashrc so it is persistent
# in the image and $HOME/.bashrc sources /etc/bashrc.
sudo echo "export SPACK_ROOT="${SPACK_ROOT} >> /etc/bashrc
sudo echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> /etc/bashrc
source $HOME/.bashrc

echo Install some dependencies...
pip3 install botocore==1.23.46 boto3==1.20.46

#echo Adding mirror and GPG keys...
#spack mirror add aws-hpc-weather s3://aws-hpc-weather/spack/
#spack buildcache keys --install --trust --force

# The packages here differ slightly from the ones listed
# in Smith et al. (2020) because they are using a slightly
# newer base image for their AWS PCluster.
if [ 1 == 1 ]; then
echo Configuring external packages...
cat <<EOF > $SPACK_ROOT/etc/spack/packages.yaml
packages:
    intel-mpi:
        externals:
        - spec: intel-mpi@2019.5.281
          prefix: /opt/intel/compilers_and_libraries_2019.5.281/linux/mpi/intel64
        buildable: False
    gcc:
        externals:
        - spec: gcc@7.3.1
          prefix: /opt/rh/devtoolset-7/root/usr
        buildable: False
    libfabric:
        variants: fabrics=efa,tcp,udp,sockets,verbs,shm,mrail,rxd,rxm
        externals:
        - spec: libfabric@1.14.0 fabrics=efa,tcp,udp,sockets,verbs,shm,mrail,rxd,rxm
          prefix: /opt/amazon/efa
        buildable: False
    openmpi:
        variants: fabrics=auto +legacylaunchers schedulers=slurm
        externals:
        - spec: openmpi@4.1.2 fabrics=auto +legacylaunchers schedulers=slurm
          prefix: /opt/amazon/openmpi
    pmix:
        externals:
          - spec: pmix@3.2.3 ~pmi_backwards_compatibility
            prefix: /opt/amazon/openmpi
    slurm:
        variants: +pmix sysconfdir=/mnt/shared/etc/slurm
        externals:
        - spec: slurm@20.02.7 +pmix sysconfdir=/mnt/shared/etc/slurm
          prefix: /usr
        buildable: False
EOF

fi

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
