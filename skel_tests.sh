#!/usr/bin/env sh
#!/bin/sh

DefModel=mas_skel
DefCores=2
DefTime=360000
DefOps=emas_erl_ops
DefPull=disable

Model=${1:-$DefModel}
Cores=${2:-$DefCores}
Time=${3:-$DefTime}
Ops=${4:-$DefOps}
Pull=${5:-$DefPull}
SplitSize=20
Islands=64
Workers=64
CPU=opteron6276

Home="/people/plganiel"
EmasHome=$Home"/skeltests" 
ScriptRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BeamDirs="-pa $EmasHome/ebin/ $EmasHome/deps/*/ebin"
OutputDir=output
GrantID=paraphrase4

output="$ScriptRoot/$OutputDir/"$Model"_"$Time"_"$Islands"_"$Cores".out"

# Common Zeus settings
CommonSettings=""
CommonSettings+=" ""-j oe" # Join stdout and stderr
CommonSettings+=" ""-A $GrantID"	# Grant ID
CommonSettings+=" ""-N "$Model"_"$Cores # Job name
CommonSettings+=" ""-l walltime=$(($Time / 500))" # 2 times the job time
CommonSettings+=" ""-l pmem=512mb" # Memory per core
CommonSettings+=" ""-q l_bigmem" # Queue

Command="$EmasHome/emas --time $Time --model $Model --genetic_ops $Ops --islands $Islands --skel_workers $Workers --skel_split_size $SplitSize --skel_pull $Pull"

Settings=$CommonSettings
Settings+=" ""-o $output" # Output directory
Settings+=" ""-l nodes=1:$CPU:ppn=$Cores"

echo $Command
echo $Settings
echo -e "$Command" | qsub $Settings
