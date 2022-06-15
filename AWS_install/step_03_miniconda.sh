#!/bin/bash
#===============================
# Install local Miniconda
#===============================

cd /var/lib/pworks

wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-x86_64.sh
chmod u+x Miniconda3-py39_4.9.2-Linux-x86_64.sh
./Miniconda3-py39_4.9.2-Linux-x86_64.sh

# Follow manual prompts (license, install location)
# (set install location to /var/lib/pworks/miniconda3)
# (do not run conda init as part of install)
source miniconda3/etc/profile.d/conda.sh
conda create --name parsl_py39
conda activate parsl_py39

# Install Pyferret first because its installer
# searches only for a Python version x.x and
# breaks when Pyton is 3.10 or more because it
# thinks the system is at Python 3.1.
conda install -y -c conda-forge pyferret
conda install -y -c conda-forge parsl
conda install -y requests
conda install -y ipykernel
conda install -y -c anaconda jinja2
