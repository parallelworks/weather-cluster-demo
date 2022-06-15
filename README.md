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

Here are the details for installing the software necessary for
running the WRF model.  This software is installed locally on
the image and will be saved into a new image.


