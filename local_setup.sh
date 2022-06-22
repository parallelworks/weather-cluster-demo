#!/bin/bash
#========================
# Need to grab data from
# a worker node's image
# (the head node image
# is always the bare bones)
#
# The spack compiler lines are
# also need to setup the location
# of gcc and intel compilers in
# $HOME/.spack.  Since this
# setup is on $HOME, it only
# needs to be done once and
# it applies to the other
# worker nodes on the cluster.
#========================

cd $HOME

cat <<EOF > srun_setup_script.sh                                                                                                                                                                               
#!/bin/bash                                                                                                                                                                                                    
cp /var/lib/pworks/spack*.tgz ~/
cp /var/lib/pworks/wrf_simulation_CONUS12km.tar.gz ~/
EOF

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

chmod u+x srun_setup_script.sh
srun -n 1 srun_setup_script.sh
rm -f srun_setup_script.sh

#===========================
# Newer version requires unpacking on head node
#=========================== 
cd $HOME
echo Unpacking model data...
mv spack*.tgz /var/lib/pworks/
mv wrf_simulation_CONUS12km.tar.gz /var/lib/pworks/
cd /var/lib/pworks
tar -xzf wrf_simulation_CONUS12km.tar.gz
rm -f wrf_simulation_CONUS12km.tar.gz
chmod --recursive a+rwx conus_12km

echo Unpacking spack...
tar -xzf spack*.tgz
echo "export SPACK_ROOT=/var/lib/pworks/spack" >> ~/.bashrc
echo "source \$SPACK_ROOT/share/spack/setup-env.sh" >> ~/.bashrc
source ~/.bashrc

#==========================
# Head node needs devtools to activate spack
#==========================
sudo yum install centos-release-scl
sudo yum install devtoolset-7

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
