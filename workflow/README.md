# weather-cluster-demo/workflow

The files in this directory provide the bridge between the GitHub actions
(which launch a PW **workflow**, i.e. defined by the files here) and the
actual weather model application that is launched by the scripts in the
top-level directory.

In production, these three files must be in a top-level directory in
`/pw/workflows/<my_workflow_name>`.
+ `workflow.xml` render the workflow form in the GUI,
+ `main.sh` is the core runscript that is launched by PW when it detects a workflow launch request via the API, and
+ `main_ssh.sh` is the command that is launched on the remote cluster via SSH.

