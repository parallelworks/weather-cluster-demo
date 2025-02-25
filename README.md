# weather-cluster-demo

Run a medium-sized weather forecast on a cluster.  This workflow is
similar to
[weather-forecast-demo](https://github.com/parallelworks/weather-forecast-demo)
except that this workflow runs a larger weather model across multiple
nodes in a cluster instead of a small forecast on a single node.

This demo is based on the [AWS Weather Workshop](https://catalog.workshops.aws/nwp-on-aws/en-US) 
[old link](https://weather.hpcworkshops.com/)
instructions for a CONUS-scale WRF model
([Smith et al., 2020](https://weather.hpcworkshops.com/authors.html)).
The setup instructions here are specific to Parallel Works (PW) V2 cloud
clusters in multiple cloud environments to compare to the benchmarks
reported by AWS in Smith et al. (2020).

# Installation

Installation instructions for installing WRF on the cluster are in `install`.

The setup script in `install/step_01_build_node_image.sh` is designed to be run 
on a cloud cluster to first install minimal system dependencies and then deploy
Spack to orchestrate the main build steps for WRF. It can run on AWS, GCE, and 
Azure clusters. This first step takes about 2 hours.

To reduce build times on other clusters, it is possible to save the Spack build
artefacts in a buildcache. The buildcache can be either an S3 bucket or a local 
path on the file system. Since it is possible to mount CSP buckets and managed 
disks to PW clusters at custom mount points, these additional, persistent storage
options (i.e. buildcaches accessed by local paths on the cluster filessytem) are 
alternatives to using a bucket (i.e. buildcaches accessed by short term tokens
from the PW CLI - this tends to work best with AWS S3 buckets.).

If you already have a buildcache, then `install/step_02_deploy_to_node_from_buildcache.sh` 
will automatically use the buildcache as specified in `install/step_03_add_buildcache.sh`. 
Note that the current default in `install/step_03_add_buildcache.sh` uses the PW CLI to access 
a shared cloud bucket - you will need to authenticate to the PW CLI before 
leveraging this bucket. As an alternative, you can specify a local path on the 
file system.

Finally, `install/step_04_push_to_buildcache.sh` provides a template if you want 
to push initial build results from `install/step_01_build_node_image.sh` to a 
buildcache. This script currently assumes that you are authenticated to the PW CLI
but you can replace the CLI commands to get bucket credentials with a local path as
well.

Cloud-specific installation scripts (older code written at the first stages 
of this project) are retained within the `install/<location>_install` directories.

# Running WRF

PW clusters autoconfigure the networking fabric necessary for MPI for each cloud 
(e.g. EFA for AWS, gVNIC for GCE) via `I_MPI` environment variables.  Therefore, 
it shouldn't be necessary to specify which networking fabric is necessary for 
each cloud. The `I_MPI_FABRICS` variable in the `run_<cloud>_<instance_type>.sh` 
is explicitly set anyway for debugging and experimentation purposes. Also, sometimes
there are changes to the allowable values of these environment variables (depending on 
the exact version of Intel MPI that is being used).

The model itself, once installed and the cluster is running, 
runs in two steps:
1. `*_setup.sh` - stage key files to a shared space. `local_setup.sh` uses `$HOME`, depending on cluster setup, one could use `/shared` or `/lustre` or `/contrib`.
2. `run_<cloud>_<worker-instance-type>.sh` - issue the sbatch commands for this cloud/instance-type combination.

