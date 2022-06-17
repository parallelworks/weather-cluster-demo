#!/bin/bash
#========================
# Need to grab data from
# a worker node's image
# (the head node image
# is always the bare bones)
#========================

cd $HOME

cat <<EOF > srun_setup_script.sh
#!/bin/bash
echo 'source ~/.bashrc; rsync -av /var/lib/pworks/conus_12km $HOME/; cd $HOME/conus_12km/; spack loca\
tion -i wrf%intel | xargs -I@ sh -c "ln -s @/test/em_real/* ."' | scl enable devtoolset-7 bash   

EOF

chmod u+x srun_setup_script.sh
srun -n 1 srun_setup_script.sh
rm -f srun_setup_script.sh

# As noted by Smith et al. (2020):
# "Please be aware there is a namelist.input in the current 
# directory that you do not want to overwrite. The link command 
# will return the following error, which is safe to ignore. 
# ln: failed to create symbolic link ‘./namelist.input’: File exists
