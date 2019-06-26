#!/bin/bash
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
#SBATCH --job-name=pp
#SBATCH --time=02:00:00
#SBATCH --qos=normal
#SBATCH --mail-type=fail
#SBATCH --nodes=1
#SBATCH --account=gfdl_O


echoOn=0
if [[ ! $echo ]]; then echoOn=1; fi
runtimeBeg=`date "+%s"`
if [[ $echoOn ]] ; then set echo; fi
echo "<NOTE> : Starting at $HOST on `date`"

# ---------------- initialize environment modules
modulesHomeDir='/opt/modules/default'
. $modulesHomeDir/init/bash
#module load cray-netcdf
#module load nco
module load fre/bronx-15
scontrol show hostname $SLURM_NODELIST

timeStamp="${rootDir}/src/mkmf/bin/time_stamp.csh"
ncCombine="${rootDir}/src/FRE-NCtools/postprocessing/mppnccombine/mppnccombine"

# ---------------- generate date for file names

cd $workDir
echo $workDir
beginDate=`$timeStamp -b -f digital`
endDate=`$timeStamp -e -f digital`
fyear=`$timeStamp -b -y -f digital`
fyear_end=`$timeStamp -e -y -f digital`
echo $fyear


cd RESTART
berg_restarts=""
for b in `ls icebergs.res.nc.????`; do   nbergs=`ncdump -h $b | grep UNLIMITED | awk '{gsub(/\(/," ");print $6}'`; if [ $nbergs -gt 0 ] ; then echo $b $nbergs;berg_restarts="$berg_restarts $b"; fi; done
if [ $nbergs -gt 0 ] ; then
ncrcat $berg_restarts icebergs.res.nc
rm -f icebergs.res.nc.????
fi

mlist='ice_model MOM calving'
for f in $mlist; do
   restart_list=`ls ${f}.res.nc.*`
   if [ ${#restart_list} -gt 0 ] ; then
     $ncCombine ${f}.res.nc
     rm -f ${f}.res.nc.????
   fi
   restart_list=`ls ${f}.res_1.nc.*`
   if [ ${#restart_list} -gt 0 ] ; then
     $ncCombine ${f}.res_1.nc
     rm -f ${f}.res_1.nc.????
   fi
   restart_list=`ls ${f}.res_2.nc.*`
   if [ ${#restart_list} -gt 0 ] ; then
     $ncCombine ${f}.res_2.nc
     rm -f ${f}.res_2.nc.????
   fi
   restart_list=`ls ${f}.res_3.nc.*`
   if [ ${#restart_list} -gt 0 ] ; then
     $ncCombine ${f}.res_3.nc
     rm -f ${f}.res_3.nc.????
   fi
   restart_list=`ls ${f}.res_4.nc.*`
   if [ ${#restart_list} -gt 0 ] ; then
     $ncCombine ${f}.res_4.nc
     rm -f ${f}.res_4.nc.????
   fi

done

cd ..

tar cvf $stageDir/$endDate.res.tar RESTART/{*.res,*.res.nc,*.res_?.nc,*.res.tile?.nc}
mv RESTART/{*.res,*.res.nc,*.res_?.nc,*.res.tile?.nc}  INPUT

###########################################
#THESE HISTORY FILE NAMES NEED TO BE CONSISTENT
#WITH THE DIAG TABLE
###########################################
histFiles='ice_daily ocean_daily ocean_month ocean_annual'
for f in $histFiles; do
if test -n "$(find . -maxdepth 1 -name "$beginDate.$histFiles.*.nc.*" -print -quit)"
  then
    $ncCombine $beginDate.$f.nc
    rm $beginDate.$f.nc.????
fi
mv $beginDate.$f.nc $stageDir

done

if [ -f ocean.stats.nc ]; then
    mv ocean.stats.nc $stageDir/$beginDate.ocean.stats.nc
fi

if [ -f stocks.out ]; then
    mv stocks.out $stageDir/$beginDate.stocks.out
fi

tiles='tile1 tile2 tile3 tile4 tile5 tile6'
file_types='atmos_daily river_static land_daily river_daily river_month river_month_inst land_month land_month_inst land_static land_static_sg'
for t in $tiles; do
  for ft in $file_types; do
   f_list=`ls $beginDate.$ft.$t.nc.*`
   if [ ${#f_list} -gt 0 ] ; then
     $ncCombine $beginDate.$ft.$t.nc $f_list
     mv $beginDate.$ft.$t.nc $stageDir
     rm $beginDate.$ft.$t.nc.????
   elif [ -f $beginDate.$ft.$t.nc ] ; then
     mv $beginDate.$ft.$t.nc $stageDir
   fi
  done
done


mv MOM_parameter_doc.all $stageDir/$beginDate.MOM_parameter_doc.all
mv SIS_parameter_doc.all $stageDir/$beginDate.SIS_parameter_doc.all
mv output $stageDir/$beginDate.output

sed -i "s/input_filename = 'n'/input_filename = 'r'/g" input.nml

cd INPUT
let fyearp=$fyear+1
fList='t10 q10 u10 v10 psurf dswrs dlwrs precip'
for f in $fList; do
    rm ${f}.nc
    ln -s /lustre/f2/pdata/gfdl/gfdl_shared/Matthew.Harrison/reanalysis/MERRA-2/${f}/${f}_merra_${fyear_end}.nc ${f}.nc
done

rm avhrr-only-v2.nc
ln -s /lustre/f2/pdata/gfdl/gfdl_shared/Matthew.Harrison/obs/NOAA-OISST-v2/avhrr-only-v2.${fyear_end}.nc avhrr-only-v2.nc
cd $baseExpDir

if [ $resubmit ]; then
  if [ $resubmit == 1 ] ; then
   sbatch run_$expName
  fi
else
  sbatch run_$expName
fi

export beginDate=$beginDate
export endDate=$endDate
export target="gfdl:/archive/mjh/MOM6-experiments.061219/land_ice_ocean_LM3_SIS2/$modelClass/$expName"
sbatch --partition=rdtn --clusters=es transfer.bash  --export=modelClass=$modelClass,rootDir=$rootDir,expName=$expName,\
             stageDir=$stageDir,baseExpDir=$baseExpDir,workDir=$workDir,beginDate=$beginDate,\
             endDate=$endDate,target=$target
