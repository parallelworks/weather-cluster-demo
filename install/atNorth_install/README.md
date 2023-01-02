Using AtNorth is different from AWS, GCE, and Azure
because the clusters are persistent and we don't 
specify custom images. On the other hand, a readily
available /shared space is persistent and can be used 
for storing files.

The steps here are broadly similar to GCE's.
However, some differences:
1. Here we use devtoolset-8 instead of -7 because -8 is 
   preinstalled on the worker nodes. Actually, I also 
   installed -7 on the workers for testing and either one
   works, but spack will now autodetect both compiler versions.
2. I tried to install gcc 7.3.1 into the spack archive
   instead of installing devtoolset-7 or -8 entirely.
   This does not work - there are some packages that
   refuse to compile even if gcc 7.3.1 is installed in
   spack. There may be some system level libraries 
   that are not being taken into account.
3. Since atNorth does not share $HOME, the working 
   directory has to be /shared.  For atNorth, the
   model input data can be prestaged and decompressed
   since /shared is persistent.
4. Spack refuses to find `zlib.h` when compiling `pigz`.
   I'm guessing this has something to do with the different
   hardware detected for Intel and gcc compilers (cascadelake
   and skylake, respectively, IDK why).  So, instead, I
   just compiled zlib and pigz from source locally and
   told spack to use pigz as an external package.
   Normally, you can just `make` in `pigz` and it 
   automatically finds the zlib with `-lz`, but not
   for the Intel compiler in this case.  I had to modify
   the following in the makefile:
CFLAGS=-O3 -Wall -Wextra -Wno-unknown-pragmas -Wcast-qual -I/shared/wrf/zlib-1.2.12/
#CFLAGS=-O3 -Wall -Wextra -Wno-unknown-pragmas -Wcast-qual -I/shared/wrf/spack/opt/spack/linux-centos7-cascadelake/intel-2021.5.0/zlib-1.2.12-qaa4z5qlrybsx6kuw6pq26ybotfowqza/include
#LIBS=-lm -lpthread -L/shared/wrf/spack/opt/spack/linux-centos7-cascadelake/intel-2021.5.0/zlib-1.2.12-qaa4z5qlrybsx6kuw6pq26ybotfowqza -lz
LIBS=-lm -lpthread -L/shared/wrf/zlib-1.2.12/lib/ -lz  
   This is exactly the kind of thing package managers are
   setup to avoid - search for a more elegant solution.
5. It is **essential** to have run `scl enable devtoolset-8 bash`
   before doing any major spack building, even if that building
   is using the intel compiler (which should be in spack?)
   and not gcc.
