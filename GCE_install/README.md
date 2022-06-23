# GCE_install

This directory contains the scripts for installing software
to run the WRF model on an PW V2 GCE cluster.

The steps for GCE are the same for AWS with minor differences
due to slightly different versions of software preinstalled
on the base image or software availability. See `../AWS_install/README.md`
for more details.  In a nutshell:
1. Use steps_[00 through 04].sh to grab, compile, and install code.
2. Pack up tar archives of the resulting miniconda and spack environments.
3. Deploy those tar archives on custom worker images via the PW `Cloud Snapshot` utility.

