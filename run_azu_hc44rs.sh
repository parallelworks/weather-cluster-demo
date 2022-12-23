#!/bin/bash
#============================
# Run forecast for c2-standard-60
# instances (need to set number
# of tasks per node).
#============================

# Source .bashrc in case local_setup.sh
# was run in an automated way immediately
# before this script (the changes in .bashrc
# from local_setup.sh are sourced in its
# child shell, but not the parent).
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

# AV: Modifying this to run from wherever the repo is being launched. Use workflow to specify this location.
# cd /shared/wrf/conus_12km/
cd conus_12km

# This env var needs to match the version
# of IntelMPI.  For the general_install,
# IntelMPI is 2022, see https://cloud.google.com/architecture/best-practices-for-using-mpi-on-compute-engine#use_intel_mpi
export I_MPI_FABRICS="ofi_rxm;tcp"

cat > slurm-wrf-conus12km.sh <<EOF
#!/bin/bash

#SBATCH --job-name=WRF
#SBATCH --output=conus-%J.%t.out
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=4
#SBATCH --exclusive

spack load intel-oneapi-mpi
spack load wrf
wrf_exe=$(spack location -i wrf)/run/wrf.exe
set -x
ulimit -s unlimited
ulimit -a

export OMP_NUM_THREADS=6
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
rm -f slurm-wrf-conus12km.sh

