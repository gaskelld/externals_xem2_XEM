#!/bin/tcsh
set targ=$1
set targ = {$1}

swif2 cancel externals_${targ}_src -delete

./make_src_input_files.sh $targ
./make_src_scripts.sh $targ

cd ../hcswif/FARM_SCRIPTS
readlink -f *_${targ}_src_part*.sh >! ${targ}_src_list.txt

cd ..

./hcswif.py --mode command --command file /u/group/c-xem2/gaskelld/GIT/externals_xem2_XEM/hcswif/FARM_SCRIPTS/${targ}_src_list.txt --name externals_${targ}_src --account hallc --time 172800 --ram 50000000

swif2 import -file json/externals_${targ}_src.json
swif2 run externals_${targ}_src
