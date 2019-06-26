# SlurmRTE
Model runtime environment using SLURM

This simple set of bash scripts is used for batch job submission using SLURM. 


A non-trivial example is provided. "run_TEST".

A new job is submitted by typing: "sbatch run_TEST"

First, the scratch working directory ($workDir) is checked for its existence. If it does
not exist, then a new one is created using the files listed in "input_file_list.txt". Following normal
completion, "post_process.bash" is submitted using environment variables defined by "setEnv"  ". setEnv ${expName}".
This is followed by a submission of "transfer.bash" for transfer of ascii/history and restart files to
remote long-term storage, and a resubmission using restart files if "resubmit" is True. 

Everything is customizable here, and should be a useful and simple framework for easily spawning perturbation experiments.

