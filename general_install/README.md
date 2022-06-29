# weather-cluster-demo/genaral_install

PW V2 cloud clusters are designed to autoprovision/setup the
network fabric necessary for MPI on clusters.  This means that
users shouldn't need to define cloud-specific MPI environment
variables in sbatch scripts.  Also, the same, general software
stack should be able run on each cloud.

The `build_node_image.sh` script here should be able to build
WRF spack archives that work on AWS, GCE, and Azure.  **This has
yet to be tested fully.**

