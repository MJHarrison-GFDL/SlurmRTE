#!/bin/bash
#SBATCH --chdir=/lustre/f2/dev/Matthew.Harrison/MOM6-experiments.061219/land_ice_ocean_LM3_SIS2/OM_1440x1080_C192
#SBATCH --output=%x.o%j
#SBATCH --job-name=pp_launcher
#SBATCH --time=00:30:00
#SBATCH --mail-type=fail
#SBATCH --nodes=1
#SBATCH --account=gfdl_O


echoOn=0
if [[ ! $echo ]]; then echoOn=1; fi
runtimeBeg=`date "+%s"`
if [[ $echoOn ]] ; then set echo; fi
echo "<NOTE> : Starting at $HOST on `date`"


sbatch --partition=ldtn --clusters=es post_process.bash  --export=modelClass=$modelClass,rootDir=$rootDir,expName=$expName,stageDir=$stageDir,baseExpDir=$baseExpDir,workDir=$workDir,resubmit=$resubmit
