#!/bin/bash

# arg--pname pvalue --> pname=pvalue
f_read_cmd_args() {
    index=1
    args=""
    rm -rf $(dirname $0)/env.sh
    echo $@
    for arg in $@; do
        prefix=$(echo "${arg}" | cut -c1-5)
	if [[ ${prefix} == 'arg--' ]]; then
	    pname=$(echo $@ | cut -d ' ' -f${index} | sed 's/arg--//g')
	    pval=$(echo $@ | cut -d ' ' -f$((index + 1)))
	    echo "export ${pname}=${pval}" >> $(dirname $0)/env.sh
	    export "${pname}=${pval}"
	fi
        index=$((index+1))
    done
}

f_read_cmd_args $@

cd ${rundir}/${jobnum}/${gh_subdir}
echo RUNNING GITHUB REPOSITORY FROM ${PWD}

#bash AWS_install/build_head_node_aws.sh # Will be able to skip this if we can use custom AMI
bash local_setup.sh
bash ${runscript}

