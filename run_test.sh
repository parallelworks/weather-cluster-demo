#!/bin/bash
#=============================
# Run forecast for c5n.9xlarge
# instances (need to set number
# of tasks per node).
#============================

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
# 2. We do not need to module load libfabric-aws since the node
#    is able to run fi_info by default.

cd $HOME/conus_12km/

cat <<EOF > srun_forecast.sh
#!/bin/bash
echo 'source ~/.bashrc; spack load intel-oneapi-compilers; spack compiler find; spack unload; export I_MPI_OFI_LIBRARY_INTERNAL=0; spack load intel-oneapi-mpi; spack load wrf; set -x; ulimit -s unlimited; ulimit -a; export OMP_NUM_THREADS=6; export FI_PROVIDER=efa; export I_MPI_FABRICS=ofi; export I_MPI_OFI_PROVIDER=efa; export I_MPI_PIN_DOMAIN=omp; export KMP_AFFINITY=compact; export I_MPI_DEBUG=4; spack location -i wrf | xargs -I@ mpiexec.hydra -np \$SLURM_NTASKS --ppn \$SLURM_NTASKS_PER_NODE @/run/wrf.exe' | scl enable devtoolset-7 bash

EOF

chmod u+x srun_forecast.sh

# Run it!
# Use srun instead of sbatch because execution halts
# locally "here" and we'll know when it is done.
srun --job-name=WRF --output=conus-%j.out --exclusive --nodes=11 --ntasks-per-node=3 srun_forecast.sh

# Clean up
#rm -f srun_forecast.sh
