#!/bin/bash
# set -e  # Exit if any command fails! Sometimes workflow runs fine but there are SSH problems.
#           Need to comment this line out until those problems are solved.
date
jobdir=${PWD}
jobnum=$(basename ${PWD})
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"


# HELPER FUNCTIONS
# Read arguments in format "--pname pval" into export pname=pval
f_read_cmd_args(){
    index=1
    args=""
    for arg in $@; do
	    prefix=$(echo "${arg}" | cut -c1-2)
	    if [[ ${prefix} == '--' ]]; then
	        pname=$(echo $@ | cut -d ' ' -f${index} | sed 's/--//g')
	        pval=$(echo $@ | cut -d ' ' -f$((index + 1)))
	        echo "export ${pname}=${pval}" >> $(dirname $0)/env.sh
	        export "${pname}=${pval}"
	    fi
        index=$((index+1))
    done
}

echod() {
    echo $(date): $@
}

# INPUTS
f_read_cmd_args $@
wfname=weather-cluster-demo
gh_subdir=${wfname}
gh_cmd="git clone --recurse-submodules parallelworks-${gh_subdir}:parallelworks/${gh_subdir}.git"

# CLONE LATEST REPOSITORY
rm -rf ${gh_subdir}
${gh_cmd} ${gh_subdir}
if [ -d "${gh_subdir}" ]; then
    cd ${gh_subdir}
    git checkout ${branch}
else
    echod Directory ${gh_subdir} not found!
    exit 1
fi

# SEND REPOSITORY TO CONTROLLER NODE OF CLUSTER
echo; echod  SEND REPOSITORY TO CONTROLLER NODE OF CLUSTER
echo "rsync -avzq --rsync-path=\"mkdir -p ${rundir}/${jobnum} && rsync\" ${jobdir}/${gh_subdir} ${whost}:${rundir}/${jobnum}"
rsync -avzq --rsync-path="mkdir -p ${rundir}/${jobnum} && rsync" ${jobdir}/${gh_subdir} ${whost}:${rundir}/${jobnum}

# RUN SCRIPT ON THE CLUSTER
echo; echod RUN SCRIPT ON THE CLUSTER
ssh_args=$(echo $@ | sed "s/--/arg--/g")
echo "ssh ${ssh_options} ${whost} 'bash -s' < ${jobdir}/main_ssh.sh ${ssh_args} arg--jobnum ${jobnum} arg--gh_subdir ${gh_subdir}"
ssh ${ssh_options} ${whost} 'bash -s' < ${jobdir}/main_ssh.sh ${ssh_args} arg--jobnum ${jobnum} arg--gh_subdir ${gh_subdir}

# Wait for weather job to run
exit_code_file=${rundir}/${jobnum}/${gh_subdir}/conus_12km/wrf.exit.code
cat <<EOT >> wait-weather-job.sh
while true; do
    ssh ${ssh_options} ${whost} [[ -f ${exit_code_file} ]] && break || echo "\$(date) Weather job is still running"; sleep 30
done
echod "\$(date) Weather job is completed"
EOT
timeout 1200 bash wait-weather-job.sh
if [ ${exit_code} -eq 124 ]; then
    echod "ERROR: Weather job timed out!"
    exit ${exit_code}
fi

# STAGE BACK FILES:
rsync -avzq ${whost}:${rundir}/${jobnum}/${gh_subdir}/conus_12km/rsl.error.0000 .
rsync -avzq ${whost}:${rundir}/${jobnum}/${gh_subdir}/conus_12km/conus*.out .

# CHECK WORKFLOW STATUS
rslout=$(tail -n1 rsl.error.0000)
echo; echod ${rslout}
if ! [[ ${rslout} == *"wrf: SUCCESS COMPLETE WRF"* ]]; then
    echo Workflow failed!
    exit 1
fi


# CI / CD:
# Only if run was successful:
if [[ ${branch} == 'development' ]] && [[ ${merge} == 'True' ]]; then
    echo Merging ${branch} to main
    git checkout main --force # Overwrite copied files
    git merge --no-edit  ${branch}
    # Deploy key needs write permission!
    git push origin main
fi

echod DONE
exit 0