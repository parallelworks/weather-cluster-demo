#!/bin/bash
#======================
# Build head node image with spack
# and miniconda3 environments.
#
# The local_setup.sh for the workflow will
# activate/setup the spack and miniconda3 environments
# as needed. All we need to do here is stash the files.
# Note that all files are saved in /var/lib/pworks which is
# a persistent space on cloud images.  $HOME, /tmp, and
# some other locations are not always persistent in images
# on all clouds and $HOME changes from user to user.
# Finally, the paths within the spack and miniconda environments
# are consistent with their location in /var/lib/pworks; if these
# particular archives are unpacked in some other location,
# the paths will need to be modified!
#======================

# Install some packages
sudo yum install -y centos-release-scl
sudo yum install -y devtoolset-7
sudo yum install -y wget git git-lfs screen zip unzip bzip2 ksh csh time psmisc gcc cmake ImageMagick gdal-python libgeotiff-devel libtiff-devel wgrib wgrib2 python39-setuptools python39-devel python34-pip nco wgrib wgr\
ib2 ncview lapack-devel blas-devel pip awscli gcc glibc glibc-common gcc-c++ kernel-devel gc gcc++ gcc-c++ nco wgrib wgrib2 ncview bc nc jq libXScrnSaver alsa-lib xorg-x11-server-Xorg  gtk+-devel gtk2-devel

# Make  the staging ground
export STAGING_DIR=/var/lib/pworks
sudo mkdir -p $STAGING_DIR
sudo chmod a+rwx $STAGING_DIR
cd $STAGING_DIR

echo Download the tarballs...
wget  https://www2.mmm.ucar.edu/wrf/OnLineTutorial/wrf_cloud/wrf_simulation_CONUS12km.tar.gz
wget https://storage.googleapis.com/wrf_weather_cluster_demo/spack_gce_wrf.tgz
wget https://storage.googleapis.com/wrf_weather_cluster_demo/miniconda3.tgz

# Unpack the largest tarballs
# (The model boundary conditions is relatively small
# and needs to end up in $HOME, which is not persistent
# so keep it in its archive.)
echo Unpacking spack...
tar -xzf spack_gce_wrf.tgz
echo Unpacking miniconda...
tar -xzf miniconda3.tgz

# Double check that everyone has permissions
# to the contents of the staging dir
echo Changing permissions...
sudo chmod --recursive a+rwx $STAGING_DIR

echo Final clean up...
cd $STAGING_DIR
rm -f miniconda3.tgz spack*.tgz

echo Done.
