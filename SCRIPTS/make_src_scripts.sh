#!/bin/csh
# creat input files for a give target
# 
# 
set targ = {$1}
set min_angle=3.0
cd ../INP/
# Loop over angles
@ i=1
while ($i <= 51)
    set angle=`echo "$min_angle+$i*0.2-0.2" | bc` 
#    echo $angle
    set angle_name=`echo "$angle" | tr '.' 'p'`
    set infile = "${angle_name}_${targ}_src_part1"
    set scriptfile = "${angle_name}_${targ}_src_part1.sh"
    echo $infile
    cd /group/c-xem2/gaskelld/GIT/externals_xem2_XEM/hcswif/FARM_SCRIPTS
    cat script_header.txt >! $scriptfile
    echo "/group/c-xem2/gaskelld/GIT/externals_xem2_XEM/./run_extern" $infile >> $scriptfile
    chmod a+x $scriptfile
#    cd INP
    @ i++
end

@ i=1
while ($i <= 51)
    set angle=`echo "$min_angle+$i*0.2-0.2" | bc` 
#    echo $angle
    set angle_name=`echo "$angle" | tr '.' 'p'`
    set infile = "${angle_name}_${targ}_src_part2"
    set scriptfile = "${angle_name}_${targ}_src_part2.sh"
    echo $infile
    cd /group/c-xem2/gaskelld/GIT/externals_xem2_XEM/hcswif/FARM_SCRIPTS
    cat script_header.txt >! $scriptfile
    echo "/group/c-xem2/gaskelld/GIT/externals_xem2_XEM/./run_extern" $infile >> $scriptfile
    chmod a+x $scriptfile
#    cd INP
    @ i++
end

