#!/bin/bash
#========================
# The spack compiler lines are
# also needed to setup the location
# of gcc and intel compilers in
# $HOME/.spack.  Since this
# setup is on $HOME, it only
# needs to be done once and
# it applies to the other
# worker nodes on the cluster.
#========================

# AV: Commenting this out to run from wherever the repo is being launched. Use workflow to specify this location.
#cd $HOME

#==========================
# Old version
#==========================
#cat <<EOF > srun_setup_script.sh
#!/bin/bash
#echo 'source ~/.bashrc; \
#rsync -av /var/lib/pworks/conus_12km $HOME/; \
#cd $HOME/conus_12km/; \
#spack compiler find; \
#spack load intel-oneapi-compilers; \
#spack compiler find; \
#spack unload; \
#spack location -i wrf%intel | xargs -I@ sh -c "ln -s @/test/em_real/* ."' | scl enable devtoolset-7 bash
#
#EOF

#chmod u+x srun_setup_script.sh
#srun -n 1 srun_setup_script.sh
#rm -f srun_setup_script.sh

#===========================
if [ -d "/opt/rh/devtoolset-8" ]
then
    echo "Running atNorth."
    # AV: Commenting this out to run from wherever the repo is being launched. Use workflow to specify this location.
    # cd /shared/wrf/
    echo Unpacking model data...
    # AV: Modifying this to run from wherever the repo is being launched. Use workflow to specify this location.
    #tar -xzf wrf_simulation_CONUS12km.tar.gz
    tar -xzf /shared/wrf/wrf_simulation_CONUS12km.tar.gz

    # Already done since $HOME is persistent
    #echo Setting up spack...
    #echo "export SPACK_ROOT=/shared/wrf/spack" >> ~/.bashrc
    #echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> ~/.bashrc
    source ~/.bashrc
else
    echo "Running on AWS|GCE|Azure."
    echo Unpacking model data...
    cp /var/lib/pworks/wrf_simulation_CONUS12km.tar.gz ./
    tar -xzf wrf_simulation_CONUS12km.tar.gz
    rm -f wrf_simulation_CONUS12km.tar.gz

    echo Setting up spack...
    echo "export SPACK_ROOT=/var/lib/pworks/spack" >> ~/.bashrc
    echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> ~/.bashrc
fi
chmod --recursive a+rwx conus_12km
source ~/.bashrc

#=========================
# Load compilers
#=========================
if [ -d "/opt/rh/devtoolset-8" ]
then
    # This is not necessary atNorth since $HOME is persistent.
    # (Done once and does not need to be repeated.  It does need to
    # be repeated for the worker nodes, their $HOME are separate
    # and also persistent.) Repeating it here does not have
    # any impact.
    echo 'spack compiler find; spack load intel-oneapi-compilers; spack compiler find; spack unload;' | scl enable devtoolset-8 bash
else
    echo 'spack compiler find; spack load intel-oneapi-compilers; spack compiler find; spack unload;' | scl enable devtoolset-7 bash
fi

#=========================
# Make links within run dir
#=========================
cd conus_12km/
spack location -i wrf%intel | xargs -I@ sh -c "ln -s @/test/em_real/* ."

# As noted by Smith et al. (2020):
# "Please be aware there is a namelist.input in the current
# directory that you do not want to overwrite. The link command
# will return the following error, which is safe to ignore.
# ln: failed to create symbolic link ‘./namelist.input’: File exists
