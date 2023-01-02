# weather-cluster-demo

Run a medium-sized weather forecast on a cluster.  This workflow is
similar to
[weather-forecast-demo](https://github.com/parallelworks/weather-forecast-demo)
except that this workflow runs a larger weather model across multiple
nodes in a cluster instead of a small forecast on a single node.

This demo is based on the [AWS Weather Workshop](https://weather.hpcworkshops.com/)
instructions for a CONUS-scale WRF model
([Smith et al., 2020](https://weather.hpcworkshops.com/authors.html)).
The setup instructions here are specific to Parallel Works (PW) V2 cloud
clusters in multiple cloud environments to compare to the benchmarks
reported by AWS in Smith et al. (2020).

# Overview

Installation instructions for installing WRF on the cluster are in `install`. The 
PW Cloud Snapshot tool creates cloud head node/workder node images
that have WRF installed.  The list of up-to-date images is currently:
+ AWS:     ami-04f457714fd1e594c
+ GCE:     pw-sfg3-wrf-cluster-demo-04
+ Azure:   pending
+ AtNorth: Clusters are persistent so no need for custom images.

The setup script in `install` is designed to be run in the PW Cloud Snapshot image builder. 
It was designed to generate images that work on AWS, GCE, and Azure clusters.  A user just 
needs to pick which cloud they prefer from the drop-down box.  PW V2 clusters autoconfigure 
the networking fabric necessary for MPI for each cloud (e.g. EFA for AWS, gVNIC for GCE) 
via MPI environment variables.  Therefore, it shouldn't be necessary to specify which 
networking fabric is necessary for each cloud aside from setting the `I_MPI_FABRICS` variable
in the `run_<cloud>_<instance_type>.sh` scripts provided in the top level of this repository.
While this approach works with a medium-sized weather model, further testing is underway to 
ensure that this works over a wide range of MPI applications.

Cloud-specific installation scripts (older code written at the first stages of this project)
are retained within the `install/<location>_install` directories.

The model itself, once installed and the cluster is running, 
runs in two steps:
1. `*_setup.sh` - stage key files to a shared space. `local_setup.sh` uses `$HOME`, depending on cluster setup, one could use `/shared` or `/lustre` or `/contrib`.
2. `run_<cloud>_<worker-instance-type>.sh` - issue the sbatch commands for this cloud/instance-type combination.

*NOTE:* If the custom image for the workflow is not available, `<cloud>_install/build_head_node_<cloud>.sh` can be run before step 1.

# AWS

## Configure cluster

PW cloud clusters are different from AWS' ParallelCluster tool. Below is the
starting configuration of the cluster used here:

```bash
{
"architecture":"amd64",
"availability_zone":"us-east-1b",
"controller_image":"latest",
"controller_net_type":true,
"export_fs_type":"ext4",
"image_disk_count":0,
"image_disk_name":"snap-XXXXXXX",
"image_disk_size_gb":"100",
"management_shape":"c5n.9xlarge",
"partition_config":[
	{
	"architecture":"amd64",
	"availability_zone":"us-east-1b",
	"default":"YES",
	"elastic_image":"latest",
	"enable_spot":false,
	"instance_type":"c5n.9xlarge",
	"max_node_num":"15",
	"name":"compute",
	"net_type":true
	}
],
"region":"us-east-1"
}
```

In the next step, we will build an AMI that will be used for the
worker nodes when we need to recreate the cluster later.  This
allows the user to save time when starting the cluster by
sidestepping the installation of software b/c installed software
will be saved in the AMI.  This custom AMI will be inserted in the
`elastic_image` field.

The `latest` AMI we start with here is also a custom AMI, but it
shares much of the same base software as a standard AWS PCluster,
in particular the installation of the following software used by
Smith et al. (2020):
+ 

The `image_disk_count` and `image_disk_name` items are not used
here.  Broadly, they represent an alternative to storing installed
software in an AMI by storing installed software in an attached
disk mounted at `/apps`.  Note that by default `/apps` on the
cluster is also shared among nodes but this will not be preserved
if an AMI is made or it could be overwritten if a volume is mounted
to `/apps` so we leave it alone for now.  The other shared spaces
(where the head and worker nodes have access) are `/home` and `/mnt/shared`.
We can also install software that each node uses (but doesn't need to
share with other nodes) in /var/lib/pworks.

Finally, we can experiment with different instance types to see
how run times and run costs change (e.g. we start with
`"instance_type":"c5n.9xlarge"` but will move to `hpc6a`).

## Install software

The details for installing the software necessary for
running the WRF model are in `AWS_install`.  This software
is installed locally on the image and will be saved into
a new image.

# GCE and atNorth

The process for GCE and atNorth broadly follow AWS.  Each
has its own `_install` directory with specific details.
