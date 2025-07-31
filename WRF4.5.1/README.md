# weather-cluster-demo

Run a medium-sized weather forecast on a cluster.  This workflow is
similar to
[weather-forecast-demo](https://github.com/parallelworks/weather-forecast-demo)
except that this workflow runs a larger weather model across multiple
nodes in a cluster instead of a small forecast on a single node (~192 CPUs).

This demo is based on the [AWS Weather Workshop](https://catalog.workshops.aws/nwp-on-aws/en-US) 
[old link](https://weather.hpcworkshops.com/)
instructions for a CONUS-scale WRF model
([Smith et al., 2020](https://weather.hpcworkshops.com/authors.html)).
The setup instructions here are tested on Parallel Works (PW) cloud
clusters in multiple cloud service provider environments to compare to the benchmarks
reported by AWS in Smith et al. (2020). Much of this setup could
probably be run on other systems.

## Overview

This WRF demonstration can be run manually (i.e. launching the
scripts in this repository manually from a terminal on a cluster) or
automated via a workflow. The workflow steps are defined in 
`./workflow/workflow.yaml`. Note that this file basically launches
each key script via ssh commands. If this workflow is run on
Parallel Works ACTIVATE, these commands will be run from the job
directory that is created by this workflow in the user workspace
(i.e. `/pw/jobs/<workflow-name>/<job-id>/`) and you can trace the
workflow inputs with `inputs.json` and `inputs.sh` therein.

The workflow runs both installation and launch steps. This
means that every time the workflow runs, it will run Spack
install commands. If WRF is not yet installed and the 
buildcache is empty, the WRF software stack will be built
from scratch (2 hours). If the buildcache is not empty, Spack will pull
relevant artefacts to build the compute environment for WRF
(~5-10 mins). Finally, if WRF is already deployed on the
cluster, the Spack install commands basically just verify
that each package in the WRF software stack is installed 
(~2mins). You could speed up this workflow by bypassing 
this step if you are prepared to assume that WRF is installed.

## Installation

Installation instructions for installing WRF on the cluster are in `install`.

The setup script in `install/deploy_to_node_from_buildcache.sh` is designed to be run 
on a cloud cluster to first install minimal system dependencies and then deploy
Spack to orchestrate the main build steps for WRF. It can run on AWS, GCE, and 
Azure clusters. If the buildcache is empty, the build step takes about 2 hours.

To reduce build times on other clusters, it is possible to save the Spack build
artefacts in a buildcache. The buildcache can be either an S3 bucket or a local 
path on the file system. Since it is possible to mount CSP buckets and managed 
disks to PW clusters at custom mount points, these additional, persistent storage
options (i.e. buildcaches accessed by local paths on the cluster filessytem) are 
alternatives to using a bucket (i.e. buildcaches accessed by short term tokens
from the PW CLI - this tends to work best with AWS S3 buckets.).

If you already have a buildcache, then `install/deploy_to_node_from_buildcache.sh` 
will automatically use the buildcache as specified in on its command line invocation.
If the `BUILDCACHE_URI` is prefixed with `pw://`, the builder script will attempt to
use the PW CLI to access a shared cloud bucket provisioned by PW ACTIVATE.
You will generally need to authenticate to the PW CLI before 
leveraging this bucket. As an alternative, you can specify a local path on the 
file system.

Finally, `install/push_to_buildcache.sh` provides a template if you want 
to push initial build results from `install/deploy_to_node_from_buildcache.sh` to a 
buildcache. This script currently assumes that you are authenticated to the PW CLI
but you can replace the CLI commands to get bucket credentials with a local path as
well.

Cloud-specific installation scripts (older code written at the first stages 
of this project) are retained within the `install/<location>_install` directories.

## Running WRF

PW clusters autoconfigure the networking fabric necessary for MPI for each cloud 
(EFA for AWS, gVNIC for GCE, IB for Azure) via `I_MPI` environment variables.  Therefore, 
it shouldn't be necessary to specify which networking fabric is necessary for 
each cloud. The `I_MPI_FABRICS` variable in the `run_<cloud>_<instance_type>.sh` 
is explicitly set anyway for debugging and experimentation purposes. Also, sometimes
there are changes to the allowable values of these environment variables (depending on 
the exact version of Intel MPI that is being used) and changes to images.
Currently, the best options for `I_MPI_FABRICS` for each CSP is:
+ AWS:    `efa`
+ Azure:  `ofi_rxm;tcp`
+ Google: `shm:tcp`

The model itself, once installed and the cluster is running, 
runs in two steps:
1. `./install/deploy_to_node_from_buildcache.sh` stages key files to a run directory (in additon to checking for whether the WRF software stack is already installed). THe default uses `$HOME`, but depending on cluster setup, one could use `/lustre` or other options.
2. `run_<cloud>_<worker-instance-type>.sh` - issue the sbatch commands for this cloud/instance-type combination. When the workflow is run, `run_general.sh` is used and it takes additional CLI arguments.

