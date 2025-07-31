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

# Register the buildcache with Spack by
# first starting Spack and then adding the
# cache.
source ${SPACK_ROOT}/share/spack/setup-env.sh
spack mirror add ${SPACK_BUILDCACHE_NAME} ${BUCKET_URI}


