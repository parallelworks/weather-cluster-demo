#!/bin/bash
set -x

# Grab current version of parsl_utils
# or specify branch with -b
git clone https://github.com/parallelworks/parsl_utils.git parsl_utils

#------------------------------------------
# Launch!
#------------------------------------------
# Cannot run scripts inside parsl_utils directly
bash parsl_utils/main.sh $@

