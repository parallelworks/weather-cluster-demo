#! /bin/bash
#=======================
# Start up several nodes
# and keep them running
# (i.e. a warm cluster)
# so they are ready for
# a job.
#======================

# Set the number of workers
# to warm up and warm up time
n_warm_workers=8
warm_time=99

# Broadcast to workers and run
# https://slurm.schedmd.com/srun.html
#srun --bcast=/home/sfgary -N${n_warm_workers} node_commands.tmp

srun -N${n_warm_workers} hostname
srun -N${n_warm_workers} sleep $warm_time

echo Done with warm_up_cluster
