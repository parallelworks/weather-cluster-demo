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

# Create temporary run script
cat <<EOF > node_commands.tmp
echo Started $hostname
sleep 99
EOF

chmod a+rwx node_commands.tmp

# Broadcast to workers and run
# https://slurm.schedmd.com/srun.html
srun --bcast=/tmp -N${n_warm_workers} node_commands.tmp

# Clean up
rm -rf node_commands.tmp

echo Done with warm_up_cluster
