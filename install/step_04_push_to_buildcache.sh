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
# The _id corresponds to the bucket
# available on the PW CLI.
export SPACK_BUILDCACHE_NAME="wrf-cache"
export SPACK_BUILDCACHE_ID="pw://sfgary/spackwrf"

# Use the PW CLI to get the bucket credentials
# and the $BUCKET_URI, used to set up the
# buildcache below.
eval `pw buckets get-token ${SPACK_BUILDCACHE_ID}`

# "Start" Spack
source ${SPACK_ROOT}/share/spack/setup-env.sh

# For each installed package, push to cache
for ii in $(spack find --format "yyy {version} /{hash}" |
            grep -v -E "^(develop^master)" |
            grep "yyy" |
            cut -f3 -d" ")
do
  echo Working on $ii
  spack buildcache create -af --only=package --unsigned --mirror-name ${SPACK_BUILDCACHE_NAME} $ii
done

# After a push, you need to:
# This line applies to newer versions of Spack (v.20+?)
# where you can reference the buildcache by it's Spack name.
#
#spack buildcache update-index ${SPACK_BUILDCACHE_NAME}
#
# For older versions of Spack, you need to use the URL:
#
spack buildcache update-index --mirror-url $BUCKET_URI

# Also need to push compilers and patchelf? I'm not 100% certain
# these steps are necessary since they are present in my bucket
# but not when I run "spack buildcache list".
#oneapi_spack_hash=`spack find --format "yyy {version} /{hash}" intel-oneapi-compilers | cut -f3 -d" "`
#spack buildcache create -af --only=package --unsigned --mirror-name ${SPACK_BUILDCACHE_NAME} ${oneapi_spack_hash}
#spack buildcache update-index --mirror-url $BUCKET_URI

#patchelf_spack_hash=`spack find --format "yyy {version} /{hash}" patchelf | cut -f3 -d" "`
#spack buildcache create -af --only=package --unsigned --mirror-name ${SPACK_BUILDCACHE_NAME} ${patchelf_spack_hash}
#spack buildcache update-index --mirror-url $BUCKET_URI

