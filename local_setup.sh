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

cd $HOME

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
echo Unpacking model data...
cp /var/lib/pworks/wrf_simulation_CONUS12km.tar.gz ./
tar -xzf wrf_simulation_CONUS12km.tar.gz
rm -f wrf_simulation_CONUS12km.tar.gz
chmod --recursive a+rwx conus_12km

echo Setting up spack...
echo "export SPACK_ROOT=/var/lib/pworks/spack" >> ~/.bashrc
echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> ~/.bashrc
source ~/.bashrc

#=========================
# Load compilers
#=========================
echo 'spack compiler find; spack load intel-oneapi-compilers; spack compiler find; spack unload;' | scl enable devtoolset-7 bash                                                                               

#=========================
# Make links within run dir
#=========================
cd ~/conus_12km/                                                                                                          
spack location -i wrf%intel | xargs -I@ sh -c "ln -s @/test/em_real/* ."

# As noted by Smith et al. (2020):
# "Please be aware there is a namelist.input in the current 
# directory that you do not want to overwrite. The link command 
# will return the following error, which is safe to ignore. 
# ln: failed to create symbolic link ‘./namelist.input’: File exists
