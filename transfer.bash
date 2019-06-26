#!/bin/bash -l
###########################################
#
# THESE ARE BASIC SCRIPTS FOR BATCH SUBMISSION
# USING SLURM.
###########################################
# USER-DEFINED ROOT DIRECTORY FOR RUNNING EXPERIMENTS. THIS COULD BE ONE OF THE MOM6-EXAMPLES FOR
# INSTANCE (e.g. MOM6-examples/ice_ocean_SIS2/OM4_025)
###########################################
#SBATCH --chdir=/lustre/f2/dev/Matthew.Harrison/MOM6-experiments.061219/land_ice_ocean_LM3_SIS2/OM_1440x1080_C192
#SBATCH --output=%x.o%j
#SBATCH --job-name=transfer
#SBATCH --time=12:00:00
#SBATCH --qos=normal
#SBATCH --mail-type=fail
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --account=gfdl_O
# ---------------- initialize environment modules
modulesHomeDir='/opt/modules/default'
source $modulesHomeDir/init/bash

module load gcp
module list
scontrol show hostname $SLURM_NODELIST

echo "Copying history for timestamp $begindate to gfdl:$target "

cd $stageDir
echo $beginDate


gcp -cd --sync $beginDate.MOM_parameter_doc.all $target/ascii/
gcp  --sync  $beginDate.SIS_parameter_doc.all $target/ascii/
gcp  --sync  $beginDate.stocks.out $target/ascii/
gcp -cd  --sync $endDate.res.tar $target/restart/

###########################################
#THESE HISTORY FILE NAMES NEED TO BE CONSISTENT
#WITH THE DIAG TABLE AND OUTPUT FROM pp
###########################################

if [ -f $beginDate.ice_daily.nc ] ; then
  #ls -l $beginDate.ice_daily.nc
  gcp  --sync $beginDate.ice_daily.nc $target
fi
gcp  --sync $beginDate.ocean_daily.nc $target
gcp  --sync $beginDate.ocean_month.nc $target
gcp  --sync $beginDate.ocean_annual.nc $target
gcp  --sync $beginDate.ocean.stats.nc $target

tl='tile1 tile2 tile3 tile4 tile5 tile6'
land_files='atmos_daily land_month river_month land_static land_static_sg'
for fl in $land_files; do
  for t in $tl; do
     gcp  --sync $beginDate.$fl.$t.nc $target
  done
done

cd $rootDir
