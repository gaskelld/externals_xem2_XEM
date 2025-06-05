#!/bin/tcsh
set targ=$1
set targ = {$1}
set min_angle=3.0
cd ../OUT/
cat ../SCRIPTS/output_header.txt >! xem2_src_rc_$targ.out
@ i=1
while ($i <= 241)
    set angle=`echo "$min_angle+$i*0.05-0.05" | bc` 
    set angle_name=`echo "$angle" | tr '.' 'p'`
    set outfile1 = "${angle_name}_${targ}_src_part1.out"
    set outfile2 = "${angle_name}_${targ}_src_part2.out"
    set outfile3 = "${angle_name}_${targ}_src_part3.out"
    set outfile4 = "${angle_name}_${targ}_src_part4.out"
    cat $outfile1 $outfile2 $outfile3 $outfile4 >! temp.out
    cat temp.out >> xem2_src_rc_$targ.out
    @ i++
end


