#!/bin/bash
#==========================
# Push Spack installation
# to buildcache.
#
# This script assumes that
# Spack is already installed
# and $SPACK_ROOT is defined.
#==========================

# The _name is used by Spack.
# The _uri corresponds to the bucket
# identifier available on the PW CLI
# or a local path on the filesystem.
install_dir=${HOME}/wrf
export SPACK_ROOT=${install_dir}/spack
export SPACK_BUILDCACHE_NAME="wrf-cache"
export SPACK_BUILDCACHE_URI=$1

# Use the PW CLI to get the bucket credentials
# and the $BUCKET_URI, used to set up the
# buildcache below. If it is a local
# system path no additional step is needed.
# The credential gathering needs to be done
# at run time since the credentials are short
# term (valid for a few hours) while build
# times can be much longer than this window.
if [[ $SPACK_BUILDCACHE_URI == "pw://"* ]]; then
    echo Getting bucket credentials from PW CLI for buildcache...
    eval `pw buckets get-token ${SPACK_BUILDCACHE_URI}`
else
    echo Assuming buildcache is mounted on local filesystem.
fi

# "Start" Spack
source ${SPACK_ROOT}/share/spack/setup-env.sh

echo Assuming that buildcache is already added...

# For each installed package, push to cache
for ii in $(spack find --format "yyy {version} /{hash}" |
            grep -v -E "^(develop^master)" |
            grep "yyy" |
            cut -f3 -d" ")
do
  echo Working on $ii
  # Need to include --mirror-name before ${SPACK_BUILDCACHE_NAME} 
  # for older versions of Spack (v0.18)
  spack buildcache create -af --only=package --unsigned ${SPACK_BUILDCACHE_NAME} $ii
done

# After a push, you need to:
# This line applies to newer versions of Spack (v.20+?)
# where you can reference the buildcache by it's Spack name.
#
spack buildcache update-index ${SPACK_BUILDCACHE_NAME}
#
# For older versions of Spack, you need to use the URL:
#
#spack buildcache update-index --mirror-url $BUCKET_URI

# Also need to push OneAPI? I'm not 100% certain
# these steps are necessary since they are present in my bucket
# but not when I run "spack buildcache list". Actually,
# for older versions of OneAPI, you could send them to the
# buildcache. For v2024 at least, however, now only the runtime
# is sent to the cache and if you try to send the whole compiler,
# nothing gets pushed. So comment out these lines since they
# don't do anything.
#oneapi_spack_hash=`spack find --format "yyy {version} /{hash}" intel-oneapi-compilers | cut -f3 -d" "`
#spack buildcache create -af --only=package --unsigned ${SPACK_BUILDCACHE_NAME} ${oneapi_spack_hash}
#spack buildcache update-index $BUCKET_URI

#patchelf_spack_hash=`spack find --format "yyy {version} /{hash}" patchelf | cut -f3 -d" "`
#spack buildcache create -af --only=package --unsigned --mirror-name ${SPACK_BUILDCACHE_NAME} ${patchelf_spack_hash}
#spack buildcache update-index --mirror-url $BUCKET_URI

