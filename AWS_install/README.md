B# AWS_install

This directory contains the scripts for installing software
to run the WRF model on a PW V2 AWS cluster.

## Process

First, start a cloud worker in a POOL based on an exsiting cluster AMI.
Then, run steps 00, 01, 02, 03, and 04 on the cloud worker which will
locally download and install WRF and supporting software.

Second, we need to make portable archives for the spack and miniconda
environments that are built here.  So, for spack, on the cloud worker,
```bash
# Get rid of intermediate files
spack clean --all
# Go to where spack was installed
cd /var/lib/pworks
# Create a single archive file
tar -czvf spack_wrf.tgz ./spack
# Copy archive to a cloud bucket for use in building the head node.
```
Similarly, for miniconda,
```bash
cd /var/lib/pworks
tar -czvf miniconda3.tgz ./miniconda3
# Copy archive to a cloud bucket for distributon to head node image.
```

Third, create an image based on the cloud worker.  This is mostly for
backup purposes, but this image could be used from the compute nodes
in the cluster configuration.

Finally, we create the head node image.  This can be done via an imaging
tool under the `Account` -> `Cloud Snapshot` tab.  When selecting
`New Cloud Snapshot`, the resulting form will prompt the user for
a base image and other information.  The key instructions are in 
`build_head_node_aws.sh`. If for some reason the image building
process does not work, you can run `build_head_node_aws.sh` 
interactively on the head node.

