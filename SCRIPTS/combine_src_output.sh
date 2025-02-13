#!/bin/tcsh
set targ=$1
set targ = {$1}
set min_angle=3.0
cd ../OUT/
cat ../SCRIPTS/output_header.txt >! xem2_src_rc_$targ.out
@ i=1
while ($i <= 51)
    set angle=`echo "$min_angle+$i*0.2-0.2" | bc` 
    set angle_name=`echo "$angle" | tr '.' 'p'`
    set outfile1 = "${angle_name}_${targ}_src_part1.out"
    set outfile2 = "${angle_name}_${targ}_src_part2.out"
    cat $outfile1 $outfile2 >! temp.out
    cat temp.out >> xem2_src_rc_$targ.out
    @ i++
end


