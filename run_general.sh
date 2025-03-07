#!/bin/bash
#============================
# Run forecast for a variety of
# node types. Need to set:
# run dir
# number of MPI tasks per node
# number of nodes in request
# 
# There are always 6 OpenMP
# threads being used, so the 
# smallest nodes must have
# at least 6 CPU with 1 MPI
# task/rank per node.
# 
# For larger nodes, work in multiples
# of 6. So for a c2-standard-60, there
# are 30 real CPU (hyperthreading is
# turned off) -> up to 5 MPI tasks/ranks
# can be activated on one node (30 CPU).
#
# But, we always need a total of 
# 32 MPI ranks, so even if we
# pack ranks with 5 ranks/node,
# we won't be able to evenly
# ranks across 7 nodes, so we need
# to use 8 nodes with 4 ranks per node.
#============================

# Key inputs
export RUNDIR=$1
export NUM_NODES=$2
export NUM_MPI_TASK_PER_NODE=$3
export PARTITION=$4

echo Starting general launcher for WRF...
echo RUNDIR is $RUNDIR
echo NUM_NODES is $NUM_NODES
echo NUM_MPI_TASK_PER_NODE is $NUM_MPI_TASK_PER_NODE
echo PARTITION is $PARTITION

# Source .bashrc because this sets up spack.
source ~/.bashrc

# Move data to home with local.setup.sh
# (Not done automatically here in case
#  cluster is persistent.)

# Create launch script
# Modifications wrt version posted by Smith et al. (2020):
# 1. Adjust --nodes and --ntasks-per-node to match number
#    of CPU = vCPU/2 on instance. For example, 2 x 16 = 4 x 8.
#    The number of CPU available should be >= --ntasks-per-node x OMP_NUM_THREADS
#    This particular model needs 2 x 16 x 6 = 4 x 8 x 6 = 192 threads.
#    In the two cases above, 16x6 means 2 quantity 96CPU instances and
#                             8x6 means 4 quantity 48CPU instances.
# 2. We do not need to module load libfabric-aws or any EFA env vars
#    since this is on GCE.  GCE gvnic env vars are autoconfigured.
# 3. Change the output logging from %j to %J.%t

# Go to whereever the WRF run directory is.
cd ${RUNDIR}

# This env var needs to match the version
# of IntelMPI.  For the general_install,
# IntelMPI is 2022, see https://cloud.google.com/architecture/best-practices-for-using-mpi-on-compute-engine#use_intel_mpi
#export I_MPI_FABRICS="ofi_rxm;tcp"
# Newer version of OneAPI? 2021.12.2 - but still get error messages
# experiment with shm:ofi and setting I_MPI_OFI_PROVIDER to TCP?
# See:
# https://www.intel.com/content/www/us/en/docs/mpi-library/developer-reference-linux/2021-8/communication-fabrics-control.html
# https://www.intel.com/content/www/us/en/docs/mpi-library/developer-reference-linux/2021-8/ofi-capable-network-fabrics-control.html
# This variable should already be set by default 
# on Parallel Works cloud clusters based on your CSP.
#export I_MPI_FABRICS="shm:tcp"

cat > slurm-wrf-conus12km.sh <<EOF
#!/bin/bash

#SBATCH --job-name=WRF
#SBATCH --output=conus-%J.%t.out
#SBATCH --nodes=$NUM_NODES
#SBATCH --ntasks-per-node=$NUM_MPI_TASK_PER_NODE
#SBATCH --exclusive
#SBATCH --partition $PARTITION

spack load intel-oneapi-mpi
spack load wrf
wrf_exe=$(spack location -i wrf)/run/wrf.exe
set -x
ulimit -s unlimited
ulimit -a

export OMP_NUM_THREADS=6
export I_MPI_FABRICS=$I_MPI_FABRICS
export I_MPI_PIN_DOMAIN=omp
export KMP_AFFINITY=compact
export I_MPI_DEBUG=6

time mpiexec.hydra -np \$SLURM_NTASKS --ppn \$SLURM_NTASKS_PER_NODE \$wrf_exe
echo $? > wrf.exit.code
EOF

# Run it!
echo; echo "Running sbatch slurm-wrf-conus12km.sh from ${PWD}"
sbatch slurm-wrf-conus12km.sh

# Clean up
#rm -f slurm-wrf-conus12km.sh

