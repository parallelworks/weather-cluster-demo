#======================================================
# Weather cluster demo workflow - run a smallish WRF 
#======================================================

# This workflow is designed to launch a smallish WRF
# simulation that is spread across several nodes with MPI.

#======================================================
# Dependencies
#======================================================

# Basic dependencies
import os
from os.path import exists
from time import sleep

# Parsl essentials
import parsl
from parsl.app.app import python_app, bash_app
print(parsl.__version__, flush = True)

# PW essentials
import parsl_utils
from parsl_utils.config import config, resource_labels, form_inputs
from parsl_utils.data_provider import PWFile

#==================================================
# Step 1: Inputs
#==================================================

# Start assuming workflow is launched from the form.

# Gather inputs from the WORKFLOW FORM    
# The form_inputs, resource_labels, and
# Parsl config built by parsl_utils are
# all loaded above with the import statement.
# Each of these three data structures
# has different information:
# 1. resource_labels is a simple list of the 
#    resource names specified in the workflow
#    which are used for accessing more details
#    about each resource in the form_inputs or
#    Parsl config.
# 2. form_inputs is a record of the user selected
#    parameters of the workflow from the 
#    workflow.xml workflow launch form.  Additional
#    information is added by the PW platform. 
#    Some form information is *hidden* in the
#    workflow.xml and not visible to the user in
#    the GUI, but it can be modified by editing
#    the workflow.xml. This approach provides a
#    way to differentiate between commonly changed
#    parameters and parameters that rarely change.
# 3. the Parsl config is build by the PW platform
#    (specifically the parsl_utils wrapper used to
#    launch this workflow querying info from the
#    PW databases via the PW API). Some of this
#    information is duplicated in the form_inputs,
#    but it is in a special format needed by Parsl.
#
# Print out each of these data structures to see
# exactly what is contained in each.

print('--------------RESOURCE-LABELS---------------')
print(resource_labels)
print('----------------FORM-INPUTS-----------------')
print(form_inputs)
print('----------------PARSL-CONFIG----------------')
print(config)

#==================================================
# Step 2: Configure Parsl
#==================================================
    
print("Loading Parsl config...")
parsl.load(config)
print("Parsl config loaded.")
    
#==================================================
# Step 3: Define Parsl workflow apps
#==================================================
    
# These apps are decorated with Parsl's `@bash_app` 
# and as such are executed in parallel on the compute 
# resources that are defined in the Parsl config 
# loaded above.  Functions that are **not** decorated 
# are not executed in parallel on remote resources. 
#
# The files that need to be staged to remote resources 
# will be marked with Parsl's `File()` (or its PW 
# extension, `PWFile()`) in the workflow.
    
print("Defining Parsl workflow apps...")
    
#===================================
# Clone github repo
#===================================

#===================================
# Set up cluster (Spack install, etc.)
#===================================

#===================================
# Prepare run from template
#===================================
# Need to modify the runscript (and other
# domain decomposition files) to allow for
# different numbers of worker nodes/CPUs.

#===================================
# Weather simulation app
#===================================
# This app launches the simulation.
# As this is under construction, it 
# is assumed that all the software is 
# preinstalled.

#@parsl_utils.parsl_wrappers.log_app
@bash_app(executors=[resource_labels[0]])
def wrf_run(run_script, run_dir='~/weather-cluster-demo', inputs=[], outputs=[], stdout='wrf.run.stdout', stderr='wrf.run.stderr'):
        return '''
        cd {start}
        ./{runner}
        '''.format(
            start=run_dir,
            runner=run_script
        )
    
     
print("Done defining Parsl workflow apps.")
    
#==================================================
# Step 4: Workflow
#==================================================
    
# These cells execute the workflow itself.
# First, we have the molecular dynamics simulation.
    
print("Running simulation...")
    
#============================================================================
# SIMULATE
#============================================================================
wrf_run_fut = wrf_run(run_script)
        
wrf_run_fut.result()
        
print('Done with simulations.')
    
#============================================================================
# VISUALIZE
#============================================================================

# Under construction

