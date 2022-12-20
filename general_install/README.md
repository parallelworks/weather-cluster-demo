# weather-cluster-demo/genaral_install

## Motivation

PW V2 cloud clusters are designed to autoprovision/setup the
network fabric necessary for MPI on clusters.  This means that
users shouldn't need to define cloud-specific MPI environment
variables in sbatch scripts.  Also, the same, general software
stack should be able run on each cloud while automatically
leveraging the high speed network fabric available for that
particular cloud.

The `build_node_image.sh` script here should be able to build
WRF spack archives that work on AWS, GCE, and Azure.  **This has
yet to be tested fully.**

## Usage

Please note that there is one key **HARD-CODED** parameter in
this script: `install_dir`. This directory is the base location
where software (i.e. the Spack-stack) and data (i.e. the
boundary conditions of the weather model). are stored. Normally,
this variable would be a command-line input to the script
(e.g. `$1`).  However, in this case, since users may copy and
paste `build_node_image.sh` into the PW Cloud Snapshot tool,
and there is currently no way to specify options on the CLI when
launching the script, this key parameter is set in the script. 
Below are suggestions for values for `install_dir` based on the
computational context.

### Building/running the weather model "live" on a cloud cluster

This case is for when a user starts a cluster and wants to install
the weather model on the cluster "live" as it is already running.
In this case, we are not saving the software in an image - rather,
all the software must install in a place that all nodes (head and
workers) have access to.  On PW cloud clusters, this is generally
somewhere in the user's `$HOME` or, if enabled, `/lustre` or
`/contrib`. For installing on an on-premise system or persistent
cloud storage, `install_dir` *could* be set to 
something like `/scratch` or `/shared` or `$HOME`, depending on
the exact configuration of the on-premise cluster or persistent
cloud storage.

### Building a cloud image for fast redeployment

In this case, the user would like to install the software and save
it as part of a virtual machine disk image that can be available
whenever the cluster is started. This has the disadvantage of a
slight increase in cloud storage costs (the image will be several
GB bigger) but there is a substantial decrease in the time necessary
for the running cluster to be ready to launch the model because the
software and data are already pre-cached on the image. This
particular case is for use with the PW Cloud Snapshot tool. In
this case, it is recommended that `install_dir` be set to
`/var/lib/pworks`. Other paths may work as well but users
**must avoid** `$HOME`, `/tmp`, and any shared space (e.g.
`/shared`, `/contrib`, or `/lustre`) since none of those
locations are stored with the image so any changes in those locations
will **not** be stored in the image.

## Troubleshooting

### GCE

To check if Google gVNIC is running, try:
```
sudo lshw -class network
```
And compare the output to the [example here](https://cloud.google.com/compute/docs/networking/using-gvnic).

Depending on the [version of IntelMPI](https://cloud.google.com/architecture/best-practices-for-using-mpi-on-compute-engine#use_intel_mpi) 
that is installed, the `I_MPI_FABRICS` environment 
variable needs to be set to either `shm:tcp` (for 2018 
and earlier IntelMPI) or  `ofi_rxm;tcp` (for 2019 and 
newer IntelMPI).  The software install script `build_node_image.sh`
does NOT set this since it is designed to be universal
across all clouds and this would impact AWS/Azure configs,
below.  Instead, this environment variable is set in the 
weather model launch script. Note that `build_node_image.sh`
pins IntelMPI to a 2022 version, so we need to use 
`I_MPI_FABRICS=ofi_rxm;tcp` when launching jobs.

### AWS

Notes about EFA here.

### Azure

Notes about Infiniband here.

